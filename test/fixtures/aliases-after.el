;;; -*- lexical-binding: t -*-
;;; Generated from an ikigai kernel's manifold — do not edit.
;;;
;;; A FIXTURE for test/ikigai-test.el: the second refresh, after the grant
;;; narrowed.  `urn:host:history' lost its Sink and `urn:text.head' left, so the
;;; collision is gone and `ikigai-text-head' now names `urn:text:head'.

(require 'ikigai)

(defun ikigai-fn-toUpper (in &rest args)
  "Upper-cases the UTF-8 text supplied in the `in` argument."
  (apply #'ikigai-invoke 'source "urn:iki:fn:toUpper" "in" in args))

(defun ikigai-text-head (in &rest args)
  "Returns the first `n` lines of the input (default 10)."
  (apply #'ikigai-invoke 'source "urn:text:head" "in" in args))

(defun ikigai-host-history (&rest args)
  "The host's command history."
  (apply #'ikigai-invoke 'source "urn:host:history" args))

(provide 'ikigai-aliases)
