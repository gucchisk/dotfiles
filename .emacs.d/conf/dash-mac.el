;;; dash
(autoload 'dash-at-point "dash-at-point"
  "Search the word at point with Dash." t nil)
(bind-key "C-c d" 'dash-at-point)
(bind-key "C-c e" 'dash-at-point-with-docset)
