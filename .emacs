;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'load-path "~/.emacs.d/elpa")
(add-to-list 'load-path "~/.emacs.d/elisp")

(when (eq system-type 'darwin)
  (add-to-list 'load-path "/usr/local/opt/cmake/share/emacs/site-lisp/cmake"))

(package-initialize)

;;; cmake-mode
(require 'cmake-mode)

;;; key bind
(require 'bind-key)
;; replace
(bind-key "C-c C-r" 'query-replace)
;; backward
(bind-key "C-h" 'delete-backward-char)
;; window move
(bind-key "<left>" 'windmove-left)
(bind-key "<right>" 'windmove-right)
(bind-key "<up>" 'windmove-up)
(bind-key "<down>" 'windmove-down)

;;; wat
(require 'wat-mode)

;;; dash
(autoload 'dash-at-point "dash-at-point"
  "Search the word at point with Dash." t nil)
(bind-key "C-c d" 'dash-at-point)
(bind-key "C-c e" 'dash-at-point-with-docset)

;;; c++
(add-hook 'c++-mode-hook
	  '(lambda()
	     (c-set-offset 'innamespace 0)))

;;; php-mode
(add-hook 'php-mode-hook
	  '(lambda()
	     (setq tab-width 2)
	     (setq c-basic-offset 2)))

;;; ac-php
(add-hook 'php-mode-hook
	  '(lambda()
	     (company-mode t)
	     (require 'company-php)
	     (ac-php-core-eldoc-setup)

	     (set (make-local-variable 'company-backends)
		  '((company-ac-php-backend company-dabbrev-code)
		    company-capf company-files))
	     (bind-key "M-[" 'ac-php-find-symbol-at-point php-mode-map)
	     (bind-key "M-]" 'ac-php-location-stack-back php-mode-map)
	     ))

;;; tide for typescript
(defun setup-tide-mode ()
  (interactive)
  (tide-setup)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  ;; company is an optional dependency. You have to
  ;; install it separately via package-install
  ;; `M-x package-install [ret] company`
  (company-mode +1))

;; aligns annotation to the right hand side
(setq company-tooltip-align-annotations t)

;; formats the buffer before saving
(add-hook 'before-save-hook 'tide-format-before-save)

(add-hook 'typescript-mode-hook #'setup-tide-mode)

;;; theme
;; (add-hook 'after-init-hook 
;; 	  (lambda () (load-theme 'cyberpunk t)))
(load-theme 'tango-dark t)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; js2-mode
(require 'js2-mode)
(add-to-list 'auto-mode-alist '("\\.[m]js\\'" . js2-mode))

;;; elisp dir
(require 'gyp)

;;; gyp
;;(require 'gyp)

;;; .emacs symlink
(setq vc-follow-symlinks t)

;;; menu bar
(menu-bar-mode 0)

;;; company
(require 'company)
(global-company-mode)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 2)
(setq company-selection-wrap-around t)
(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c-mode-hook 'company-mode)
(add-hook 'objc-mode-hook 'company-mode)

(bind-key "C-o" 'company-complete)
;;; (setq company-idle-delay nil) ; 自動補完をしない
(bind-keys :map company-active-map
	   ("C-n" . company-select-next)
	   ("C-p" . company-select-previous))
(bind-keys :map company-search-map
	   ("C-n" . company-select-next)
	   ("C-p" . company-select-previous))

(eval-after-load "irony"
  '(progn
     (custom-set-variables '(irony-additional-clang-options '("-std=c++11")))
     (add-to-list 'company-backends 'company-irony)
     (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
     (add-hook 'c-mode-common-hook 'irony-mode)))



;;; jedi
;; (require 'jedi-core)
;; (setq jedi:complete-on-dot t)
;; (setq jedi:use-shortcuts t)
;; (add-hook 'python-mode-hook 'jedi:setup)
;; (add-to-list 'company-backends 'company-jedi)
