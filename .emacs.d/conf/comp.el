(require 'company)
(bind-key "C-o" 'company-complete)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 2)
(setq company-selection-wrap-around t)
(bind-keys :map company-active-map
	   ("C-n" . company-select-next)
	   ("C-p" . company-select-previous))
(bind-keys :map company-search-map
	   ("C-n" . company-select-next)
	   ("C-p" . company-select-previous))
