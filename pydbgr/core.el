;;; Copyright (C) 2010, 2013 Rocky Bernstein <rocky@gnu.org>
(eval-when-compile (require 'cl-lib))

(require 'load-relative)
(require 'realgud)
(require-relative-list '("init") "realgud-pydbgr-")

(declare-function realgud-lang-mode? 'realgud-lang)
(declare-function realgud-parse-command-arg 'realgud-core)
(declare-function realgud-query-cmdline 'realgud-core)
(declare-function realgud-suggest-invocation 'realgud-core)

;; FIXME: I think the following could be generalized and moved to
;; realgud-... probably via a macro.
(defvar realgud:pydbgr-minibuffer-history nil
  "minibuffer history list for the command `pydbgr'.")

(easy-mmode-defmap pydbgr-minibuffer-local-map
  '(("\C-i" . comint-dynamic-complete-filename))
  "Keymap for minibuffer prompting of gud startup command."
  :inherit minibuffer-local-map)

;; FIXME: I think this code and the keymaps and history
;; variable chould be generalized, perhaps via a macro.
(defun pydbgr-query-cmdline (&optional opt-debugger)
  (realgud-query-cmdline
   'pydbgr-suggest-invocation
   pydbgr-minibuffer-local-map
   'realgud:pydbgr-minibuffer-history
   opt-debugger))

(defun pydbgr-parse-cmd-args (orig-args)
  "Parse command line ARGS for the annotate level and name of script to debug.

ARGS should contain a tokenized list of the command line to run.

We return the a list containing
- the command processor (e.g. python) and it's arguments if any - a list of strings
- the name of the debugger given (e.g. pydbgr) and its arguments - a list of strings
- the script name and its arguments - list of strings
- whether the annotate or emacs option was given ('-A', '--annotate' or '--emacs) - a boolean

For example for the following input
  (map 'list 'symbol-name
   '(python2.6 -O -Qold --emacs ./gcd.py a b))

we might return:
   ((python2.6 -O -Qold) (pydbgr --emacs) (./gcd.py a b) 't)

NOTE: the above should have each item listed in quotes.
"

  ;; Parse the following kind of pattern:
  ;;  [python python-options] pydbgr pydbgr-options script-name script-options
  (let (
	(args orig-args)
	(pair)          ;; temp return from
	(python-opt-two-args '("c" "m" "Q" "W"))
	;; Python doesn't have mandatory 2-arg options in our sense,
	;; since the two args can be run together, e.g. "-C/tmp" or "-C /tmp"
	;;
	(python-two-args '())
	;; One dash is added automatically to the below, so
	;; h is really -h and -host is really --host.
	(pydbgr-two-args '("x" "-command" "e" "-execute"
			   "o" "-output"  "t" "-target"
			   "a" "-annotate"))
	(pydbgr-opt-two-args '())
	(interp-regexp
	 (if (member system-type (list 'windows-nt 'cygwin 'msdos))
	     "^python[-0-9.]*\\(.exe\\)?$"
	   "^python[-0-9.]*$"))

	;; Things returned
	(annotate-p nil)
	(debugger-args '())
	(debugger-name nil)
	(interpreter-args '())
	(script-args '())
	(script-name nil)
	)

    (if (not (and args))
	;; Got nothing: return '(nil, nil)
	(list interpreter-args debugger-args script-args annotate-p)
      ;; else
      ;; Strip off optional "python" or "python182" etc.
      (when (string-match interp-regexp
			  (file-name-sans-extension
			   (file-name-nondirectory (car args))))
	(setq interpreter-args (list (pop args)))

	;; Strip off Python-specific options
	(while (and args
		    (string-match "^-" (car args)))
	  (setq pair (realgud-parse-command-arg
		      args python-two-args python-opt-two-args))
	  (nconc interpreter-args (car pair))
	  (setq args (cadr pair))))

      ;; Remove "pydbgr" from "pydbgr --pydbgr-options script
      ;; --script-options"
      (setq debugger-name (file-name-sans-extension
			   (file-name-nondirectory (car args))))
      (unless (string-match "^\\(pydbgr\\|cli.py\\)$" debugger-name)
	(message
	 "Expecting debugger name `%s' to be `pydbgr' or `cli.py'"
	 debugger-name))
      (setq debugger-args (list (pop args)))

      ;; Skip to the first non-option argument.
      (while (and args (not script-name))
	(let ((arg (car args)))
	  (cond
	   ;; Annotation or emacs option with level number.
	   ((or (member arg '("--annotate" "-A"))
		(equal arg "--emacs"))
	    (setq annotate-p t)
	    (nconc debugger-args (list (pop args))))
	   ;; Combined annotation and level option.
	   ((string-match "^--annotate=[0-9]" arg)
	    (nconc debugger-args (list (pop args)) )
	    (setq annotate-p t))
	   ;; Options with arguments.
	   ((string-match "^-" arg)
	    (setq pair (realgud-parse-command-arg
			args pydbgr-two-args pydbgr-opt-two-args))
	    (nconc debugger-args (car pair))
	    (setq args (cadr pair)))
	   ;; Anything else must be the script to debug.
	   (t (setq script-name arg)
	      (setq script-args args))
	   )))
      (list interpreter-args debugger-args script-args annotate-p))))

;; To silence Warning: reference to free variable
(defvar realgud:pydbgr-command-name)

(defun pydbgr-suggest-invocation (debugger-name)
  "Suggest a pydbgr command invocation via `realgud-suggest-invocaton'"
  (realgud-suggest-invocation realgud:pydbgr-command-name
			      realgud:pydbgr-minibuffer-history
			      "python" "\\.py"))

(defun pydbgr-reset ()
  "Pydbgr cleanup - remove debugger's internal buffers (frame,
breakpoints, etc.)."
  (interactive)
  ;; (pydbgr-breakpoint-remove-all-icons)
  (dolist (buffer (buffer-list))
    (when (string-match "\\*pydbgr-[a-z]+\\*" (buffer-name buffer))
      (let ((w (get-buffer-window buffer)))
        (when w
          (delete-window w)))
      (kill-buffer buffer))))

;; (defun pydbgr-reset-keymaps()
;;   "This unbinds the special debugger keys of the source buffers."
;;   (interactive)
;;   (setcdr (assq 'pydbgr-debugger-support-minor-mode minor-mode-map-alist)
;; 	  pydbgr-debugger-support-minor-mode-map-when-deactive))


(defun realgud:pydbgr-customize ()
  "Use `customize' to edit the settings of the `pydbgr' debugger."
  (interactive)
  (customize-group 'realgud:pydbgr))

(provide-me "realgud-pydbgr-")
