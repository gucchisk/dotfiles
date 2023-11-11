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
