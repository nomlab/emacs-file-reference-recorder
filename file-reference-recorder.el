;;; file-reference-recorder.el --- Record files that emacs referred

;; Copyright (C) 2015 by Takuya Okada

;; Author: Takuya Okada <pitipitiunsyumikan@gmail.com>
;; URL: ***************************************************************
;; Version: 0.4
;; Package-Requires: ((request "0.2.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

(require 'json)
(require 'request)

(defgroup file-reference-recorder nil
  "File reference recorder"
  :group 'text
  :prefix "frr:")

(defcustom frr:history-location (expand-file-name "~/.file-reference-history")
  "History file location"
  :type 'string
  :group 'file-reference-recorder)

(defcustom frr:dtb-url "http://localhost:3000"
  "dtb url"
  :type 'string
  :group 'file-reference-recorder)

(defstruct frr:recorder
  is-on
  title
  path
  start-stamp)

(defstruct frr:history
  title
  path
  start-stamp
  end-stamp
  is-posted)

(defvar frr:histories ())

(defun frr:reset-file-reference-recorder ()
  (interactive)
  (frr:init-histories-file)
  (setq frr:histories))

;; file operation functions
(defun frr:init-histories-file ()
  "Initialize file storing history at frr:history-location"
  (with-temp-buffer
    (insert "()")
    (write-file frr:history-location)))

(defun frr:save-histories ()
  "save file reference histories to frr:history-location"
  (with-temp-buffer
    (insert (format "%s" frr:histories))
    (write-file frr:history-location)))

(defun frr:read-histories ()
  "read file reference histories from frr:history-location"
  (with-temp-buffer
    (insert-file-contents frr:history-location)
    (setq frr:histories (read (buffer-string)))))

; recording functions
(defun frr:stop-recording ()
  (cond ((not (frr:recorder-is-on recorder)))
        ;; 本来は，history全体を投げたい
        (t (let ((history (make-frr:history :title       (frr:recorder-title       recorder)
                                            :path        (frr:recorder-path        recorder)
                                            :start-stamp (frr:recorder-start-stamp recorder)
                                            :end-stamp   (current-time-string)
                                            :is-posted   nil)))

             (cond ((frr:history-path history)
                    (frr:post-history history)
                    (setf (frr:history-is-posted history) t))) ;; 本来は post-history 内でsuccess時にやるべきだが，requestが絶対failするのでこうしている
             (push history frr:histories))
           (frr:save-histories)
           (setf (frr:recorder-is-on recorder) nil)
           ;; TODO: Rails に history 全体を投げる処理の実装
           ;; (frr:post-histories)
           (message "Stop Recording at %s" (current-time-string)))))

(defun frr:start-recording ()
  (cond ((and (frr:recorder-is-on recorder) (eq (buffer-file-name) (frr:recorder-path recorder))))
        (t
           (frr:stop-recording) ; record previous file
           (setf (frr:recorder-is-on       recorder) t)
           (setf (frr:recorder-title       recorder) (buffer-name))
           (setf (frr:recorder-path        recorder) (buffer-file-name))
           (setf (frr:recorder-start-stamp recorder) (current-time-string))
           (message "Start Recording refering to %s at %s" (buffer-name) (current-time-string)))))

;; Post history functions
(defun frr:generate-json-from-history (history)
  (json-encode   `(("unified_history" .
                    (("title"      . ,(frr:history-title       history))
                     ("path"       . ,(frr:history-path        history))
                     ("start_time" . ,(frr:history-start-stamp history))
                     ("end_time"   . ,(frr:history-end-stamp   history))
                     ("type"       . "FileHistory"))))))

(defun frr:generate-params-from-history (history) ;; TODO: 将来的には不要なので消す
  `(("unified_history[title]"      . ,(frr:history-title       history))
    ("unified_history[path]"       . ,(frr:history-path        history))
    ("unified_history[start_time]" . ,(frr:history-start-stamp history))
    ("unified_history[end_time]"   . ,(frr:history-end-stamp   history))
    ("unified_history[type]"       . "FileHistory")))

(defun frr:post-history (history)
  (request
   (concat frr:dtb-url "/unified_histories")
   :type "POST"
   :data (frr:generate-json-from-history history)
   :params (frr:generate-params-from-history history) ;; TODO: dataのみで投げられるようにする
   :headers '(("Content-Type" . "application/json"))
   :parser 'json-read
   :success (function*
             (lambda (&key data &allow-other-keys)
               (message "I sent: %S" (assoc-default 'json data))
               (setf (frr:history-is-posted history) t)))
   :error (function*
           (lambda (&key data &allow-other-keys)
             ;; (message "Failed!" (assoc-default 'json data)) ;; 毎回失敗するため一旦削除
             )))) ;; TODO: Failedになるがhistory作成に成功する問題を修正

(defun frr:post-histories ()
  (let ((unposted-histories (remove-if-not (lambda (history) (eq nil (frr:history-is-posted history))) frr:histories)))
    (mapcar 'frr:post-history unposted-histories)))

;; main
(cond ((file-exists-p frr:history-location))
      (t (frr:init-histories-file)))
(setf recorder (make-frr:recorder))
(frr:read-histories)
(frr:start-recording)

;; setup timers
(add-hook 'find-file-hooks         'frr:start-recording)
(add-hook 'focus-in-hook           'frr:start-recording)
(add-hook 'mouse-leave-buffer-hook 'frr:start-recording)
(add-hook 'post-command-hook       'frr:start-recording)

(add-hook 'focus-out-hook   'frr:stop-recording)
(add-hook 'kill-emacs-hook  'frr:stop-recording)

(provide 'file-reference-recorder)
