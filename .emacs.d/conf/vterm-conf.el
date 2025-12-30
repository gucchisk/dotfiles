;;; vterm configuration

;; vterm package
(use-package vterm
  :ensure t
  :config
  ;; Use arrow keys for window movement instead of cursor movement in vterm
  (define-key vterm-mode-map (kbd "<left>") 'windmove-left)
  (define-key vterm-mode-map (kbd "<right>") 'windmove-right)
  (define-key vterm-mode-map (kbd "<up>") 'windmove-up)
  (define-key vterm-mode-map (kbd "<down>") 'windmove-down))
