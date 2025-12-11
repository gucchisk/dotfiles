(with-eval-after-load 'jq-mode
  (setq-default jq-indent-offset 2))
(add-hook 'jq-mode-hook
  (lambda ()
    (setq jq-indent-offset 2)))
