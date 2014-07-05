(in-package #:thym)

(defexpr + (assoc-expr) ((identity :allocation :class
                                   :initform 0))
    (&rest args)
  (assoc-expr '+ args))

(defmethod deriv ((expr +) wrt &optional (n 1))
  (apply #'+ (mapcar (rcurry #'deriv wrt n) (args expr))))

(defmethod level ((expr +))
  (let ((args (args expr))
        (terms (make-hash-table :test #'equals))
        new-args)
    (push (first args) args)
    (do* ((%args args (rest (progn (pop args) args)))
          (arg (first %args) (first %args)))
         ((endp (rest args)))
      (let (c s)
        (cond
          ((numberp arg)
           (setf c arg))
          ((typep arg '+)
           (appendf args (args arg)))
          ((typep arg '*)
           (setf (values c s) (as-coeff-mul arg)))
          ((typep arg '^)
           (setf c 1 s arg))
          (t (setf c 1 s arg)))
        (setf (gethash s terms)
              (if (gethash s terms)
                  (cl:+ (gethash s terms) c)
                  c))))
    (maphash (lambda (s c)
               (cond
                 ((null s)
                  (push c new-args))
                 ((zerop c))
                 ((eql c 1)
                  (push s new-args))
                 ((typep s '*)
                  (push (func s (list* c (args s))) new-args))
                 (t
                  (push (* c s) new-args))))
             terms)
    (string-sort new-args)))
