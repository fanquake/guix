;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2016 Theodoros Foradis <theodoros@foradis.org>
;;; Copyright © 2019 Arun Isaac <arunisaac@systemreboot.net>
;;; Copyright © 2019, 2020 Tobias Geerinckx-Rice <me@tobias.gr>
;;; Copyright © 2020 Michael Rohleder <mike@rohleder.de>
;;; Copyright © 2022, 2024 jgart <jgart@dismail.de>
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

(define-module (gnu packages uml)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system ant)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages java))

(define-public plantuml
  (package
    (name "plantuml")
    (version "1.2024.6")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/plantuml/plantuml/")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32
                "0h6hk34x5qc8cyqlw90wnakji8w6n9bykpr3dygvfwg2kvw5rhlv"))))
    (build-system ant-build-system)
    (arguments
     `(#:tests? #f                      ; no tests
       #:build-target "dist"
       #:phases
       (modify-phases %standard-phases
         (add-before 'build 'delete-extra-from-classpath
           (lambda _
             (substitute* "build.xml"
               (("1.6") "1.7")
               (("<attribute name=\"Class-Path\"") "<!--")
               (("ditaa0_9.jar\" />") "-->"))
             #t))
         (add-after 'delete-extra-from-classpath 'patch-usr-bin-dot
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((dot (search-input-file inputs "/bin/dot")))
               (substitute*
                   "src/net/sourceforge/plantuml/dot/GraphvizLinux.java"
                 (("/usr/bin/dot") dot)))
             #t))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (install-file "plantuml.jar" (string-append
                                           (assoc-ref outputs "out")
                                           "/share/java"))
             #t))
         (add-after 'install 'make-wrapper
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (wrapper (string-append out "/bin/plantuml")))
               (mkdir-p (string-append out "/bin"))
               (with-output-to-file wrapper
                 (lambda _
                   (display
                    (string-append
                     "#!/bin/sh\n\n"
                     (assoc-ref inputs "jre") "/bin/java -jar "
                     out "/share/java/plantuml.jar \"$@\"\n"))))
               (chmod wrapper #o555))
             #t)))))
    (inputs
     `(("graphviz" ,graphviz)
       ("jre" ,icedtea)))
    (home-page "https://plantuml.com/")
    (synopsis "Draw UML diagrams from simple textual description")
    (description
     "Plantuml is a tool to generate sequence, usecase, class, activity,
component, state, deployment and object UML diagrams, using a simple and
human readable text description.  Contains @code{salt}, a tool that can design
simple graphical interfaces.")
    (license license:gpl3+)))
