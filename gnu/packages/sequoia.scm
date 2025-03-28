;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2019, 2020, 2021 Hartmut Goebel <h.goebel@crazy-compilers.com>
;;; Copyright © 2021, 2023-2025 Efraim Flashner <efraim@flashner.co.il>
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

(define-module (gnu packages sequoia)
  #:use-module (guix build-system cargo)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (gnu packages)
  #:use-module (gnu packages base)  ; glibc
  #:use-module (gnu packages crates-check)
  #:use-module (gnu packages crates-compression)
  #:use-module (gnu packages crates-crypto)
  #:use-module (gnu packages crates-database)
  #:use-module (gnu packages crates-io)
  #:use-module (gnu packages crates-tls)
  #:use-module (gnu packages crates-web)
  #:use-module (gnu packages crates-windows)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages hardware)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages nettle)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages security-token)
  #:use-module (gnu packages serialization)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages tls))

(define-public rust-card-backend-0.2
  (package
    (name "rust-card-backend")
    (version "0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "card-backend" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1ra2zfcs0n4msw4j0hmv8f3bpfz49x5c704i93f6a844k2if6gmx"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-thiserror" ,rust-thiserror-1))))
    (home-page "https://gitlab.com/openpgp-card/openpgp-card")
    (synopsis "Card backend trait, for use with the openpgp-card crate")
    (description
     "This package provides the card backend trait, for use with the
openpgp-card crate.")
    (license (list license:expat license:asl2.0))))

(define-public rust-card-backend-pcsc-0.5
  (package
    (name "rust-card-backend-pcsc")
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "card-backend-pcsc" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0ddv3jkcyy2vfc6jmlsh87yxcgkhcppp1g9sv670asqvgdq0pfv8"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-card-backend" ,rust-card-backend-0.2)
                       ("rust-iso7816-tlv" ,rust-iso7816-tlv-0.4)
                       ("rust-log" ,rust-log-0.4)
                       ("rust-pcsc" ,rust-pcsc-2))))
    (native-inputs
     (list pkg-config))
    (inputs
     (list pcsc-lite))
    (home-page "https://gitlab.com/openpgp-card/openpgp-card")
    (synopsis "PCSC card backend, e.g. for use with the openpgp-card crate")
    (description
     "This package provides a PCSC card backend, e.g. for use with the
openpgp-card crate.")
    (license (list license:expat license:asl2.0))))

(define-public rust-openpgp-card-0.5
  (package
    (name "rust-openpgp-card")
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "openpgp-card" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1hdlzziz9d8i55hj55jbvzidwp9q45krhb1pmz2f52hpq1mv302y"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-card-backend" ,rust-card-backend-0.2)
                       ("rust-chrono" ,rust-chrono-0.4)
                       ("rust-hex-slice" ,rust-hex-slice-0.1)
                       ("rust-log" ,rust-log-0.4)
                       ("rust-nom" ,rust-nom-7)
                       ("rust-secrecy" ,rust-secrecy-0.8)
                       ("rust-sha2" ,rust-sha2-0.10)
                       ("rust-thiserror" ,rust-thiserror-1))
       #:cargo-development-inputs (("rust-hex-literal" ,rust-hex-literal-0.4))))
    (home-page "https://gitlab.com/openpgp-card/openpgp-card")
    (synopsis "Client implementation for the OpenPGP card specification")
    (description
     "This package provides a client implementation for the @code{OpenPGP} card
specification.")
    (license (list license:expat license:asl2.0))))

