;;; -*- Mode: LISP; Syntax: COMMON-LISP; Package: HUNCHENTOOT; Base: 10 -*-
;;; $Header: /usr/local/cvsrep/hunchentoot/cookie.lisp,v 1.6 2007/01/01 23:50:30 edi Exp $

;;; Copyright (c) 2004-2007, Dr. Edmund Weitz.  All rights reserved.

;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:

;;;   * Redistributions of source code must retain the above copyright
;;;     notice, this list of conditions and the following disclaimer.

;;;   * Redistributions in binary form must reproduce the above
;;;     copyright notice, this list of conditions and the following
;;;     disclaimer in the documentation and/or other materials
;;;     provided with the distribution.

;;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR 'AS IS' AND ANY EXPRESSED
;;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package :hunchentoot)

(defclass cookie ()
  ((name :initarg :name
         :reader cookie-name
         :type string
         :documentation "The name of the cookie - a string.")
   (value :initarg :value
          :accessor cookie-value
          :initform ""
          :documentation "The value of the cookie. Will be URL-encoded
when sent to the browser.")
   (expires :initarg :expires
            :initform nil
            :accessor cookie-expires
            :documentation "The time \(a universal time) when the
cookie expires \(or NIL).")
   (path :initarg :path
         :initform nil
         :accessor cookie-path
         :documentation "The path this cookie is valid for \(or NIL).")
   (domain :initarg :domain
           :initform nil
           :accessor cookie-domain
           :documentation "The domain this cookie is valid for \(or NIL).")
   (secure :initarg :secure
           :initform nil
           :accessor cookie-secure
           :documentation "A generalized boolean denoting whether this
cookie is a secure cookie."))
  (:documentation "Each COOKIE objects describes one outgoing cookie."))

(defmethod initialize-instance :around ((cookie cookie) &rest init-args)
  "Ensure COOKIE has a correct slot-value for NAME."
  (let ((name (getf init-args :name)))
    (unless (http-token-p name)
      (error "~S is not a legal name for a cookie." name)))
  (call-next-method))

(defun set-cookie* (cookie &optional (reply *reply*))
  "Adds the COOKIE object COOKIE to the outgoing cookies of the
REPLY object REPLY. If a cookie with the same name
\(case-sensitive) already exists, it is replaced."
  (let* ((name (cookie-name cookie))
         (place (assoc name (cookies-out reply) :test #'string=)))
    (cond
      (place
        (setf (cdr place) cookie))
      (t
        (push (cons name cookie) (cookies-out reply))
        cookie))))

(defun set-cookie (name &key (value "") expires path domain secure (reply *reply*))
  "Creates a cookie object from the parameters provided and adds
it to the outgoing cookies of the REPLY object REPLY. If a cookie
with the name NAME \(case-sensitive) already exists, it is
replaced."
  (set-cookie* (make-instance 'cookie
                              :name name
                              :value value
                              :expires expires
                              :path path
                              :domain domain
                              :secure secure)
               reply))

(defun cookie-date (universal-time)
  "Converts UNIVERSAL-TIME to cookie date format."
  (and universal-time
       (rfc-1123-date universal-time)))

(defmethod stringify-cookie ((cookie cookie))
  "Converts the COOKIE object COOKIE to a string suitable for a
'Set-Cookie' header to be sent to the client."
  (format nil
          "~A=~A~:[~;~:*; expires=~A~]~:[~;~:*; path=~A~]~:[~;~:*; domain=~A~]~:[~;; secure~]"
          (cookie-name cookie)
          (url-encode (format nil "~A" (cookie-value cookie)) +utf-8+)
          (cookie-date (cookie-expires cookie))
          (cookie-path cookie)
          (cookie-domain cookie)
          (cookie-secure cookie)))