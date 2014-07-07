(in-package #:thym)

(defexpr exp-base (efun) () ())

(defmethod inverse ((fun exp-base))
  'logarithm)

(defmethod exponent ((expr exp-base))
  (first (args expr)))

(defexpr exp (exp-base) () (arg)
  (make-expr 'exp (list arg)))

(defmethod print-object ((object exp) stream)
  (format stream "e ^ ~A" (exponent object)))

(defmethod antideriv ((expr exp))
  (lambda (u) (exp u)))

(defmethod base ((expr exp))
  (exp 1))

(defmethod first-deriv ((expr exp) wrt)	expr)

(defexpr log (efun) () (arg)
  (make-expr 'log (list arg)))

(defmethod first-deriv ((expr log) wrt)
  (^ (first (args expr)) -1))

(defmethod inverse ((expr log))
  'exp)
