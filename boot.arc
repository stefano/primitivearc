; Copyright (c) 2008 Dissegna Stefano

; quasiquoting

; helper fns and macs

(set and 
  (annotate 'mac 
    (fn (a b)
      (list 'if a (list 'if b t)))))

(set no (fn (x) (if x nil t)))

(set atom (fn (x) (no (is (type x) 'cons))))
(set acons (fn (x) (is (type x) 'cons)))
(set cadr [car (cdr _)])

(set let 
  (annotate 'mac (fn (x y . bd) (list (cons 'fn (cons (list x) bd)) y))))

(set map1 (fn (f l) (if l (cons (f (car l)) (map1 f (cdr l))))))

(set splice 
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

(set eval-qq 
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

(set quasiquote 
  (annotate 'mac 
    (fn (x)
      (splice (eval-qq x 1) nil))))

