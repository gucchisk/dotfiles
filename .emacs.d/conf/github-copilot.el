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
(require 'copilot-chat)
(global-set-key (kbd "C-c c c") 'copilot-chat-display)
(global-set-key (kbd "C-c c r") 'copilot-chat-reset)
