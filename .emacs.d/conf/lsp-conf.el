(with-eval-after-load 'lsp-mode
  (bind-key "M-/" 'lsp-find-references lsp-mode-map)
  (bind-key "M-." 'lsp-find-definition lsp-mode-map))
