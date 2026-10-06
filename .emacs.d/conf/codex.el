(use-package codex-ide
  :vc (:url "https://github.com/dgillis/emacs-codex-ide" :rev :newest)
  :bind ("C-c C-;" . codex-ide-menu))

(setq codex-ide-cli-extra-flags
  "-c sandbox_workspace_write.network_accerss=true")
