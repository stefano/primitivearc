; quasiquoting

(assign splice 
  (fn (l before)
    (if (and (no (acons l)) l)
      l
      (if (no l)
        before
        (if (acons (car l))
          (if (is (car (car l)) '__to-splice)
            (let res (list '+ before (splice (cadr (car l)) nil))
              (list '+ res (cons 'list (splice (cdr l) nil))))
            (splice (cdr l) (+ before (list (splice (car l) nil)))))
          (splice (cdr l) (+ before (list (car l)))))))))

(assign eval-qq 
  (fn (x level)
    (if (is level 0) x
        (atom x) (list 'quote x)
        (and (is level 1) (is (car x) 'unquote))
          (eval-qq (cadr x) (- level 1))
        (is (car x) 'unquote)
          (list 'unquote (eval-qq (cadr x) (- level 1)))
        (and (is level 1) (is (car x) 'splice))
          (list '__to-splice (eval-qq (cadr x) (- level 1)))
        (is (car x) 'splice)
          (list 'splice (eval-qq (cadr x) (- level 1)))
        (is (car x) 'quasiquote)
          (list 'quasiquote (eval-qq (cadr x) (+ level 1)))
        (cons 'list (map1 [eval-qq _ level] x)))))

(assign quasiquote 
  (annotate 'mac 
    (fn (x)
      (splice (eval-qq x 1) nil))))
