;;; realgud-old-debuggers.el --- Realgud front-end to older lesser-used debuggers

;; Author: Rocky Bernstein
;; Version: 1.1.0
;; Package-Type: multi
;; Package-Requires: ((realgud "1.4.5") (load-relative "1.2") (cl-lib "0.5") (emacs "24"))
;; URL: http://github.com/rocky/realgud-old-debuggers
;; Compatibility: GNU Emacs 24.x

;; Copyright (C) 2016, 2019 Free Software Foundation, Inc

;; Author: Rocky Bernstein <rocky@gnu.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; realgud support for various older debuggers

;;; Code:

;; Press C-x C-e at the end of the next line configure the program in
;; for building via "make" to get set up.
;; (compile (format "EMACSLOADPATH=:%s:%s:%s:%s ./autogen.sh" (file-name-directory (locate-library "test-simple.elc")) (file-name-directory (locate-library "realgud.elc")) (file-name-directory (locate-library "load-relative.elc")) (file-name-directory (locate-library "loc-changes.elc"))))


(require 'load-relative)

(defgroup realgud-old-debuggers nil
  "Realgud interface to older lesser-used debuggers"
  :group 'processes
  :group 'tools
  :version "24.3")

(require-relative-list
 '(
   "./pydb/pydb"
   "./pydbgr/pydbgr"
   "./trepanx/trepanx"
   "./trepan8/trepan8"
   ) "realgud-")

(provide-me)


;;; realgud-old-debuggers.el ends here