(define-public rust-openpgp-cert-d-0.3
  (package
    (name "rust-openpgp-cert-d")
    (version "0.3.3")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "openpgp-cert-d" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "01b3wac69jz0wkf9lq8a3rlh502glw31k8daba1j0vwclln06yvw"))))
    (build-system cargo-build-system)
    (arguments
     `(#:tests? #f      ; Not all files included.
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-dirs" ,rust-dirs-5)
        ("rust-fd-lock" ,rust-fd-lock-3)
        ("rust-libc" ,rust-libc-0.2)
        ("rust-sha1collisiondetection" ,rust-sha1collisiondetection-0.3)
        ("rust-tempfile" ,rust-tempfile-3)
        ("rust-thiserror" ,rust-thiserror-1)
        ("rust-walkdir" ,rust-walkdir-2))
       #:cargo-development-inputs (("rust-assert-fs" ,rust-assert-fs-1)
                                   ("rust-predicates" ,rust-predicates-3))))
    (home-page "https://gitlab.com/sequoia-pgp/pgp-cert-d")
    (synopsis "Shared OpenPGP Certificate Directory")
    (description "This package provides the shared code for a @code{OpenPGP}
Certificate Directory.")
    (license license:expat)))

(define-public rust-sequoia-autocrypt-0.25
  (package
    (name "rust-sequoia-autocrypt")
    (version "0.25.1")
    (source (origin
              (method url-fetch)
              (uri (crate-uri "sequoia-autocrypt" version))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0ns121ggmx690m8czhc7zbb7rwz0jjv3l5gw4igs6mn1hznc0kz2"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs
       (("rust-base64" ,rust-base64-0.21)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))
       #:cargo-development-inputs
       (("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))))
    (native-inputs
     (list clang pkg-config))
    (inputs
     (list gmp nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Deal with Autocrypt encoded data")
    (description "This crate implements low-level functionality like encoding
and decoding of Autocrypt headers and setup messages.  Note: Autocrypt is more
than just headers; it requires tight integration with the MUA.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-cert-store-0.6
  (package
    (name "rust-sequoia-cert-store")
    (version "0.6.2")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-cert-store" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "19drjzxihs1bgqb0klwf81nxxx9jqgifzi49v8gqw00d6ba9lcwy"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-crossbeam" ,rust-crossbeam-0.8)
                       ("rust-dirs" ,rust-dirs-5)
                       ("rust-gethostname" ,rust-gethostname-0.4)
                       ("rust-num-cpus" ,rust-num-cpus-1)
                       ("rust-openpgp-cert-d" ,rust-openpgp-cert-d-0.3)
                       ("rust-rayon" ,rust-rayon-1)
                       ("rust-rusqlite" ,rust-rusqlite-0.29)
                       ("rust-sequoia-net" ,rust-sequoia-net-0.29)
                       ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                       ("rust-smallvec" ,rust-smallvec-1)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-tokio" ,rust-tokio-1)
                       ("rust-url" ,rust-url-2))
       #:cargo-development-inputs (("rust-rand" ,rust-rand-0.8)
                                   ("rust-rusty-fork" ,rust-rusty-fork-0.3)
                                   ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                                   ("rust-tempfile" ,rust-tempfile-3))))
    (native-inputs
     (list clang pkg-config))
    (inputs
     (list gmp nettle openssl sqlite))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Certificate database interface")
    (description "This package provides a certificate database interface.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-directories-0.1
  (package
    (name "rust-sequoia-directories")
    (version "0.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-directories" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1m9plvzm61571y1vzsp3jkba2mgbxgwckrbpmcbqdky5c24x87dh"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-directories" ,rust-directories-5)
                       ("rust-same-file" ,rust-same-file-1)
                       ("rust-tempfile" ,rust-tempfile-3)
                       ("rust-thiserror" ,rust-thiserror-1))
       #:phases
       (modify-phases %standard-phases
         (add-before 'check 'pre-check
           (lambda _
             (setenv "HOME" (getcwd)))))))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Directories used by Sequoia")
    (description "This package provides Directories used by Sequoia.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-gpg-agent-0.5
  (package
    (name "rust-sequoia-gpg-agent")
    (version "0.5.1")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-gpg-agent" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1j3pawsnxj27ak5gfw6aa7crypbbvv5whwpm3cml7ay4yv6qp8hh"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-chrono" ,rust-chrono-0.4)
                       ("rust-futures" ,rust-futures-0.3)
                       ("rust-lalrpop" ,rust-lalrpop-0.20)
                       ("rust-lalrpop-util" ,rust-lalrpop-util-0.20)
                       ("rust-libc" ,rust-libc-0.2)
                       ("rust-sequoia-ipc" ,rust-sequoia-ipc-0.35)
                       ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                       ("rust-stfu8" ,rust-stfu8-0.2)
                       ("rust-tempfile" ,rust-tempfile-3)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-tokio" ,rust-tokio-1))
       #:cargo-development-inputs (("rust-clap" ,rust-clap-4)
                                   ("rust-lazy-static" ,rust-lazy-static-1)
                                   ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                                   ("rust-tempfile" ,rust-tempfile-3)
                                   ("rust-tokio" ,rust-tokio-1)
                                   ("rust-tokio-test" ,rust-tokio-test-0.4))))
    (native-inputs (list clang gnupg pkg-config))
    (inputs (list nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Library for interacting with GnuPG's gpg-agent")
    (description
     "This package provides a library for interacting with @code{GnuPG's} gpg-agent.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-ipc-0.35
  (package
    (name "rust-sequoia-ipc")
    (version "0.35.1")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-ipc" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1qryibvxs7fgbfi55sxsmh6kpim41rz06sslfb0n2cr3jn5cpbl9"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-buffered-reader" ,rust-buffered-reader-1)
                       ("rust-capnp-rpc" ,rust-capnp-rpc-0.19)
                       ("rust-ctor" ,rust-ctor-0.2)
                       ("rust-dirs" ,rust-dirs-5)
                       ("rust-fs2" ,rust-fs2-0.4)
                       ("rust-lalrpop" ,rust-lalrpop-0.17)
                       ("rust-lalrpop-util" ,rust-lalrpop-util-0.17)
                       ("rust-lazy-static" ,rust-lazy-static-1)
                       ("rust-libc" ,rust-libc-0.2)
                       ("rust-memsec" ,rust-memsec-0.5)
                       ("rust-rand" ,rust-rand-0.8)
                       ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                       ("rust-socket2" ,rust-socket2-0.5)
                       ("rust-tempfile" ,rust-tempfile-3)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-tokio" ,rust-tokio-1)
                       ("rust-tokio-util" ,rust-tokio-util-0.7)
                       ("rust-winapi" ,rust-winapi-0.3))
       #:cargo-development-inputs
       (("rust-quickcheck" ,rust-quickcheck-1)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))))
    (native-inputs
     (list clang pkg-config))
    (inputs
     (list nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Interprocess communication infrastructure for Sequoia")
    (description
     "This package provides interprocess communication infrastructure for Sequoia.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-keystore-0.6
  (package
    (name "rust-sequoia-keystore")
    (version "0.6.2")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-keystore" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1qy3nk2r39m5mzvx58ij7a1r9hiw0fmgmjrad6j4nf8djids5lsx"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-async-generic" ,rust-async-generic-1)
        ("rust-capnp" ,rust-capnp-0.19)
        ("rust-capnpc" ,rust-capnpc-0.19)
        ("rust-dirs" ,rust-dirs-5)
        ("rust-env-logger" ,rust-env-logger-0.10)
        ("rust-lazy-static" ,rust-lazy-static-1)
        ("rust-log" ,rust-log-0.4)
        ("rust-paste" ,rust-paste-1)
        ("rust-sequoia-directories" ,rust-sequoia-directories-0.1)
        ("rust-sequoia-ipc" ,rust-sequoia-ipc-0.35)
        ("rust-sequoia-keystore-backend" ,rust-sequoia-keystore-backend-0.6)
        ("rust-sequoia-keystore-gpg-agent" ,rust-sequoia-keystore-gpg-agent-0.4)
        ("rust-sequoia-keystore-openpgp-card" ,rust-sequoia-keystore-openpgp-card-0.1)
        ("rust-sequoia-keystore-softkeys" ,rust-sequoia-keystore-softkeys-0.6)
        ("rust-sequoia-keystore-tpm" ,rust-sequoia-keystore-tpm-0.1)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-thiserror" ,rust-thiserror-1)
        ("rust-tokio" ,rust-tokio-1)
        ("rust-tokio-util" ,rust-tokio-util-0.7))
       #:cargo-development-inputs
       (("rust-dircpy" ,rust-dircpy-0.3)
        ("rust-env-logger" ,rust-env-logger-0.10)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-test-log" ,rust-test-log-0.2)
        ("rust-tracing" ,rust-tracing-0.1)
        ("rust-tracing-subscriber" ,rust-tracing-subscriber-0.3))))
    (native-inputs (list capnproto clang pkg-config))
    (inputs (list nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Sequoia's private key store server")
    (description "This package contains sequoia's private key store server.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-keystore-backend-0.6
  (package
    (name "rust-sequoia-keystore-backend")
    (version "0.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-keystore-backend" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "15nzpqgpnnbmpcdldzgzx5v0ifgm1njqhvzsh40cg3c02p7xyz40"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-async-trait" ,rust-async-trait-0.1)
                       ("rust-env-logger" ,rust-env-logger-0.10)
                       ("rust-futures" ,rust-futures-0.3)
                       ("rust-lazy-static" ,rust-lazy-static-1)
                       ("rust-log" ,rust-log-0.4)
                       ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                       ("rust-tempfile" ,rust-tempfile-3)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-tokio" ,rust-tokio-1))
       #:cargo-development-inputs
       (("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))))
    (native-inputs (list clang pkg-config))
    (inputs (list nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Traits for private key store backends")
    (description "This package contains traits for private key store backends.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-keystore-gpg-agent-0.4
  (package
    (name "rust-sequoia-keystore-gpg-agent")
    (version "0.4.1")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-keystore-gpg-agent" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1qnpcydrw0l3i0i082cy9mghjjq3l25clxwfj6gcpf72d6hq0wkq"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-async-trait" ,rust-async-trait-0.1)
        ("rust-futures" ,rust-futures-0.3)
        ("rust-lazy-static" ,rust-lazy-static-1)
        ("rust-log" ,rust-log-0.4)
        ("rust-openpgp-cert-d" ,rust-openpgp-cert-d-0.3)
        ("rust-sequoia-gpg-agent" ,rust-sequoia-gpg-agent-0.5)
        ("rust-sequoia-ipc" ,rust-sequoia-ipc-0.35)
        ("rust-sequoia-keystore-backend" ,rust-sequoia-keystore-backend-0.6)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-tokio" ,rust-tokio-1))
       #:cargo-development-inputs
       (("rust-env-logger" ,rust-env-logger-0.10)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-tracing" ,rust-tracing-0.1)
        ("rust-tracing-subscriber" ,rust-tracing-subscriber-0.3))))
    (native-inputs (list clang gnupg pkg-config))
    (inputs (list nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "GPG-agent backend for Sequoia's private key store")
    (description
     "This package provides a gpg-agent backend for Sequoia's private key store.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-keystore-openpgp-card-0.1
  (package
    (name "rust-sequoia-keystore-openpgp-card")
    (version "0.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-keystore-openpgp-card" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1sr3hyxvq6nc319k134iwf4z3m9lx48r40j44xbsrp7mcknxz7w8"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-async-trait" ,rust-async-trait-0.1)
        ("rust-card-backend-pcsc" ,rust-card-backend-pcsc-0.5)
        ("rust-futures" ,rust-futures-0.3)
        ("rust-log" ,rust-log-0.4)
        ("rust-openpgp-card" ,rust-openpgp-card-0.5)
        ("rust-openpgp-cert-d" ,rust-openpgp-cert-d-0.3)
        ("rust-rsa" ,rust-rsa-0.9)
        ("rust-sequoia-keystore-backend" ,rust-sequoia-keystore-backend-0.6)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-tokio" ,rust-tokio-1))
       #:cargo-development-inputs
       (("rust-env-logger" ,rust-env-logger-0.10)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-tracing" ,rust-tracing-0.1)
        ("rust-tracing-subscriber" ,rust-tracing-subscriber-0.3))))
    (native-inputs (list clang pkg-config))
    (inputs (list nettle pcsc-lite))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "OpenPGP card backend for Sequoia's private key store")
    (description
     "This package provides an @code{OpenPGP} card backend for Sequoia's
private key store.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-keystore-softkeys-0.6
  (package
    (name "rust-sequoia-keystore-softkeys")
    (version "0.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-keystore-softkeys" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1zyapjfadgmy5fnk1kwxr0dq7i4qmj4614r0g0z68dawpp8mdflr"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-async-trait" ,rust-async-trait-0.1)
        ("rust-dirs" ,rust-dirs-5)
        ("rust-futures" ,rust-futures-0.3)
        ("rust-lazy-static" ,rust-lazy-static-1)
        ("rust-log" ,rust-log-0.4)
        ("rust-sequoia-keystore-backend" ,rust-sequoia-keystore-backend-0.6)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))
       #:cargo-development-inputs
       (("rust-dircpy" ,rust-dircpy-0.3)
        ("rust-env-logger" ,rust-env-logger-0.10)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-tempfile" ,rust-tempfile-3)
        ("rust-tokio" ,rust-tokio-1)
        ("rust-tracing" ,rust-tracing-0.1)
        ("rust-tracing-subscriber" ,rust-tracing-subscriber-0.3))))
    (native-inputs (list clang pkg-config))
    (inputs (list nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "In-memory backend for Sequoia's private key store")
    (description
     "This package provides a soft key (in-memory key) backend for Sequoia's
private key store.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-keystore-tpm-0.1
  (package
    (name "rust-sequoia-keystore-tpm")
    (version "0.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-keystore-tpm" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "00cc468mf9wvkrkdzc1lhjg8a1a0qgfdj046kk09x1nfzlbm5ggh"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-async-trait" ,rust-async-trait-0.1)
        ("rust-futures" ,rust-futures-0.3)
        ("rust-log" ,rust-log-0.4)
        ("rust-openpgp-cert-d" ,rust-openpgp-cert-d-0.3)
        ("rust-sequoia-ipc" ,rust-sequoia-ipc-0.35)
        ("rust-sequoia-keystore-backend" ,rust-sequoia-keystore-backend-0.6)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-sequoia-tpm" ,rust-sequoia-tpm-0.1)
        ("rust-serde" ,rust-serde-1)
        ("rust-serde-yaml" ,rust-serde-yaml-0.8)
        ("rust-tokio" ,rust-tokio-1))
       #:cargo-development-inputs
       (("rust-env-logger" ,rust-env-logger-0.10)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-tracing" ,rust-tracing-0.1)
        ("rust-tracing-subscriber" ,rust-tracing-subscriber-0.3))))
    (native-inputs (list clang pkg-config))
    (inputs (list nettle tpm2-tss))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "TPM backend for Sequoia's private key store")
    (description
     "This package provides a TPM backend for Sequoia's private key store.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-net-0.29
  (package
    (name "rust-sequoia-net")
    (version "0.29.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-net" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0xdraqrjlpjpzyn8sc8c8xfq13pr1gp6sd4c0n80x30i6kc60zjl"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-base64" ,rust-base64-0.21)
                       ("rust-futures-util" ,rust-futures-util-0.3)
                       ("rust-hickory-client" ,rust-hickory-client-0.24)
                       ("rust-hickory-resolver" ,rust-hickory-resolver-0.24)
                       ("rust-http" ,rust-http-1)
                       ("rust-hyper" ,rust-hyper-1)
                       ("rust-hyper-tls" ,rust-hyper-tls-0.6)
                       ("rust-libc" ,rust-libc-0.2)
                       ("rust-percent-encoding" ,rust-percent-encoding-2)
                       ("rust-reqwest" ,rust-reqwest-0.12)
                       ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-tokio" ,rust-tokio-1)
                       ("rust-url" ,rust-url-2)
                       ("rust-z-base-32" ,rust-z-base-32-0.1))
       #:cargo-development-inputs (("rust-bytes" ,rust-bytes-1)
                                   ("rust-http-body-util" ,rust-http-body-util-0.1)
                                   ("rust-hyper" ,rust-hyper-1)
                                   ("rust-hyper-util" ,rust-hyper-util-0.1)
                                   ("rust-rand" ,rust-rand-0.8)
                                   ("rust-reqwest" ,rust-reqwest-0.12)
                                   ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                                   ("rust-tempfile" ,rust-tempfile-3))))
    (native-inputs
     (list clang pkg-config))
    (inputs
     (list gmp nettle openssl))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Discover and publish OpenPGP certificates over the network")
    (description "This package provides a crate to access keyservers using the
HKP protocol, and searching and publishing Web Key Directories.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-openpgp-1
  (package
    (name "rust-sequoia-openpgp")
    (version "1.22.0")
    (source
      (origin
        (method url-fetch)
        (uri (crate-uri "sequoia-openpgp" version))
        (file-name (string-append name "-" version ".tar.gz"))
        (sha256
         (base32 "0ngg32kqcrg6lz1c0g2fkb76cm1ajifb9qcjvv77kw4gwkly8n78"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("crypto-nettle")
       #:cargo-inputs
       (("rust-aes" ,rust-aes-0.8)
        ("rust-aes-gcm" ,rust-aes-gcm-0.10)
        ("rust-anyhow" ,rust-anyhow-1)
        ("rust-base64" ,rust-base64-0.21)
        ("rust-block-padding" ,rust-block-padding-0.3)
        ("rust-blowfish" ,rust-blowfish-0.9)
        ("rust-botan" ,rust-botan-0.10)
        ("rust-buffered-reader" ,rust-buffered-reader-1)
        ("rust-bzip2" ,rust-bzip2-0.4)
        ("rust-camellia" ,rust-camellia-0.1)
        ("rust-cast5" ,rust-cast5-0.11)
        ("rust-cfb-mode" ,rust-cfb-mode-0.8)
        ("rust-chrono" ,rust-chrono-0.4)
        ("rust-cipher" ,rust-cipher-0.4)
        ("rust-des" ,rust-des-0.8)
        ("rust-digest" ,rust-digest-0.10)
        ("rust-dsa" ,rust-dsa-0.6)
        ("rust-dyn-clone" ,rust-dyn-clone-1)
        ("rust-eax" ,rust-eax-0.5)
        ("rust-ecb" ,rust-ecb-0.1)
        ("rust-ecdsa" ,rust-ecdsa-0.16)
        ("rust-ed25519" ,rust-ed25519-2)
        ("rust-ed25519-dalek" ,rust-ed25519-dalek-2)
        ("rust-flate2" ,rust-flate2-1)
        ("rust-getrandom" ,rust-getrandom-0.2)
        ("rust-idea" ,rust-idea-0.5)
        ("rust-idna" ,rust-idna-1)
        ("rust-lalrpop" ,rust-lalrpop-0.20)
        ("rust-lalrpop-util" ,rust-lalrpop-util-0.20)
        ("rust-lazy-static" ,rust-lazy-static-1)
        ("rust-libc" ,rust-libc-0.2)
        ("rust-md-5" ,rust-md-5-0.10)
        ("rust-memsec" ,rust-memsec-0.6)
        ("rust-nettle" ,rust-nettle-7)
        ("rust-num-bigint-dig" ,rust-num-bigint-dig-0.8)
        ("rust-once-cell" ,rust-once-cell-1)
        ("rust-openssl" ,rust-openssl-0.10)
        ("rust-openssl-sys" ,rust-openssl-sys-0.9)
        ("rust-p256" ,rust-p256-0.13)
        ("rust-p384" ,rust-p384-0.13)
        ("rust-p521" ,rust-p521-0.13)
        ("rust-rand" ,rust-rand-0.8)
        ("rust-rand-core" ,rust-rand-core-0.6)
        ("rust-regex" ,rust-regex-1)
        ("rust-regex-syntax" ,rust-regex-syntax-0.8)
        ("rust-ripemd" ,rust-ripemd-0.1)
        ("rust-rsa" ,rust-rsa-0.9)
        ("rust-sha1collisiondetection" ,rust-sha1collisiondetection-0.3)
        ("rust-sha2" ,rust-sha2-0.10)
        ("rust-thiserror" ,rust-thiserror-1)
        ("rust-twofish" ,rust-twofish-0.7)
        ("rust-typenum" ,rust-typenum-1)
        ("rust-win-crypto-ng" ,rust-win-crypto-ng-0.5)
        ("rust-winapi" ,rust-winapi-0.3)
        ("rust-x25519-dalek" ,rust-x25519-dalek-2)
        ("rust-xxhash-rust" ,rust-xxhash-rust-0.8))
       #:cargo-development-inputs
       (("rust-criterion" ,rust-criterion-0.5)
        ("rust-quickcheck" ,rust-quickcheck-1)
        ("rust-rand" ,rust-rand-0.8)
        ("rust-rpassword" ,rust-rpassword-7))))
    (native-inputs
     (list clang pkg-config))
    (inputs
     (list gmp nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "OpenPGP data types and associated machinery")
    (description "This crate aims to provide a complete implementation of
OpenPGP as defined by RFC 4880 as well as some extensions (e.g., RFC 6637,
which describes ECC cryptography) for OpenPGP.  This includes support for
unbuffered message processing.

A few features that the OpenPGP community considers to be deprecated (e.g.,
version 3 compatibility) have been left out.  The developers have also updated
some OpenPGP defaults to avoid foot guns (e.g., they selected modern algorithm
defaults).

This Guix package is built to use the nettle cryptographic library.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-policy-config-0.7
  (package
    (name "rust-sequoia-policy-config")
    (version "0.7.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-policy-config" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "17alq9dyg9gd26zbc8bcgm0vgwnlghqp0npvh088fc768c05yzb1"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-chrono" ,rust-chrono-0.4)
                       ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                       ("rust-serde" ,rust-serde-1)
                       ("rust-thiserror" ,rust-thiserror-1)
                       ("rust-toml" ,rust-toml-0.5))
       #:cargo-development-inputs
       (("rust-assert-cmd" ,rust-assert-cmd-2)
        ("rust-quickcheck" ,rust-quickcheck-1)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))))
    (native-inputs
     (list clang pkg-config))
    (inputs
     (list gmp nettle))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Configure Sequoia using a configuration file")
    (description "Configure Sequoia using a configuration file.")
    (license license:lgpl2.0+)))

(define-public rust-sequoia-policy-config-0.6
  (package
    (inherit rust-sequoia-policy-config-0.7)
    (name "rust-sequoia-policy-config")
    (version "0.6.0")
    (source (origin
              (method url-fetch)
              (uri (crate-uri "sequoia-policy-config" version))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "0x42h22kng4dsbfr0a6zdf2j9bcq14r0yr6xdw6rrggj139lazbm"))))
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-chrono" ,rust-chrono-0.4)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-serde" ,rust-serde-1)
        ("rust-thiserror" ,rust-thiserror-1)
        ("rust-toml" ,rust-toml-0.5))
       #:cargo-development-inputs
       (("rust-assert-cmd" ,rust-assert-cmd-2)
        ("rust-lazy-static" ,rust-lazy-static-1)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))))))

(define-public rust-sequoia-tpm-0.1
  (package
    (name "rust-sequoia-tpm")
    (version "0.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-tpm" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0n6qa5kxsq8m2m1b7rqgcdhfjd67jql0vsinl7x0j9vma9r38brk"))))
    (build-system cargo-build-system)
    (arguments
     `(#:cargo-inputs (("rust-hex" ,rust-hex-0.4)
                       ("rust-serde" ,rust-serde-1)
                       ("rust-tss-esapi" ,rust-tss-esapi-7)
                       ("rust-tss-esapi-sys" ,rust-tss-esapi-sys-0.5))))
    (native-inputs (list pkg-config))
    (inputs (list tpm2-tss))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Machinery for working with TPM from Sequoia")
    (description
     "This package provides machinery for working with TPM from Sequoia.")
    (license (list license:lgpl2.0+ license:asl2.0))))

