(with-eval-after-load 'magit-diff
  (define-key magit-diff-mode-map (kbd "RET") 'magit-diff-visit-file-other-window))
