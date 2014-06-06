;;;; thym.lisp

(in-package #:thym)

(defvar *factorp* nil "Determines whether expressions should be factored.")

(defun ^ (base power) (expt base power))

(defun op (expr) (first expr))
(defun args (expr) (rest expr))
(defun varp (obj) (symbolp obj))

(defun operatorp (op expr) (and (consp expr) (eq (op expr) op)))
(defun sump (expr) (operatorp '+ expr))
(defun productp (expr) (operatorp '* expr))
(defun powerp (expr) (operatorp '^ expr))

(defun remove-sums (args) (remove-if #'sump args))
(defun keep-sums (args) (remove-if-not #'sump args))

(defun remove-products (args) (remove-if #'productp args))
(defun keep-products (args) (remove-if-not #'productp args))

(defun remove-powers (args) (remove-if #'powerp args))
(defun keep-powers (args) (remove-if-not #'powerp args))

(defun base (power) (second power))
(defun exponent (power) (third power))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun sym-op (op) (symbolicate "s" op)))

(defun level (expr)
  (if (atom expr)
      expr
      (let ((op (op expr)))
	(labels ((%level (expr &aux (expr (level expr)))
		   (if (and (member op '(+ *))
			  (consp expr)
			  (eq op (op expr)))
		       (rest expr)
		       (list expr))))
	  (mapcan #'%level expr)))))

(defun function-of (var expr)
  "Looks for variable somewhere in the expression."
  (if (atom expr)
      (eq expr var)
      (or (function-of var (first expr))
	 (function-of var (rest expr)))))

(defmacro defsym (op params &body body)
  `(defun ,(sym-op op) ,params
     ,@body))

(defun combine-constants (op args)
  (append (mapcar #'sym (remove-numbers args))
	  (list (apply op (mapcar #'sym (keep-numbers args))))))

(defun combine* (args)
  (let* ((powers (keep-powers args))
	 (singles (remove-duplicates (keep-symbols args)
					 :test #'eq))
	 (bases (remove-duplicates (mapcar #'base powers)
				  :test #'equalp)))
    (append
     (remove-symbols (remove-powers args))
     (mapcar (lambda (var)
	       (funcall (sym-op '^)
			var
			(apply (sym-op '+)
			       (count var args)
			       (mapcar #'exponent
				       (remove-if-not
					(lambda (x)
					  (equalp (base x) var))
					powers)))))
	     (union bases singles :test #'eq)))))

(defsym + (&rest args)
  (let ((args (remove 0 (if (some #'numberp args)
			    (combine-constants '+ args)
			    args))))
    (if (null args)
	0
	(if (singlep args)
	    (first args)
	    `(+ ,@args)))))

(defsym * (&rest args)
  (let ((args (remove 1 (combine* (if (some #'numberp args)
				      (combine-constants '* args)
				      args)))))
    (if (null args)
	1
	(if (singlep args)
	    (first args)
	    `(* ,@args)))))

(defsym ^ (base exponent)
  (cond ((eql exponent 1) base)
	((eql base 0) 0)
	((eql base 1) 1)
	((and (numberp base)
	    (numberp exponent))
	 (^ base exponent))
	(t `(^ ,base ,exponent))))

(defun sym (expr &aux (expr (level expr)))
  "Simplifies on a prefix expression."
  (if (atom expr)
      expr
      (if (fboundp (sym-op (op expr))) ; Check if there are rewrite rules available
	  (apply (sym-op (op expr)) (mapcar #'sym (args expr)))
	  (list* (op expr) (mapcar #'sym (args expr))))))

(defun ssym (string)
  "Takes infix string, simplifies, spits out a nice output string."
  (funcall (compose #'untokenize
		    #'unparenthesize
		    #'prefix->infix
		    #'sym
		    #'infix->prefix
		    #'parenthesize
		    #'tokenize)
	   string))
