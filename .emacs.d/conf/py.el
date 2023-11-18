;;; jedi
(require 'jedi-core)
(setq jedi:server-command (list (executable-find "jediepcserver")))
(setq jedi:complete-on-dot t)
(setq jedi:use-shortcuts t)
(add-hook 'python-mode-hook
	  (lambda ()
	    (company-mode)
	    'jedi:setup))
(add-to-list 'company-backends 'company-jedi)
