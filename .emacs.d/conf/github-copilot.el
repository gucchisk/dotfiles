(require 'copilot)
;; with-temp-buffer 内でのフォント付け等で prog-mode が起動した場合は有効にしない
(defun copilot-mode-enable-unless-temp-buffer ()
  (unless (or (string-prefix-p " " (buffer-name))
              (string-prefix-p "*temp*" (buffer-name)))
    (copilot-mode 1)))
(add-hook 'prog-mode-hook #'copilot-mode-enable-unless-temp-buffer)
(define-key copilot-completion-map (kbd "<tab>") 'copilot-accept-completion)
(define-key copilot-completion-map (kbd "TAB") 'copilot-accept-completion)

;; for go-mode: インデント推測をオーバーライド
(with-eval-after-load 'copilot
  (defun copilot--infer-indentation-offset-advice (original-fn)
    (if (derived-mode-p 'go-mode)
        tab-width
      (funcall original-fn)))
  (advice-add 'copilot--infer-indentation-offset :around #'copilot--infer-indentation-offset-advice))

;; for elisp-mode
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq-local lisp-indent-offset 2)))
(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq-local copilot-indent-offset 2)))

;; copilot-chat
(use-package copilot-chat
  :ensure t
  :after (copilot)
  :config
  ;; 設定をここに書く
  )
(setopt copilot-chat-backend 'request)
(with-eval-after-load 'copilot-chat
  (define-key global-map (kbd "C-c c c") #'copilot-chat-display)
  (define-key global-map (kbd "C-c c a") #'copilot-chat-add-current-buffer)
  (define-key global-map (kbd "C-c c s") #'copilot-chat-custom-prompt-selection)
  (define-key global-map (kbd "C-c c r") #'copilot-chat-reset)
  )
