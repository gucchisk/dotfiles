;;
;; require @vue/language-server typescript typescript-language-server

;; vue, js, ts
(use-package lsp-mode
  :hook ((web-mode . lsp))
  :commands lsp)

(use-package lsp-ui
  :commands lsp-ui-mode)

(use-package company
  :hook (after-init . global-company-mode))

;; web-mode
(use-package web-mode
  :mode ("\\.vue\\'" . web-mode)
  :config
  (setq web-mode-enable-auto-quoting nil)
  (setq web-mode-content-types-alist
        '(("vue" . "\\.vue\\'")))
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  (setq-local copilot-infer-indentation-offset 2))

;; prettier-js
(use-package prettier-js
  :hook ((web-mode . prettier-js-mode)
         (js-mode . prettier-js-mode)
         (typescript-mode . prettier-js-mode)))

;; emmet
(use-package emmet-mode
  :hook ((web-mode . emmet-mode)))

(use-package exec-path-from-shell
  :if (memq window-system '(mac ns x))
  :config
  (exec-path-from-shell-initialize))

;; (with-eval-after-load 'lsp-mode
;;   (add-to-list 'lsp-language-id-configuration '(web-mode . "vue"))
;;   (lsp-register-client
;;    (make-lsp-client
;;     :new-connection (lsp-stdio-connection '("vue-language-server" "--stdio"))
;;     :major-modes '(web-mode)
;;     :priority -1
;;     :server-id 'volar)))
(with-eval-after-load 'lsp-mode
  (setq lsp-clients-vue-server-command '("vue-language-server" "--stdio")))
