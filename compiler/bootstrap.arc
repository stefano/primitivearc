; bootstrap the compiler

(each f '("boot.arc" "read.arc" "comp.arc")
  (emit-toplevel (cons 'do (readfile f))))
