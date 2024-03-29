(require 'go-mode)

;;; godef
;; (with-eval-after-load 'go-mode
;;   (bind-key "M-." 'godef-jump go-mode-map)
;;   (bind-key "M-," 'pop-tag-mark go-mode-map))

(add-to-list 'exec-path (expand-file-name "~/go/bin"))

;;; gopls
;; require `go install golang.org/x/tools/gopls@latest`
(require 'lsp-mode)
(add-hook 'go-mode-hook #'lsp-deferred)
(add-hook 'go-mode-hook
          (lambda ()
            (setq tab-width 4)
            (company-mode)
            (add-to-list 'company-backends 'company-capf)))
;; (setq lsp-prefer-capf t)

;; Set up before-save hooks to format buffer and add/delete imports.
;; Make sure you don't have other gofmt/goimports hooks enabled.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

(lsp-register-custom-settings
 '(("gopls.completeUnimported" t t)
   ("gopls.staticcheck" t t)))

;;; go guru
;; (require 'go-guru)
;; (add-hook 'go-mode-hook #'go-guru-hl-identifier-mode)
;; (with-eval-after-load 'go-guru
;;   (bind-key "M-m" 'go-guru-referrers go-mode-map))
