;;; c++
(add-hook 'c++-mode-hook
	  '(lambda()
	     (c-set-offset 'innamespace 0)
	     (c-set-offset 'access-label -1)
             ))

(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))

(require 'irony)
(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-moded)
(add-hook 'objc-mode-hook 'irony-mode)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
(add-hook 'irony-mode-hook
	  '(lambda()
	     (setq irony--server-executable (expand-file-name "~/.emacs.d/irony/bin/irony-server"))
	     (company-mode t)))

(require 'company-irony-c-headers)
(with-eval-after-load 'company
  (add-to-list 'company-backends '(company-irony-c-headers company-irony)))

(setq irony-lang-compile-option-alist
      (quote ((c-mode . "c")
	      (c++-mode . "c++ -std=c++11 -lstdc++")
	      (objc-mode . "objective-c"))))
(defun ad-irony--lang-compile-option ()
  (defvar irony-lang-compile-option-alist)
  (let ((it (cdr-safe (assq major-mode irony-lang-compile-option-alist))))
    (when it (append '("-x") (split-string it "\s")))))
(advice-add 'irony--lang-compile-option :override #'ad-irony--lang-compile-option)

;;; cmake-mode
(require 'cmake-mode)


;;; rtags
(add-to-list 'load-path "/opt/homebrew/Cellar/rtags/2.40_3/share/emacs/site-lisp/rtags/")

(use-package cmake-ide
  :bind
  (("<f9>" . cmake-ide-compile))
  :config
  (progn
    (setq
     cmake-ide-rdm-executable "/opt/homebrew/bin/rdm"
     cmake-ide-rc-executable "/opt/homebrew/bin/rc")))

(use-package rtags
  :config
  (rtags-enable-standard-keybindings c-mode-base-map)
  (cmake-ide-setup)
  (setq rtags-path "/opt/homebrew/bin")
  (bind-keys :map c-mode-base-map
             ("M-." . rtags-find-symbol-at-point)
             ("M-," . rtags-location-stack-back)
             ("M-/" . rtags-find-references-at-point)
             ("M-;" . rtags-find-symbol)
             )
  )
