(require 'claude-code)
(global-set-key (kbd "C-c c") 'claude-code-transient)

;; Add vterm-copy-mode keybinding for scrollback
(with-eval-after-load 'claude-code-ui
  (define-key claude-code-vterm-mode-map (kbd "C-c C-y") 'vterm-copy-mode))
