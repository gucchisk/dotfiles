(gptel-make-gh-copilot "Copilot")
;; OPTIONAL configuration
(setq gptel-model 'claude-3.7-sonnet
  gptel-backend (gptel-make-gh-copilot "Copilot"))

(with-eval-after-load 'markdown-mode
  (define-key markdown-mode-map (kbd "C-c C-c") #'gptel-send))
