;;; c++
(add-hook 'c++-mode-hook
	  '(lambda()
	     (c-set-offset 'innamespace 0)))

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
  '(add-to-list 'company-backends '(company-irony-c-headers company-irony)))

(setq irony-lang-compile-option-alist
      (quote ((c++-mode . "c++ -std=c++11 -lstdc++")
	      (c-mode . "c")
	      (objc-mode . "objective-c"))))

;;; cmake-mode
(require 'cmake-mode)
