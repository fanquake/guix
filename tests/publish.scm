;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 David Thompson <davet@gnu.org>
;;; Copyright © 2020 by Amar M. Singh <nly@disroot.org>
;;; Copyright © 2016-2022, 2024 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

;; Avoid interference.
(unsetenv "http_proxy")

(define-module (test-publish)
  #:use-module (guix scripts publish)
  #:use-module (guix tests)
  #:use-module (guix config)
  #:use-module ((guix utils) #:select (call-with-temporary-directory))
  #:use-module ((guix build utils) #:select (call-with-temporary-output-file))
  #:use-module (gcrypt hash)
  #:use-module (guix store)
  #:use-module (guix derivations)
  #:use-module (guix gexp)
  #:use-module (guix base32)
  #:use-module (guix base64)
  #:use-module ((guix records) #:select (recutils->alist))
  #:use-module ((guix serialization) #:select (restore-file))
  #:use-module (gcrypt pk-crypto)
  #:use-module ((guix pki) #:select (%public-key-file %private-key-file))
  #:use-module (zlib)
  #:use-module (lzlib)
  #:autoload   (zstd) (call-with-zstd-input-port)
  #:use-module (web uri)
  #:use-module (web client)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module ((guix http-client) #:select (http-multiple-get))
  #:use-module (rnrs bytevectors)
  #:use-module (ice-9 binary-ports)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-64)
  #:use-module (srfi srfi-71)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 format)
  #:use-module (ice-9 match)
  #:use-module (ice-9 rdelim))

(define %store
  (open-connection-for-tests))

(define (zstd-supported?)
  (resolve-module '(zstd) #t #f #:ensure #f))

(define %reference (add-text-to-store %store "ref" "foo"))

(define %item (add-text-to-store %store "item" "bar" (list %reference)))

(define (http-get-body uri)
  (call-with-values (lambda () (http-get uri))
    (lambda (response body) body)))

(define (http-get-port uri)
  (let ((socket (open-socket-for-uri uri)))
    ;; Make sure to use an unbuffered port so that we can then peek at the
    ;; underlying file descriptor via 'call-with-gzip-input-port'.
    (setvbuf socket 'none)
    (call-with-values
        (lambda ()
          (http-get uri #:port socket #:streaming? #t))
      (lambda (response port)
        ;; Don't (setvbuf port 'none) because of <http://bugs.gnu.org/19610>
        ;; (PORT might be a custom binary input port).
        port))))

(define (publish-uri route)
  (string-append "http://localhost:6789" route))

(define-syntax-rule (with-separate-output-ports exp ...)
  ;; Since ports aren't thread-safe in Guile 2.0, duplicate the output and
  ;; error ports to make sure the two threads don't end up stepping on each
  ;; other's toes.
  (with-output-to-port (duplicate-port (current-output-port) "w")
    (lambda ()
      (with-error-to-port (duplicate-port (current-error-port) "w")
        (lambda ()
          exp ...)))))

;; guix-publish uses (current-processor-count) as the default number of
;; workers, however on a system with a large number of cores, that large
;; number of worker threads being used in the course of these tests can end up
;; hitting resource limits and causing spurious test failures.
;;
;; This will depend on what resource limits are in use, but 64 seems low
;; enough to be able to run the tests without problems.
(let ((max-processors 64))
  (when (> (current-processor-count)
           max-processors)
    (setaffinity
     (getpid)
     (make-bitvector max-processors #t))))

;; Run a local publishing server in a separate thread.
(with-separate-output-ports
 (call-with-new-thread
  (lambda ()
    (guix-publish "--port=6789" "-C0"))))     ;attempt to avoid port collision

(define (wait-until-ready port)
  ;; Wait until the server is accepting connections.
  (let ((conn (socket PF_INET SOCK_STREAM 0)))
    (let loop ()
      (unless (false-if-exception
               (connect conn AF_INET (inet-pton AF_INET "127.0.0.1") port))
        (loop)))))

(define (wait-for-file file)
  ;; Wait until FILE shows up.
  (let loop ((i 20))
    (cond ((file-exists? file)
           #t)
          ((zero? i)
           (error "file didn't show up" file))
          (else
           (pk 'wait-for-file file)
           (sleep 1)
           (loop (- i 1))))))

(define %gzip-magic-bytes
  ;; Magic bytes of gzip file.
  #vu8(#x1f #x8b))

;; Wait until the two servers are ready.
(wait-until-ready 6789)

;; Initialize the public/private key SRFI-39 parameters.
(%public-key (read-file-sexp %public-key-file))
(%private-key (read-file-sexp %private-key-file))


(test-begin "publish")

(test-equal "/nix-cache-info"
  (format #f "StoreDir: ~a\nWantMassQuery: 0\nPriority: 100\n"
          %store-directory)
  (http-get-body (publish-uri "/nix-cache-info")))

(test-equal "/*.narinfo"
  (let* ((info (query-path-info %store %item))
         (unsigned-info
          (format #f
                  "StorePath: ~a
NarHash: sha256:~a
NarSize: ~d
References: ~a~%"
                  %item
                  (bytevector->nix-base32-string
                   (path-info-hash info))
                  (path-info-nar-size info)
                  (basename (first (path-info-references info)))))
         (signature (base64-encode
                     (string->utf8
                      (canonical-sexp->string
                       (signed-string unsigned-info))))))
    (format #f "~aSignature: 1;~a;~a
URL: nar/~a
Compression: none
FileSize: ~a\n"
            unsigned-info (gethostname) signature
            (basename %item)
            (path-info-nar-size info)))
  (utf8->string
   (http-get-body
    (publish-uri
     (string-append "/" (store-path-hash-part %item) ".narinfo")))))

(test-equal "/*.narinfo pipeline"
  (make-list 500 200)
  ;; Make sure clients can pipeline requests and correct responses, in the
  ;; right order.  See <https://issues.guix.gnu.org/54723>.
  (let* ((uri (string->uri (publish-uri
                            (string-append "/"
                                           (store-path-hash-part %item)
                                           ".narinfo"))))
         (_ expected (http-get uri #:streaming? #f #:decode-body? #f)))
    (http-multiple-get (string->uri (publish-uri ""))
                       (lambda (request response port result)
                         (and (bytevector=? expected
                                            (get-bytevector-n port
                                                              (response-content-length
                                                               response)))
                              (cons (response-code response) result)))
                       '()
                       (make-list 500 (build-request uri))
                       #:batch-size 77)))

(test-equal "/*.narinfo with properly encoded '+' sign"
  ;; See <http://bugs.gnu.org/21888>.
  (let* ((item (add-text-to-store %store "fake-gtk+" "Congrats!"))
         (info (query-path-info %store item))
         (unsigned-info
          (format #f
                  "StorePath: ~a
NarHash: sha256:~a
NarSize: ~d
References: ~%"
                  item
                  (bytevector->nix-base32-string
                   (path-info-hash info))
                  (path-info-nar-size info)))
         (signature (base64-encode
                     (string->utf8
                      (canonical-sexp->string
                       (signed-string unsigned-info))))))
    (format #f "~aSignature: 1;~a;~a
URL: nar/~a
Compression: none
FileSize: ~a~%"
            unsigned-info (gethostname) signature
            (uri-encode (basename item))
            (path-info-nar-size info)))

  (let ((item (add-text-to-store %store "fake-gtk+" "Congrats!")))
    (utf8->string
     (http-get-body
      (publish-uri
       (string-append "/" (store-path-hash-part item) ".narinfo"))))))

(test-equal "/nar/*"
  "bar"
  (call-with-temporary-output-file
   (lambda (temp port)
     (let ((nar (utf8->string
                 (http-get-body
                  (publish-uri
                   (string-append "/nar/" (basename %item)))))))
       (call-with-input-string nar (cut restore-file <> temp)))
     (call-with-input-file temp read-string))))

(test-equal "/nar/gzip/*"
  "bar"
  (call-with-temporary-output-file
   (lambda (temp port)
     (let ((nar (http-get-port
                 (publish-uri
                  (string-append "/nar/gzip/" (basename %item))))))
       (call-with-gzip-input-port nar
         (cut restore-file <> temp)))
     (call-with-input-file temp read-string))))

(test-equal "/nar/gzip/* is really gzip"
  %gzip-magic-bytes
  ;; Since 'gzdopen' (aka. 'call-with-gzip-input-port') transparently reads
  ;; uncompressed gzip, the test above doesn't check whether it's actually
  ;; gzip.  This is what this test does.  See <https://bugs.gnu.org/30184>.
  (let ((nar (http-get-port
              (publish-uri
               (string-append "/nar/gzip/" (basename %item))))))
    (get-bytevector-n nar (bytevector-length %gzip-magic-bytes))))

(test-equal "/nar/lzip/*"
  "bar"
  (call-with-temporary-output-file
   (lambda (temp port)
     (let ((nar (http-get-port
                 (publish-uri
                  (string-append "/nar/lzip/" (basename %item))))))
       (call-with-lzip-input-port nar
         (cut restore-file <> temp)))
     (call-with-input-file temp read-string))))

(unless (zstd-supported?) (test-skip 1))
(test-equal "/nar/zstd/*"
  "bar"
  (call-with-temporary-output-file
   (lambda (temp port)
     (let ((nar (http-get-port
                 (publish-uri
                  (string-append "/nar/zstd/" (basename %item))))))
       (call-with-zstd-input-port nar
         (cut restore-file <> temp)))
     (call-with-input-file temp read-string))))

(test-equal "/*.narinfo with compression"
  `(("StorePath" . ,%item)
    ("URL" . ,(string-append "nar/gzip/" (basename %item)))
    ("Compression" . "gzip"))
  (let ((thread (with-separate-output-ports
                 (call-with-new-thread
                  (lambda ()
                    (guix-publish "--port=6799" "-C5"))))))
    (wait-until-ready 6799)
    (let* ((url  (string-append "http://localhost:6799/"
                                (store-path-hash-part %item) ".narinfo"))
           (body (http-get-port url)))
      (filter (lambda (item)
                (match item
                  (("Compression" . _) #t)
                  (("StorePath" . _)  #t)
                  (("URL" . _) #t)
                  (_ #f)))
              (recutils->alist body)))))

(test-equal "/*.narinfo with lzip compression"
  `(("StorePath" . ,%item)
    ("URL" . ,(string-append "nar/lzip/" (basename %item)))
    ("Compression" . "lzip"))
  (let ((thread (with-separate-output-ports
                 (call-with-new-thread
                  (lambda ()
                    (guix-publish "--port=6790" "-Clzip"))))))
    (wait-until-ready 6790)
    (let* ((url  (string-append "http://localhost:6790/"
                                (store-path-hash-part %item) ".narinfo"))
           (body (http-get-port url)))
      (filter (lambda (item)
                (match item
                  (("Compression" . _) #t)
                  (("StorePath" . _)  #t)
                  (("URL" . _) #t)
                  (_ #f)))
              (recutils->alist body)))))

(test-equal "/*.narinfo for a compressed file"
  '("none" "nar")          ;compression-less nar
  ;; Assume 'guix publish -C' is already running on port 6799.
  (let* ((item (add-text-to-store %store "fake.tar.gz"
                                  "This is a fake compressed file."))
         (url  (string-append "http://localhost:6799/"
                              (store-path-hash-part item) ".narinfo"))
         (body (http-get-port url))
         (info (recutils->alist body)))
    (list (assoc-ref info "Compression")
          (dirname (assoc-ref info "URL")))))

(test-equal "/*.narinfo with lzip + gzip"
  `((("StorePath" . ,%item)
     ("URL" . ,(string-append "nar/gzip/" (basename %item)))
     ("Compression" . "gzip")
     ("URL" . ,(string-append "nar/lzip/" (basename %item)))
     ("Compression" . "lzip"))
    200
    200)
  (call-with-temporary-directory
   (lambda (cache)
     (let ((thread (with-separate-output-ports
                    (call-with-new-thread
                     (lambda ()
                       (guix-publish "--port=6793" "-Cgzip:2" "-Clzip:2"))))))
       (wait-until-ready 6793)
       (let* ((base "http://localhost:6793/")
              (part (store-path-hash-part %item))
              (url  (string-append base part ".narinfo"))
              (body (http-get-port url)))
         (list (filter (match-lambda
                         (("StorePath" . _) #t)
                         (("URL" . _) #t)
                         (("Compression" . _) #t)
                         (_ #f))
                       (recutils->alist body))
               (response-code
                (http-get (string-append base "nar/gzip/"
                                         (basename %item))))
               (response-code
                (http-get (string-append base "nar/lzip/"
                                         (basename %item))))))))))

(test-equal "custom nar path"
  ;; Serve nars at /foo/bar/chbouib instead of /nar.
  (list `(("StorePath" . ,%item)
          ("URL" . ,(string-append "foo/bar/chbouib/" (basename %item)))
          ("Compression" . "none"))
        200
        404)
  (let ((thread (with-separate-output-ports
                 (call-with-new-thread
                  (lambda ()
                    (guix-publish "--port=6798" "-C0"
                                  "--nar-path=///foo/bar//chbouib/"))))))
    (wait-until-ready 6798)
    (let* ((base    "http://localhost:6798/")
           (part    (store-path-hash-part %item))
           (url     (string-append base part ".narinfo"))
           (nar-url (string-append base "foo/bar/chbouib/"
                                   (basename %item)))
           (body    (http-get-port url)))
      (list (filter (lambda (item)
                      (match item
                        (("Compression" . _) #t)
                        (("StorePath" . _)  #t)
                        (("URL" . _) #t)
                        (_ #f)))
                    (recutils->alist body))
            (response-code (http-get nar-url))
            (response-code
             (http-get (string-append base "nar/" (basename %item))))))))

(test-equal "/nar/ with properly encoded '+' sign"
  "Congrats!"
  (let ((item (add-text-to-store %store "fake-gtk+" "Congrats!")))
    (call-with-temporary-output-file
     (lambda (temp port)
       (let ((nar (utf8->string
                   (http-get-body
                    (publish-uri
                     (string-append "/nar/" (uri-encode (basename item))))))))
         (call-with-input-string nar (cut restore-file <> temp)))
       (call-with-input-file temp read-string)))))

(test-equal "/nar/invalid"
  404
  (begin
    (call-with-output-file (string-append (%store-prefix) "/invalid")
      (lambda (port)
        (display "This file is not a valid store item." port)))
    (response-code (http-get (publish-uri (string-append "/nar/invalid"))))))

(test-equal "non-substitutable derivation"
  404
  (let* ((non-substitutable
          (run-with-store %store
            (gexp->derivation "non-substitutable"
                              #~(begin
                                  (mkdir #$output)
                                  (chdir #$output)
                                  (call-with-output-file "foo.txt"
                                    (lambda (port)
                                      (display "bar" port))))
                              #:substitutable? #f)))
         (item (derivation->output-path non-substitutable)))
    (build-derivations %store (list non-substitutable))
    (response-code (http-get (publish-uri
                              (string-append "/nar/" (basename item)))))))

(test-equal "/file/NAME/sha256/HASH"
  "Hello, Guix world!"
  (let* ((data "Hello, Guix world!")
         (hash (call-with-input-string data port-sha256))
         (drv  (run-with-store %store
                 (gexp->derivation "the-file.txt"
                                   #~(call-with-output-file #$output
                                       (lambda (port)
                                         (display #$data port)))
                                   #:hash-algo 'sha256
                                   #:hash hash)))
         (out  (build-derivations %store (list drv))))
    (utf8->string
     (http-get-body
      (publish-uri
       (string-append "/file/the-file.txt/sha256/"
                      (bytevector->nix-base32-string hash)))))))

(test-equal "/file/NAME/sha256/INVALID-NIX-BASE32-STRING"
  404
  (let ((uri (publish-uri
              "/file/the-file.txt/sha256/not-a-nix-base32-string")))
    (response-code (http-get uri))))

(test-equal "/file/NAME/sha256/INVALID-HASH"
  404
  (let ((uri (publish-uri
              (string-append "/file/the-file.txt/sha256/"
                             (bytevector->nix-base32-string
                              (call-with-input-string "" port-sha256))))))
    (response-code (http-get uri))))

(test-equal "with cache"
  (list #t
        `(("StorePath" . ,%item)
          ("URL" . ,(string-append "nar/gzip/" (basename %item)))
          ("Compression" . "gzip"))
        200                                       ;nar/gzip/…
        #t                                        ;Content-Length
        #t                                        ;FileSize
        404)                                      ;nar/…
  (call-with-temporary-directory
   (lambda (cache)
     (let ((thread (with-separate-output-ports
                    (call-with-new-thread
                     (lambda ()
                       (guix-publish "--port=6797" "-C2"
                                     (string-append "--cache=" cache)
                                     "--cache-bypass-threshold=0"))))))
       (wait-until-ready 6797)
       (let* ((base     "http://localhost:6797/")
              (part     (store-path-hash-part %item))
              (url      (string-append base part ".narinfo"))
              (nar-url  (string-append base "nar/gzip/" (basename %item)))
              (cached   (string-append cache "/gzip/" (basename %item)
                                       ".narinfo"))
              (nar      (string-append cache "/gzip/"
                                       (basename %item) ".nar"))
              (response (http-get url)))
         (and (= 404 (response-code response))

              ;; We should get an explicitly short TTL for 404 in this case
              ;; because it's going to become 200 shortly.
              (match (assq-ref (response-headers response) 'cache-control)
                ((('max-age . ttl))
                 (< ttl 3600)))

              (wait-for-file cached)

              ;; Both the narinfo and nar should be world-readable.
              (= #o444 (logand #o444 (stat:perms (lstat cached))))
              (= #o444 (logand #o444 (stat:perms (lstat nar))))

              (let* ((body         (http-get-port url))
                     (compressed   (http-get nar-url))
                     (uncompressed (http-get (string-append base "nar/"
                                                            (basename %item))))
                     (narinfo      (recutils->alist body)))
                (list (file-exists? nar)
                      (filter (lambda (item)
                                (match item
                                  (("Compression" . _) #t)
                                  (("StorePath" . _)  #t)
                                  (("URL" . _) #t)
                                  (_ #f)))
                              narinfo)
                      (response-code compressed)
                      (= (response-content-length compressed)
                         (stat:size (stat nar)))
                      (= (string->number
                          (assoc-ref narinfo "FileSize"))
                         (stat:size (stat nar)))
                      (response-code uncompressed)))))))))

(test-equal "with cache, lzip + gzip"
  '(200 200 404)
  (call-with-temporary-directory
   (lambda (cache)
     (let ((thread (with-separate-output-ports
                    (call-with-new-thread
                     (lambda ()
                       (guix-publish "--port=6794" "-Cgzip:2" "-Clzip:2"
                                     (string-append "--cache=" cache)
                                     "--cache-bypass-threshold=0"))))))
       (wait-until-ready 6794)
       (let* ((base     "http://localhost:6794/")
              (part     (store-path-hash-part %item))
              (url      (string-append base part ".narinfo"))
              (nar-url  (cute string-append "nar/" <> "/"
                              (basename %item)))
              (cached   (cute string-append cache "/" <> "/"
                              (basename %item) ".narinfo"))
              (nar      (cute string-append cache "/" <> "/"
                              (basename %item) ".nar"))
              (response (http-get url)))
         (wait-for-file (cached "gzip"))
         (let* ((body         (http-get-port url))
                (narinfo      (recutils->alist body))
                (uncompressed (string-append base "nar/"
                                             (basename %item))))
           (and (file-exists? (nar "gzip"))
                (file-exists? (nar "lzip"))
                (match (pk 'narinfo/gzip+lzip narinfo)
                  ((("StorePath" . path)
                    _ ...
                    ("Signature" . _)
                    ("URL" . gzip-url)
                    ("Compression" . "gzip")
                    ("FileSize" . (= string->number gzip-size))
                    ("URL" . lzip-url)
                    ("Compression" . "lzip")
                    ("FileSize" . (= string->number lzip-size)))
                   (and (string=? gzip-url (nar-url "gzip"))
                        (string=? lzip-url (nar-url "lzip"))
                        (= gzip-size
                           (stat:size (stat (nar "gzip"))))
                        (= lzip-size
                           (stat:size (stat (nar "lzip")))))))
                (list (response-code
                       (http-get (string-append base (nar-url "gzip"))))
                      (response-code
                       (http-get (string-append base (nar-url "lzip"))))
                      (response-code
                       (http-get uncompressed))))))))))

(let ((item (add-text-to-store %store "fake-compressed-thing.tar.gz"
                               (random-text))))
  (test-equal "with cache, uncompressed"
    (list #t
          (* 42 3600)                             ;TTL on narinfo
          `(("StorePath" . ,item)
            ("URL" . ,(string-append "nar/" (basename item)))
            ("Compression" . "none"))
          200                                     ;nar/…
          (* 42 3600)                             ;TTL on nar/…
          (path-info-nar-size
           (query-path-info %store item))         ;FileSize
          404)                                    ;nar/gzip/…
    (call-with-temporary-directory
     (lambda (cache)
       (let ((thread (with-separate-output-ports
                      (call-with-new-thread
                       (lambda ()
                         (guix-publish "--port=6796" "-C2" "--ttl=42h"
                                       (string-append "--cache=" cache)
                                       "--cache-bypass-threshold=0"))))))
         (wait-until-ready 6796)
         (let* ((base     "http://localhost:6796/")
                (part     (store-path-hash-part item))
                (url      (string-append base part ".narinfo"))
                (cached   (string-append cache "/none/"
                                         (basename item) ".narinfo"))
                (nar      (string-append cache "/none/"
                                         (basename item) ".nar"))
                (response (http-get url)))
           (and (= 404 (response-code response))

                (wait-for-file cached)
                (let* ((response     (http-get url))
                       (body         (http-get-port url))
                       (compressed   (http-get (string-append base "nar/gzip/"
                                                              (basename item))))
                       (uncompressed (http-get (string-append base "nar/"
                                                              (basename item))))
                       (narinfo      (recutils->alist body)))
                  (list (file-exists? nar)
                        (match (assq-ref (response-headers response)
                                         'cache-control)
                          ((('max-age . ttl)) ttl)
                          (_ #f))

                        (filter (lambda (item)
                                  (match item
                                    (("Compression" . _) #t)
                                    (("StorePath" . _)  #t)
                                    (("URL" . _) #t)
                                    (_ #f)))
                                narinfo)
                        (response-code uncompressed)
                        (match (assq-ref (response-headers uncompressed)
                                         'cache-control)
                          ((('max-age . ttl)) ttl)
                          (_ #f))

                        (string->number
                         (assoc-ref narinfo "FileSize"))
                        (response-code compressed))))))))))

(test-equal "with cache, vanishing item"         ;<https://bugs.gnu.org/33897>
  200
  (call-with-temporary-directory
   (lambda (cache)
     (let ((thread (with-separate-output-ports
                    (call-with-new-thread
                     (lambda ()
                       (guix-publish "--port=6795"
                                     (string-append "--cache=" cache)))))))
       (wait-until-ready 6795)

       ;; Make sure that, even if ITEM disappears, we're still able to fetch
       ;; it.
       (let* ((base     "http://localhost:6795/")
              (item     (add-text-to-store %store "random" (random-text)))
              (part     (store-path-hash-part item))
              (url      (string-append base part ".narinfo"))
              (cached   (string-append cache "/gzip/"
                                       (basename item)
                                       ".narinfo"))
              (response (http-get url)))
         (and (= 200 (response-code response))    ;we're below the threshold
              (wait-for-file cached)
              (begin
                (delete-paths %store (list item))
                (response-code (pk 'response (http-get url))))))))))

(test-equal "with cache, cache bypass"
  200
  (call-with-temporary-directory
   (lambda (cache)
     (let ((thread (with-separate-output-ports
                    (call-with-new-thread
                     (lambda ()
                       (guix-publish "--port=6788" "-C" "gzip"
                                     (string-append "--cache=" cache)))))))
       (wait-until-ready 6788)

       (let* ((base     "http://localhost:6788/")
              (item     (add-text-to-store %store "random" (random-text)))
              (part     (store-path-hash-part item))
              (narinfo  (string-append base part ".narinfo"))
              (nar      (string-append base "nar/gzip/" (basename item)))
              (cached   (string-append cache "/gzip/" (basename item)
                                       ".narinfo")))
         ;; We're below the default cache bypass threshold, so NAR and NARINFO
         ;; should immediately return 200.  The NARINFO request should trigger
         ;; caching, and the next request to NAR should return 200 as well.
         (and (let ((response (pk 'r1 (http-get nar))))
                (and (= 200 (response-code response))
                     (not (response-content-length response)))) ;not known
              (= 200 (response-code (http-get narinfo)))
              (begin
                (wait-for-file cached)
                (let ((response (pk 'r2 (http-get nar))))
                  (and (> (response-content-length response)
                          (stat:size (stat item)))
                       (response-code response))))))))))

(test-equal "with cache, cache bypass, unmapped hash part"
  200

  ;; This test reproduces the bug described in <https://bugs.gnu.org/44442>:
  ;; the daemon connection would be closed as a side effect of a nar request
  ;; for a non-existing file name.
  (call-with-temporary-directory
   (lambda (cache)
     (let ((thread (with-separate-output-ports
                    (call-with-new-thread
                     (lambda ()
                       (guix-publish "--port=6787" "-C" "gzip"
                                     (string-append "--cache=" cache)))))))
       (wait-until-ready 6787)

       (let* ((base     "http://localhost:6787/")
              (item     (add-text-to-store %store "random" (random-text)))
              (part     (store-path-hash-part item))
              (narinfo  (string-append base part ".narinfo"))
              (nar      (string-append base "nar/gzip/" (basename item)))
              (cached   (string-append cache "/gzip/" (basename item)
                                       ".narinfo")))
         ;; The first response used to be 500 and to terminate the daemon
         ;; connection as a side effect.
         (and (= (response-code
                  (http-get (string-append base "nar/gzip/"
                                           (make-string 32 #\e)
                                           "-does-not-exist")))
                 404)
              (= 200 (response-code (http-get nar)))
              (= 200 (response-code (http-get narinfo)))
              (begin
                (wait-for-file cached)
                (response-code (http-get nar)))))))))

(test-equal "/log/NAME"
  `(200 #t text/plain (gzip))
  (let ((drv (run-with-store %store
               (gexp->derivation "with-log"
                                 #~(call-with-output-file #$output
                                     (lambda (port)
                                       (display "Hello, build log!"
                                                (current-error-port))
                                       (display #$(random-text) port)))))))
    (build-derivations %store (list drv))
    (let* ((response (http-get
                      (publish-uri (string-append "/log/"
                                                  (basename (derivation->output-path drv))))
                      #:decode-body? #f))
           (base     (basename (derivation-file-name drv)))
           (log      (string-append (dirname %state-directory)
                                    "/log/guix/drvs/" (string-take base 2)
                                    "/" (string-drop base 2) ".gz")))
      (list (response-code response)
            (= (response-content-length response) (stat:size (stat log)))
            (first (response-content-type response))
            (response-content-encoding response)))))

(test-equal "negative TTL"
  `(404 42)

  (call-with-temporary-directory
   (lambda (cache)
     (let ((thread (with-separate-output-ports
                    (call-with-new-thread
                     (lambda ()
                       (guix-publish "--port=6786" "-C0"
                                     "--negative-ttl=42s"))))))
       (wait-until-ready 6786)

       (let* ((base     "http://localhost:6786/")
              (url      (string-append base (make-string 32 #\z)
                                       ".narinfo"))
              (response (http-get url)))
         (list (response-code response)
               (match (assq-ref (response-headers response) 'cache-control)
                 ((('max-age . ttl)) ttl)
                 (_ #f))))))))

(test-equal "no negative TTL"
  `(404 #f)
  (let* ((uri      (publish-uri
                    (string-append "/" (make-string 32 #\z)
                                   ".narinfo")))
         (response (http-get uri)))
    (list (response-code response)
          (assq-ref (response-headers response) 'cache-control))))

(test-equal "/log/NAME not found"
  404
  (let ((uri (publish-uri "/log/does-not-exist")))
    (response-code (http-get uri))))

(test-equal "/signing-key.pub"
  200
  (response-code (http-get (publish-uri "/signing-key.pub"))))

(test-equal "non-GET query"
  '(200 404)
  (let ((path (string-append "/" (store-path-hash-part %item)
                             ".narinfo")))
    (map response-code
         (list (http-get (publish-uri path))
               (http-post (publish-uri path))))))

(test-end "publish")
