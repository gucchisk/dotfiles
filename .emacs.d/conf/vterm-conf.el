;;; vterm configuration

;; vterm package
(use-package vterm
  :ensure t
  :hook
  ;; Hide line numbers enabled by global-display-line-numbers-mode
  (vterm-mode . (lambda () (display-line-numbers-mode -1)))
  :config
  ;; Use arrow keys for window movement instead of cursor movement in vterm
  (define-key vterm-mode-map (kbd "<left>") 'windmove-left)
  (define-key vterm-mode-map (kbd "<right>") 'windmove-right)
  (define-key vterm-mode-map (kbd "<up>") 'windmove-up)
  (define-key vterm-mode-map (kbd "<down>") 'windmove-down))
