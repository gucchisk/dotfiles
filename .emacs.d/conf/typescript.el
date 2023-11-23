;;; tide for typescript
(defun setup-tide-mode ()
  (interactive)
  (tide-setup)
  (flycheck-mode +1)
  (setq flycheck-check-syntax-automatically '(save mode-enabled))
  (eldoc-mode +1)
  (tide-hl-identifier-mode +1)
  (setq tide-format-options '(:indentSize 2))
  ;;; company is an optional dependency. You have to
  ;;; install it separately via package-install
  ;;; `M-x package-install [ret] company`
  (company-mode +1))

;;; formats the buffer before saving
(add-hook 'before-save-hook 'tide-format-before-save)

;;; if you use typescript-mode
;; (add-hook 'typescript-mode-hook #'setup-tide-mode)
(add-hook 'typescript-ts-mode-hook #'setup-tide-mode)

(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))