(define-public rust-sequoia-wot-0.13
  (package
    (name "rust-sequoia-wot")
    (version "0.13.3")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-wot" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "08948jazk7c5a4sza5amq9ah8r0mg02lcrrpqhwgi3qjx6w550v0"))))
    (build-system cargo-build-system)
    (arguments
     `(#:features '("sequoia-openpgp/crypto-nettle")
       #:cargo-inputs (("rust-anyhow" ,rust-anyhow-1)
                       ("rust-chrono" ,rust-chrono-0.4)
                       ("rust-crossbeam" ,rust-crossbeam-0.8)
                       ("rust-num-cpus" ,rust-num-cpus-1)
                       ("rust-sequoia-cert-store" ,rust-sequoia-cert-store-0.6)
                       ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
                       ("rust-thiserror" ,rust-thiserror-2))
       #:cargo-development-inputs
       (("rust-quickcheck" ,rust-quickcheck-1)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1))))
    (inputs
     (list nettle openssl sqlite))
    (native-inputs
     (list clang pkg-config))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Implementation of OpenPGP's web of trust")
    (description
     "This package provides an implementation of @code{OpenPGP's} web of trust.")
    (license license:lgpl2.0+)))

(define-public sequoia-chameleon-gnupg
  (package
    (name "sequoia-chameleon-gnupg")
    (version "0.12.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-chameleon-gnupg" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0ydb6wbyznr9p734p4jh896arcc45wi0b4isfjs6znwa40j3s66c"))))
    (build-system cargo-build-system)
    (arguments
     (list
       #:install-source? #f
       #:features '(list "crypto-nettle")
       #:cargo-test-flags
       '(list "--"
              ;; Some tests overly depend on specific versions of input crates.
              "--skip=gpg::generate_key"
              "--skip=gpg::list_keys"
              "--skip=gpg::migrate::migration_from_secring"
              "--skip=gpg::print_mds"
              "--skip=gpg::quick::add_key_default_default_iso_date"
              "--skip=gpg::quick::generate_key_default_default_iso_date"
              "--skip=gpg::sign"
              "--skip=gpg::verify")
       #:cargo-inputs
       (list rust-anyhow-1
             rust-base64-0.21
             rust-buffered-reader-1
             rust-chrono-0.4
             rust-clap-4
             rust-clap-complete-4
             rust-clap-mangen-0.2
             rust-daemonize-0.5
             rust-dirs-5
             rust-fd-lock-4
             rust-filetime-0.2
             rust-futures-0.3
             rust-indexmap-2
             rust-interprocess-2
             rust-libc-0.2
             rust-memchr-2
             rust-openssh-keys-0.6
             rust-percent-encoding-2
             rust-rand-0.8
             rust-rand-distr-0.4
             rust-rayon-1
             rust-reqwest-0.12
             rust-roff-0.2
             rust-rpassword-7
             rust-rusqlite-0.31
             rust-sequoia-cert-store-0.6
             rust-sequoia-gpg-agent-0.5
             rust-sequoia-ipc-0.35
             rust-sequoia-net-0.29
             rust-sequoia-openpgp-1
             rust-sequoia-policy-config-0.7
             rust-sequoia-wot-0.13
             rust-serde-1
             rust-serde-json-1
             rust-shellexpand-3
             rust-tempfile-3
             rust-thiserror-2
             rust-tokio-1)
       #:cargo-development-inputs
       (list rust-anyhow-1
             rust-bzip2-0.4
             rust-diff-0.1
             rust-editdistancek-1
             rust-histo-1
             rust-interprocess-2
             rust-ntest-0.9
             rust-pty-process-0.4
             rust-regex-1
             rust-reqwest-0.12
             rust-serde-with-3
             rust-stfu8-0.2
             rust-tar-0.4
             rust-tempfile-3)
       #:phases
       #~(modify-phases %standard-phases
           (add-after 'unpack 'set-asset-out-dir
             (lambda _
               (setenv "ASSET_OUT_DIR" "target/assets")))
           (add-after 'install 'install-more
             (lambda* (#:key outputs #:allow-other-keys)
               (let* ((out (assoc-ref outputs "out"))
                      (share (string-append out "/share"))
                      (bash-completions-dir
                        (string-append out "/etc/bash_completion.d"))
                      (zsh-completions-dir
                        (string-append share "/zsh/site-functions"))
                      (fish-completions-dir
                        (string-append share "/fish/vendor_completions.d"))
                      (elvish-completions-dir
                        (string-append share "/elvish/lib"))
                      (man1 (string-append share "/man/man1")))
                 ;; The completions are generated in build.rs.
                 (mkdir-p bash-completions-dir)
                 (mkdir-p elvish-completions-dir)
                 (for-each (lambda (file)
                             (install-file file man1))
                           (find-files "target/assets/man-pages" "\\.1$"))
                 (copy-file "target/assets/shell-completions/gpg-sq.bash"
                            (string-append bash-completions-dir "/gpg-sq"))
                 (copy-file "target/assets/shell-completions/gpgv-sq.bash"
                            (string-append bash-completions-dir "/gpgv-sq"))
                 (copy-file "target/assets/shell-completions/gpg-sq.elv"
                            (string-append elvish-completions-dir "/gpg-sq"))
                 (copy-file "target/assets/shell-completions/gpgv-sq.elv"
                            (string-append elvish-completions-dir "/gpgv-sq"))
                 (install-file "target/assets/shell-completions/_gpg-sq"
                               zsh-completions-dir)
                 (install-file "target/assets/shell-completions/_gpgv-sq"
                               zsh-completions-dir)
                 (install-file "target/assets/shell-completions/gpg-sq.fish"
                               fish-completions-dir)
                 (install-file "target/assets/shell-completions/gpgv-sq.fish"
                               fish-completions-dir)))))))
    (inputs
     (list nettle openssl sqlite))
    (native-inputs
     (list clang gnupg pkg-config sequoia-sq))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Sequoia's reimplementation of the GnuPG interface")
    (description "This package provides Sequoia's reimplementation of the
@code{GnuPG} interface.

@code{gpg-sq} is Sequoia's alternative implementation of a tool following the
GnuPG command line interface.  It provides a drop-in but not feature-complete
replacement for the GnuPG project's @code{gpg}.

This Guix package is built to use the nettle cryptographic library.")
    (license license:gpl3+)))

(define-public sequoia-sq
  (package
    (name "sequoia-sq")
    (version "1.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (crate-uri "sequoia-sq" version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "0p3z6njzgffz8hrjnj3c1xk9fwfr8fjp81nmr03v8n2fspzyq6l7"))))
    (build-system cargo-build-system)
    (arguments
     `(#:install-source? #f
       #:features '("crypto-nettle"
                    "sequoia-keystore/gpg-agent"
                    "sequoia-keystore/openpgp-card"
                    "sequoia-keystore/softkeys")
       #:cargo-test-flags
       (list "--"
             ;; The certificate has an expiration date.
             "--skip=sq_autocrypt_import")
       #:cargo-inputs
       (("rust-aho-corasick" ,rust-aho-corasick-1)
        ("rust-anyhow" ,rust-anyhow-1)
        ("rust-buffered-reader" ,rust-buffered-reader-1)
        ("rust-cfg-if" ,rust-cfg-if-1)
        ("rust-chrono" ,rust-chrono-0.4)
        ("rust-clap" ,rust-clap-4)
        ("rust-clap-complete" ,rust-clap-complete-4)
        ("rust-clap-lex" ,rust-clap-lex-0.7)
        ("rust-culpa" ,rust-culpa-1)
        ("rust-dirs" ,rust-dirs-5)
        ("rust-filetime" ,rust-filetime-0.2)
        ("rust-fs-extra" ,rust-fs-extra-1)
        ("rust-futures-util" ,rust-futures-util-0.3)
        ("rust-gethostname" ,rust-gethostname-0.4)
        ("rust-humantime" ,rust-humantime-2)
        ("rust-indicatif" ,rust-indicatif-0.17)
        ("rust-once-cell" ,rust-once-cell-1)
        ("rust-regex" ,rust-regex-1)
        ("rust-reqwest" ,rust-reqwest-0.12)
        ("rust-roff" ,rust-roff-0.2)
        ("rust-rpassword" ,rust-rpassword-7)
        ("rust-rusqlite" ,rust-rusqlite-0.32)
        ("rust-sequoia-autocrypt" ,rust-sequoia-autocrypt-0.25)
        ("rust-sequoia-cert-store" ,rust-sequoia-cert-store-0.6)
        ("rust-sequoia-directories" ,rust-sequoia-directories-0.1)
        ("rust-sequoia-ipc" ,rust-sequoia-ipc-0.35)
        ("rust-sequoia-keystore" ,rust-sequoia-keystore-0.6)
        ("rust-sequoia-net" ,rust-sequoia-net-0.29)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-sequoia-policy-config" ,rust-sequoia-policy-config-0.7)
        ("rust-sequoia-wot" ,rust-sequoia-wot-0.13)
        ("rust-serde" ,rust-serde-1)
        ("rust-subplot-build" ,rust-subplot-build-0.12)
        ("rust-subplotlib" ,rust-subplotlib-0.12)
        ("rust-tempfile" ,rust-tempfile-3)
        ("rust-termcolor" ,rust-termcolor-1)
        ("rust-terminal-size" ,rust-terminal-size-0.4)
        ("rust-textwrap" ,rust-textwrap-0.16)
        ("rust-thiserror" ,rust-thiserror-2)
        ("rust-tokio" ,rust-tokio-1)
        ("rust-toml-edit" ,rust-toml-edit-0.22)
        ("rust-typenum" ,rust-typenum-1))
       #:cargo-development-inputs
       (("rust-assert-cmd" ,rust-assert-cmd-2)
        ("rust-libc" ,rust-libc-0.2)
        ("rust-predicates" ,rust-predicates-3)
        ("rust-regex" ,rust-regex-1))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'set-asset-out-dir
           (lambda _
             (setenv "ASSET_OUT_DIR" "target/assets")))
         (add-after 'install 'install-more
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (share (string-append out "/share"))
                    (bash-completions-dir
                     (string-append out "/etc/bash_completion.d"))
                    (zsh-completions-dir
                     (string-append share "/zsh/site-functions"))
                    (fish-completions-dir
                     (string-append share "/fish/vendor_completions.d"))
                    (elvish-completions-dir
                     (string-append share "/elvish/lib"))
                    (man1 (string-append share "/man/man1")))
               ;; The completions are generated in build.rs.
               (mkdir-p bash-completions-dir)
               (mkdir-p elvish-completions-dir)
               (for-each (lambda (file)
                           (install-file file man1))
                         (find-files "target/assets/man-pages" "\\.1$"))
               (copy-file "target/assets/shell-completions/sq.bash"
                          (string-append bash-completions-dir "/sq"))
               (install-file "target/assets/shell-completions/_sq"
                             zsh-completions-dir)
               (install-file "target/assets/shell-completions/sq.fish"
                             fish-completions-dir)
               (copy-file "target/assets/shell-completions/sq.elv"
                          (string-append elvish-completions-dir "/sq"))))))))
    (inputs
     (list nettle openssl pcsc-lite sqlite))
    (native-inputs
     (list capnproto clang pkg-config))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Command-line frontend for Sequoia OpenPGP")
    (description "This package provides the command-line frontend for Sequoia
OpenPGP.

This Guix package is built to use the nettle cryptographic library and the
gpg-agent, openpgp-card and softkeys keystore backends.")
    (license license:lgpl2.0+)))

