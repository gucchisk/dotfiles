;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)
(setq package-archives
      '(("gnu" . "http://elpa.gnu.org/packages/")
        ("melpa" . "http://melpa.org/packages/")
        ("org" . "http://orgmode.org/elpa/")))
(add-to-list 'load-path "~/.emacs.d/elpa")
(add-to-list 'load-path "~/.emacs.d/elisp")
(add-to-list 'load-path "~/.emacs.d/conf")
;; (setq package-check-signature nil)

;;; line number
(if (version<= "26.0.50" emacs-version)
    (progn
      (global-display-line-numbers-mode)
      (set-face-attribute 'line-number nil
                          :foreground "OliveDrab"
                          :background "gray17")
      (set-face-attribute 'line-number-current-line nil
                          :foreground "gold")
      ))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; tab->space
(setq-default indent-tabs-mode nil)

(when (eq system-type 'darwin)
  (add-to-list 'load-path "/usr/local/opt/cmake/share/emacs/site-lisp/cmake"))

;;; mark-multiple
(require 'inline-string-rectangle)
(global-set-key (kbd "C-x r t") 'inline-string-rectangle)
(require 'mark-more-like-this)
(global-set-key (kbd "C-l") 'mark-previous-like-this)
(global-set-key (kbd "C-;") 'mark-next-like-this)
(global-set-key (kbd "C-M-m") 'mark-more-like-this)
(global-set-key (kbd "C-*") 'mark-all-like-this)

;;; ignore cl deprecated warning
(setq byte-compile-warnings '(cl-functions))

;;; theme
(load-theme 'tango-dark t)

;;; .emacs symlink
(setq vc-follow-symlinks t)

;;; menu bar
(menu-bar-mode 0)

;;; key bind
(require 'bind-key)

;;; global keybind
(load "keybind")

;;; helm
(require 'helm)
(helm-mode 1)

;;; company
(load "comp")

;;; typescript
(load "typescript")

;;; javascript
(load "javascript")

;;; c++
(load "cpp")

;;; python
(load "py")

;;; dash
(load "dash-mac")

;;; php
(load "php-conf")

;;; go
(load "go")

;;; swift
(load "swift")

;;; gyp
(require 'gyp)

;;; wat
(require 'wat-mode)

;;; markdown
(load "md")

;;; shell
(load "sh")

;;; copilot
(load "github-copilot")

;;; vue
(load "vue")

;;; lsp
(load "lsp-conf")
