;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014 Sree Harsha Totakura <sreeharsha@totakura.in>
;;; Copyright © 2015 Federico Beffa <beffa@fbengineering.ch>
;;; Copyright © 2016–2018, 2020–2022 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2018 Theodoros Foradis <theodoros@foradis.org>
;;; Copyright © 2019 Jens Mølgaard <jens@zete.tk>
;;; Copyright © 2020 Jan Wielkiewicz <tona_kosmicznego_smiecia@interia.pl>
;;; Copyright © 2021 Efraim Flashner <efraim@flashner.co.il>
;;; Copyright © 2023, 2024 Ricardo Wurmus <rekado@elephly.net>
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

(define-module (gnu packages upnp)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages base)
  #:use-module (gnu packages check)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages file)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages image)
  #:use-module (gnu packages javascript)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages logging)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pretty-print)
  #:use-module (gnu packages python)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages xml)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix utils)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (ice-9 match))

(define-public miniupnpc
  (package
    (name "miniupnpc")
    (version "2.1.20191224")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://miniupnp.tuxfamily.org/files/"
                           "miniupnpc-" version ".tar.gz"))
       (sha256
        (base32 "1kv6dpj93gckvwvgzxl4vdqpwnicb0c8p0xw53m2gh5naiw44ys4"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("python" ,python-2)))
    (arguments
     ;; The build system does not use a configure script but depends on
     ;; `make'.  Hence we should pass parameters to `make' instead and remove
     ;; the configure phase.
     `(#:make-flags
       (list
        (string-append "SH=" (search-input-file %build-inputs "/bin/sh"))
        (string-append "INSTALLPREFIX=" (assoc-ref %outputs "out"))
        ,(string-append "CC=" (cc-for-target))

        ;; Allow executables to find libminiupnpc.so.
        (string-append "LDFLAGS=-Wl,-rpath="
                       (assoc-ref %outputs "out") "/lib"))
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-before 'install 'qualify-paths
           (lambda* (#:key outputs #:allow-other-keys)
             (substitute* "external-ip.sh"
               (("upnpc")
                (string-append (assoc-ref outputs "out") "/bin/upnpc")))
             #t)))))
    (home-page "http://miniupnp.free.fr/")
    (synopsis "UPnP protocol client library")
    (description
     "The MiniUPnPc client library facilitates access to the services provided
by any @dfn{Universal Plug and Play} (UPnP) @dfn{Internet Gateway Device} (IGD)
present on the network.  In UPnP terminology, MiniUPnPc is a UPnP Control Point.

It is useful whenever an application needs to listen for incoming connections
while running behind a UPnP-enabled router or firewall.  Such applications
include peer-to-peer applications, active-mode FTP clients, DCC file transfers
over IRC, instant messaging, network games, and most server software.")
    (license
     (license:x11-style "file://LICENSE" "See 'LICENSE' file in the distribution"))))

(define-public libupnp
  (package
    (name "libupnp")
    (version "1.14.18")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://github.com/pupnp/pupnp/releases/download"
                          "/release-" version "/libupnp-" version".tar.bz2"))
      (sha256
       (base32 "1sywi1l0sc9s55hryfwqb5y5fhyyqx6ida5i7bk8m1p27klwx9qn"))))
    (native-inputs
     (list pkg-config))
    (build-system gnu-build-system)
    (arguments
     ;; The tests require a network device capable of multicasting which is
     ;; not available in the build environment. See
     ;; https://lists.gnu.org/archive/html/guix-devel/2015-01/msg00312.html.
     `(#:tests? #f
       #:configure-flags '("--disable-static")))
    (home-page "https://pupnp.sourceforge.net")
    (synopsis "Portable SDK for UPnP Devices")
    (description
     "The portable SDK for UPnP Devices (libupnp) provides developers with an
API and code for building control points, devices, and bridges that are
compliant with Version 1.0 of the Universal Plug and Play Device Architecture
Specification and support several operating systems like Linux, *BSD, Solaris
and others.")
    (license license:bsd-3)))

(define-public readymedia
  (package
    (name "readymedia")
    (version "1.3.3")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://git.code.sf.net/p/minidlna/git")
             (commit (string-append
                      "v" (string-replace-substring version "." "_")))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1al04jx72bxwqch1nv9lx536mb6pvj7pgnqzy6lm32q6xa114yr2"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:configure-flags #~(list "--with-os-name=Linux" ; uname -s
                                "--with-os-version=")  ; uname -r
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'patch-source
            (lambda* (#:key inputs #:allow-other-keys)
              (substitute* "Makefile.am"
                ((".*LIBAVUTIL_LIBS.*") ""))
              (substitute* "minidlna.c"
                (("rm -rf")
                 (string-append
                  (search-input-file inputs "/bin/rm") " -rf")))
              (substitute* "minidlnad.8"
                (("/usr(/sbin/minidlnad)" _ path)
                 (string-append #$output path)))))
          (add-after 'install 'install-man-pages
            (lambda _
              (let ((man (string-append #$output "/share/man/man")))
                (install-file "minidlnad.8" (string-append man "8"))
                (install-file "minidlna.conf.5" (string-append man "5"))))))))
    (native-inputs (list autoconf automake gettext-minimal))
    (inputs
     (list coreutils-minimal
           ffmpeg
           flac
           libexif
           libid3tag
           libjpeg-turbo
           libvorbis
           sqlite
           zlib))
    (home-page "https://minidlna.sourceforge.net/")
    (synopsis "DLNA/UPnP-AV media server")
    (description "ReadyMedia (formerly known as MiniDLNA) is a simple media
server, which serves multimedia content to compatible clients on the network.
It aims to be fully compliant with DLNA and UPnP-AV standards.")
    (license license:gpl2)))

(define-public gerbera
  (package
    (name "gerbera")
    (version "2.2.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/gerbera/gerbera")
             (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1pqqjwza9fs59n2x685yvfb0sdwigknfxc4ihh3phpqyg99427kk"))))
    (build-system cmake-build-system)
    (arguments
     (list
      #:configure-flags
      #~(list "-DWITH_SYSTEMD=NO"
              "-DWITH_AVCODEC=YES"
              "-DWITH_TESTS=YES")))
    (inputs
     (list curl
           duktape
           exiv2
           ffmpeg
           file
           fmt
           libebml
           libexif
           libmatroska
           libupnp
           pugixml
           spdlog-1.13
           sqlite
           taglib
           `(,util-linux "lib")
           zlib))
    (native-inputs
     (list googletest pkg-config))
    (home-page "https://gerbera.io/")
    (synopsis "UPnP media server")
    (description "Gerbera is a UPnP media server which allows you to stream
your digital media through your home network and consume it on a variety of
UPnP compatible devices.")
    (license license:gpl2)))
