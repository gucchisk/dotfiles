;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(js-indent-level 2)
 '(package-selected-packages
   (quote
    (company-jedi company-irony irony yaml-mode js2-mode swift-mode))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(global-set-key "\C-h" 'delete-backward-char)

;; window move
(global-set-key (kbd "<left>") 'windmove-left)
(global-set-key (kbd "<right>") 'windmove-right)
(global-set-key (kbd "<up>") 'windmove-up)
(global-set-key (kbd "<down>") 'windmove-down)

;;; menu bar
(menu-bar-mode 0)

;; company
(require 'company)
(global-company-mode)
(setq company-idle-delay 0)
(setq company-minimum-prefix-length 2)
(setq company-selection-wrap-around t)

(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c-mode-hook 'company-mode)
(add-hook 'objc-mode-hook 'company-mode)

(defun company--insert-candidate2 (candidate)
  (when (> (length candidate) 0)
    (setq candidate (substring-no-properties candidate))
    (if (eq (company-call-backend 'ignore-case) 'keep-prefix)
        (insert (company-strip-prefix candidate))
      (if (equal company-prefix candidate)
          (company-select-next)
          (delete-region (- (point) (length company-prefix)) (point))
        (insert candidate))
      )))

(defun company-complete-common2 ()
  (interactive)
  (when (company-manual-begin)
    (if (and (not (cdr company-candidates))
             (equal company-common (car company-candidates)))
        (company-complete-selection)
      (company--insert-candidate2 company-common))))

(define-key company-active-map [tab] 'company-complete-common2)
(define-key company-active-map [backtab] 'company-select-previous)

;; (setq company-transformers '(company-sort-by-statistics company-sort-by-backend-importance))

;; irony
(require 'irony)
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
(with-eval-after-load 'company
  (add-to-list 'company-backends 'company-irony))

;; (setq irony-lang-compile-option-alist
;;       '((c++-mode . ("c++" "-std=c++11" "-lstdc++" "-lm"))
;;         (c-mode . ("c"))
;;         (objc-mode . '("objective-c"))))
;; (defun irony--lang-compile-option ()
;;   (irony--awhen (cdr-safe (assq major-mode irony-lang-compile-option-alist))
;;     (append '("-x") it)))


;; 連想リストの中身を文字列のリストに変更せず、変数そのままの構造を利用。
;; 複数のコンパイルオプションはスペースで区切る
(setq irony-lang-compile-option-alist
      (quote ((c++-mode . "c++ -std=c++11 -lstdc++")
              (c-mode . "c")
              (objc-mode . "objective-c"))))
;; アドバイスによって関数を再定義。
;; split-string によって文字列をスペース区切りでリストに変換
;; (24.4以降 新アドバイス使用)
(defun ad-irony--lang-compile-option ()
  (defvar irony-lang-compile-option-alist)
  (let ((it (cdr-safe (assq major-mode irony-lang-compile-option-alist))))
    (when it (append '("-x") (split-string it "\s")))))
(advice-add 'irony--lang-compile-option :override #'ad-irony--lang-compile-option)


;;; company-irony
;; (require 'irony)
;; (add-hook 'c++-mode-hook 'irony-mode)
;; (add-hook 'c-mode-hook 'irony-mode)
;; (add-hook 'objc-mode-hook 'irony-mode)
;; (with-eval-after-load 'company
;;   (add-to-list 'company-backends 'company-irony))

;; (setq irony-lang-compile-option-alist
;;       '((c++-mode . ("c++" "-std=c++11" "-lstdc++" "-lm"))
;; 	))
;; (defun irony--lang-compile-option ()
;;   (irony--awhen (cdr-safe (assq major-mode irony-lang-compile-option-alist))
;;     (append '("-x") it)))

;; (defun my-irony-mode-hook ()
;;   (define-key irony-mode-map
;;     [remap completion-at-point]
;;     'irony-completion-at-point-async)
;;   (define-key irony-mode-map
;;     [remap complete-symbol]
;;     'irony-completion-at-point-async)
;;   )

;; (add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)
;; (add-hook 'irony-mode-hook 'my-irony-mode-hook)
;; (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
;; (add-hook 'irony-mode-hook 'irony-eldoc)

;; (require 'use-package)
;; (use-package irony
;;   :config
;;   (progn
;;     ; ironyのビルド&インストール時にCMAKE_INSTALL_PREFIXで指定したディレクトリへのパス。
;;     (setq irony-server-install-prefix "~/.emacs.d/irony")
;;     (add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)
;;     (add-hook 'irony-mode-hook 'my-irony-mode-hook)
;;     (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
;;     (add-hook 'irony-mode-hook 'irony-eldoc)
;;     (with-eval-after-load 'company
;;       (add-to-list 'company-backends 'company-irony))
;;     )
;;   )

;;; company
;; (require 'company)
;; (add-hook 'c++-mode-hook 'company-mode)
;; (add-hook 'c-mode-hook 'company-mode)
;; (add-hook 'objc-mode-hook 'company-mode)

;;; company
(when (locate-library "company")
  (global-set-key (kbd "C-o") 'company-complete)
  ;; (setq company-idle-delay nil) ; 自動補完をしない
  (define-key company-active-map (kbd "C-n") 'company-select-next)
  (define-key company-active-map (kbd "C-p") 'company-select-previous)
  (define-key company-search-map (kbd "C-n") 'company-select-next)
  (define-key company-search-map (kbd "C-p") 'company-select-previous))
  ;; (define-key company-active-map (kbd "<tab>") 'company-complete-selection))

;;; jedi
(require 'jedi-core)
(setq jedi:complete-on-dot t)
(setq jedi:use-shortcuts t)
(add-hook 'python-mode-hook 'jedi:setup)
(add-to-list 'company-backends 'company-jedi)
