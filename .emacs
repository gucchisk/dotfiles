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

(when (eq system-type 'darwin)
  (add-to-list 'load-path "/usr/local/opt/cmake/share/emacs/site-lisp/cmake"))

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
(require 'helm-config)
(helm-mode 1)

;;; company
(load "comp")

;;; javascript
(load "javascript")

;;; typescript
(load "typescript")

;;; c++
(load "cpp")

;;; python
(load "py")

;;; dash
(load "dash-mac")

;;; php
(load "php")

;;; go
(load "go")

;;; gyp
(require 'gyp)

;;; wat
(require 'wat-mode)

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))
