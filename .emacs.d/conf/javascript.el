;;; js2-mode
;; (require 'js2-mode)
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.[m]*js\\'" . js2-mode))

(add-hook 'js2-mode-hook
	  (lambda ()
	    (setq js2-basic-offset 2)
	    (setq js-switch-indent-offset 2)))

(add-hook 'js2-mode-hook #'js2-imenu-extras-mode)

(require 'js2-refactor)
(add-hook 'js2-mode-hook #'js2-refactor-mode)
(js2r-add-keybindings-with-prefix "C-c C-r")
(bind-key "C-k" #'js2r-kill js2-mode-map)


(projectile-mode +1)

(require 'xref-js2)
(bind-key "M-." nil js-mode-map)

(add-hook 'js2-mode-hook (lambda ()
  (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))

(require 'company-tern)
(defun company-tern-depth (candidate)
  "Return depth attribute for CANDIDATE. 'nil' entries are treated as 0."
  (let ((depth (get-text-property 0 'depth candidate)))
    (if (eq depth nil) 0 depth)))
;; (add-to-list 'company-backends 'company-tern)
(add-hook 'js2-mode-hook
	  (lambda ()
	    (setq tern-command '("tern" "--no-port-file"))
	    (tern-mode)
	    (company-mode)))
(bind-key "M-." nil tern-mode-keymap)
(bind-key "M-," nil tern-mode-keymap)
