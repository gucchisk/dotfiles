(require 'multiple-cursors)

(global-set-key (kbd "C-;") 'mc/mark-next-like-this-symbol)
(global-set-key (kbd "C-M-;") 'mc/skip-to-next-like-this)
(global-set-key (kbd "C-l") 'mc/mark-previous-like-this-symbol)
(global-set-key (kbd "C-c C-;") 'mc/mark-all-symbols-like-this)
(global-set-key (kbd "C-c m l") 'mc/edit-lines)
