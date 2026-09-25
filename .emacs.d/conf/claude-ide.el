(use-package ghostel
  :vc (:url "https://github.com/dakra/ghostel"
       :lisp-dir "lisp"
       :rev :newest)
  :hook
  ;; Hide line numbers enabled by global-display-line-numbers-mode
  (ghostel-mode . (lambda () (display-line-numbers-mode -1)))
  :custom
  ;; Use arrow keys for window movement (windmove) instead of sending them to the terminal
  (ghostel-keymap-exceptions
   '("C-c" "C-x" "C-u" "C-h" "M-x" "M-:" "C-\\"
     "<left>" "<right>" "<up>" "<down>")))

(use-package claude-code-ide
  :vc (:url "https://github.com/manzaltu/claude-code-ide.el" :rev :newest)
  :bind ("C-c '" . claude-code-ide-menu)
  :custom
  (claude-code-ide-terminal-backend 'ghostel)
  :config
  (claude-code-ide-emacs-tools-setup))
