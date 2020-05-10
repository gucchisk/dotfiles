(require 'go-mode)
(with-eval-after-load 'go-mode
  (bind-key "M-." 'godef-jump go-mode-map)
  (bind-key "M-," 'pop-tag-mark go-mode-map))

(add-to-list 'exec-path (expand-file-name "~/go/bin"))

(add-hook 'go-mode-hook
	  (lambda ()
	    (company-mode)
	    (add-to-list 'company-backends 'company-go)))
