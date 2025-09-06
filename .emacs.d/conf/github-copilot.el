(require 'copilot)
(add-hook 'prog-mode-hook 'copilot-mode)
(define-key copilot-completion-map (kbd "<tab>") 'copilot-accept-completion)
(define-key copilot-completion-map (kbd "TAB") 'copilot-accept-completion)

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
  (define-key global-map (kbd "C-c c r") #'copilot-chat-reset)
  )