(define-public sequoia-sqv
  (package
    (name "sequoia-sqv")
    (version "1.2.1")
    (source
      (origin
        (method url-fetch)
        (uri (crate-uri "sequoia-sqv" version))
        (file-name (string-append name "-" version ".tar.gz"))
        (sha256
          (base32 "0nizac02bwl5cdmcvn3vjjxdhcy431mnsijyswnq101p764dlkl2"))))
    (build-system cargo-build-system)
    (inputs
     (list nettle openssl))
    (native-inputs
     (list clang pkg-config))
    (arguments
     `(#:install-source? #f
       #:cargo-inputs
       (("rust-anyhow" ,rust-anyhow-1)
        ("rust-chrono" ,rust-chrono-0.4)
        ("rust-clap" ,rust-clap-4)
        ("rust-clap-complete" ,rust-clap-complete-4)
        ("rust-clap-mangen" ,rust-clap-mangen-0.2)
        ("rust-sequoia-openpgp" ,rust-sequoia-openpgp-1)
        ("rust-sequoia-policy-config" ,rust-sequoia-policy-config-0.6))
       #:cargo-development-inputs
       (("rust-assert-cmd" ,rust-assert-cmd-2)
        ("rust-predicates" ,rust-predicates-3))
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'set-asset-out-dir
           (lambda _
             (setenv "ASSET_OUT_DIR" "target/assets")))
         (add-after 'install 'install-more
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (share (string-append out "/share"))
                    (bash-completions-dir
                     (string-append out "/etc/bash_completion.d"))
                    (zsh-completions-dir
                     (string-append share "/zsh/site-functions"))
                    (fish-completions-dir
                     (string-append share "/fish/vendor_completions.d"))
                    (elvish-completions-dir
                     (string-append share "/elvish/lib"))
                    (man1 (string-append share "/man/man1")))
               ;; The completions are generated in build.rs.
               (mkdir-p bash-completions-dir)
               (mkdir-p elvish-completions-dir)
               (for-each (lambda (file)
                           (install-file file man1))
                         (find-files "target/assets/man-pages" "\\.1$"))
               (copy-file "target/assets/shell-completions/sqv.bash"
                          (string-append bash-completions-dir "/sqv"))
               (install-file "target/assets/shell-completions/_sqv"
                             zsh-completions-dir)
               (install-file "target/assets/shell-completions/sqv.fish"
                             fish-completions-dir)
               (copy-file "target/assets/shell-completions/sqv.elv"
                          (string-append elvish-completions-dir "/sqv"))))))))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Simple OpenPGP signature verification program")
    (description "@code{sqv} verifies detached OpenPGP signatures.  It is a
replacement for @code{gpgv}.  Unlike @code{gpgv}, it can take additional
constraints on the signature into account.

This Guix package is built to use the nettle cryptographic library.")
    (license license:lgpl2.0+)))

;; There hasn't been a release cut since the tools were split from the library
;; so we use the 0.1.0 number from tools/Cargo.toml and the tag from the library.
(define-public sequoia-wot-tools
  (package
    (name "sequoia-wot-tools")
    (version "0.1.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://gitlab.com/sequoia-pgp/sequoia-wot")
              (commit "sequoia-wot/v0.13.2")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0vvq2izz2088x9jvii1xj14z4hls948wn18wb53fpahyhx8kkbvx"))))
    (build-system cargo-build-system)
    (arguments
     (list
       #:features '(list "sequoia-openpgp/crypto-nettle")
       #:cargo-test-flags '(list "--" "--skip=gpg_trust_roots")
       #:install-source? #f
       #:cargo-inputs
       (list rust-anyhow-1
             rust-chrono-0.4
             rust-clap-4
             rust-clap-complete-4
             rust-clap-mangen-0.2
             rust-dot-writer-0.1
             rust-enumber-0.3
             rust-sequoia-cert-store-0.6
             rust-sequoia-openpgp-1
             rust-sequoia-policy-config-0.7)
       #:cargo-development-inputs
       (list rust-assert-cmd-2
             rust-predicates-3
             rust-tempfile-3)
       #:phases
       #~(modify-phases %standard-phases
           (add-after 'unpack 'chdir
             (lambda _
               (delete-file "Cargo.lock")
               (chdir "tools")))
           (add-after 'install 'install-more
             (lambda* (#:key outputs #:allow-other-keys)
               (let* ((out   (assoc-ref outputs "out"))
                      (share (string-append out "/share"))
                      (man1  (string-append share "/man/man1")))
                 (for-each (lambda (file)
                             (install-file file man1))
                           (find-files "target/release" "\\.1$"))
                 (mkdir-p (string-append out "/etc/bash_completion.d"))
                 (mkdir-p (string-append share "/fish/vendor_completions.d"))
                 (mkdir-p (string-append share "/elvish/lib"))
                 (copy-file (car (find-files "target/release" "sq-wot.bash"))
                            (string-append out "/etc/bash_completion.d/sq-wot"))
                 (copy-file (car (find-files "target/release" "sq-wot.fish"))
                            (string-append
                              share "/fish/vendor_completions.d/sq-wot.fish"))
                 (copy-file (car (find-files "target/release" "sq-wot.elv"))
                            (string-append share "/elvish/lib/sq-wot"))
                 (install-file (car (find-files "target/release" "_sq-wot"))
                               (string-append
                                 share "/zsh/site-functions"))))))))
    (inputs
     (list nettle openssl sqlite))
    (native-inputs
     (list clang pkg-config))
    (home-page "https://sequoia-pgp.org/")
    (synopsis "Implementation of OpenPGP's web of trust")
    (description
     "This package provides an implementation of @code{OpenPGP's} web of trust.

This Guix package is built to use the nettle cryptographic library.")
    (license license:lgpl2.0+)))

;;

(define-public sequoia
  (package
    (name "sequoia")
    (version "1.22.0")
    (source #f)
    (build-system trivial-build-system)
    (arguments
     (list
      #:modules '((guix build utils)
                  (guix build union)
                  (guix build gnu-build-system)
                  (guix build gremlin)
                  (guix elf))
      #:builder
      #~(begin
          (use-modules (guix build utils)
                       (guix build union)
                       (guix build gnu-build-system)
                       (ice-9 match))
          (let ((make-dynamic-linker-cache
                 (assoc-ref %standard-phases 'make-dynamic-linker-cache))
                (ld.so.cache
                 (string-append #$output "/etc/ld.so.cache")))
            (match %build-inputs
                   (((names . directories) ...)
                    (union-build #$output directories)))
            (delete-file ld.so.cache)
            (setenv "PATH"
                    (string-append (getenv "PATH") ":" #$glibc "/sbin"))
            (make-dynamic-linker-cache #:outputs %outputs)))))
    (inputs
     (list ;glibc ;; for ldconfig in make-dynamic-linker-cache
           sequoia-sq
           sequoia-sqv
           sequoia-wot-tools))
    (home-page "https://sequoia-pgp.org")
    (synopsis "New OpenPGP implementation (meta-package)")
    (description "Sequoia is a new OpenPGP implementation, written in Rust,
consisting of several Rust crates/packages.  This Guix meta-package combines
these packages into a single one for convenience.  Anyhow, you should not
depend other packages on this one avoid excessive compile-times for users.")
    (license license:lgpl2.0+)))
