;;; -*- lexical-binding: t -*-
;;; Generated from an ikigai kernel's manifold — do not edit.
;;;
;;; A FIXTURE for test/ikigai-test.el, hand-written in the shape
;;; `aliases_elisp' (ikigai-cli) emits: the first of two refreshes.

(require 'ikigai)

(defun ikigai-fn-toUpper (in &rest args)
  "Upper-cases the UTF-8 text supplied in the `in` argument."
  (apply #'ikigai-invoke 'source "urn:iki:fn:toUpper" "in" in args))

(defun ikigai-text-head (in &rest args)
  "Returns the last `n` lines of the input (default 10)."
  (apply #'ikigai-invoke 'source "urn:text.head" "in" in args))

;; SKIPPED urn:text:head (Source): `ikigai-text-head` is already defined above — two IRIs, one name.
;; Still reachable as (ikigai-invoke 'source "urn:text:head").

(defun ikigai-host-history (&rest args)
  "The host's command history."
  (apply #'ikigai-invoke 'source "urn:host:history" args))

(defun ikigai-host-history! (content &rest args)
  "Turns history recording on or off."
  (apply #'ikigai-invoke 'sink "urn:host:history" "content" content args))

;; SKIPPED urn:demo:odd (Frobnicate): `Frobnicate` is not a kernel verb.
;; Still reachable as (ikigai-invoke 'frobnicate "urn:demo:odd").

(provide 'ikigai-aliases)
