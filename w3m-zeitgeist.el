;;; w3m-zeitgeist.el --- 
;;
;; Copyright (C) 2011 Hironori OKAMOTO
;;
;; Author: Hironori OKAMOTO <k.ten87@gmail.com>
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see http://www.gnu.org/licenses/.


;;; Commentary:
;;
;; 

;;; Code:

(require 'w3m)
(require 'zeitgeist)

(defun w3m-zeitgeist-event-interpretation (event)
  "Get the Event Interpretation of EVENT."
  (case event
    (w3m-zeitgeist-access-web-event
     "http://www.zeitgeist-project.com/ontologies/2010/01/27/zg#AccessEvent")
    (w3m-zeitgeist-leave-web-event
     "http://www.zeitgeist-project.com/ontologies/2010/01/27/zg#LeaveEvent")
    (t (error "Unknown event %s" event))))

(defun w3m-zeitgeist-send (event &rest props)
  "Send zeitgeist the EVENT with PROPS."
  (let ((event-interpretation (w3m-zeitgeist-event-interpretation event)))
    (condition-case error
	(case event
	  ((w3m-zeitgeist-access-web-event
	    w3m-zeitgeist-leave-web-event)
	   (zeitgeist-call
	    "InsertEvents"
	    (zeitgeist-create-event
	     event-interpretation
	     (plist-get props :uri)
	     "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#Website"
	     "http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#RemoteDataObject"
	     (file-name-directory (plist-get props :uri))
	     (plist-get props :mimetype)
	     (plist-get props :title)
	     (file-name-nondirectory
	      (file-name-sans-versions (plist-get props :uri)))
	     ""))))
      ;; Ouch, something failed when trying to communicate with zeitgeist!
      (error (message "ERROR (ZEITGEIST): %s" (cadr error))))))

(defun w3m-zeitgeist-display-hook (uri)
  (w3m-zeitgeist-send 'w3m-zeitgeist-access-web-event
		      :uri uri
		      :mimetype (w3m-content-type uri)
		      :title (w3m-current-title)))

(defun w3m-zeitgeist-delete-buffer-hook ()
  (w3m-zeitgeist-send 'w3m-zeitgeist-leave-web-event
		      :uri w3m-current-url
		      :mimetype (w3m-content-type w3m-current-url)
		      :title (w3m-current-title)))

(add-hook 'w3m-display-hook 'w3m-zeitgeist-display-hook)

(add-hook 'w3m-delete-buffer-hook 'w3m-zeitgeist-delete-buffer-hook)

(defadvice w3m-goto-url (before w3m-zeitgeist activate)
  (when w3m-current-url
    (w3m-zeitgeist-send 'w3m-zeitgeist-leave-web-event
			:uri w3m-current-url
			:mimetype (w3m-content-type w3m-current-url)
			:title (w3m-current-title))))

(provide 'w3m-zeitgeist)

;;; w3m-zeitgeist.el ends here
