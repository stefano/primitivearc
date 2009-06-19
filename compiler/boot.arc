; Copyright (c) 2008 Dissegna Stefano

; functions needed to run compiled pbc compiler

; quasiquoting

; helper fns

(set sig (table))
; TODO: make it really atomic
(set atomic-invoke (fn (f) (f)))

(set no (fn (x) (if x nil t)))

(set sym intern)

(let next 0
  (def uniq ()
    (= next (+ next 1))
    (sym (string "gs" next))))

(def atom (x) (no (is (type x) 'cons)))
(def acons (x) (is (type x) 'cons))
(set alist acons)

(def isa (x what) (is (type x) what))

(def cadr (x) (car:cdr x))
(def cddr (x) (cdr:cdr x))

(def map1 (f l)
  ;(ero 'map1 l)
  (if l (cons (f (car l)) (map1 f (cdr l)))))

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

;(set quasiquote 
;  (annotate 'mac 
;    (fn (x)
;      (splice (eval-qq x 1) nil))))

(def mem (x l)
  (if (no l) l
    (is (car l) x) x
    (mem x (cdr l))))

(set coerce-table* (table))

(def coerce (what into)
  ((coerce-table* (cons (type what) into)) what))

(= (coerce-table* '(string . cons)) (fn (s) (str>lst s 0)))

(def str>lst (s pos)
  (if (< pos (len s))
    (cons (s pos) (str>lst s (+ pos 1)))
    nil))

(def rev (lst)
  (let f (afn (l acc)
           (if l (self (cdr l) (cons (car l) acc)) acc))
    (f lst nil)))

(def intersperse (x into)
  (let f (afn (into)
           (if into
             (cons x (cons (car into) (self (cdr into))))
             nil))
    (cons (car into) (f (cdr into)))))

; from arc.arc
(def flat (x)
  ((afn (x acc)
     (if (no x)   acc
         (atom x) (cons x acc)
                  (self (car x) (self (cdr x) acc))))
   x nil))

; from arc.arc (anarki)
(def makeproper (lst)
  (if (no (acons lst))
      lst
      (cons (car lst)
            (if (alist (cdr lst))
              (makeproper (cdr lst))
              (list (cdr lst))))))

; not the official some
(def some (test l)
  (if l
    (or (test (car l)) (some test (cdr l)))
    nil))

; from arc.arc (minus string stuff)
(def map (f . seqs)
;  (ero 'map seqs)
  (if (no (cdr seqs)) 
       (map1 f (car seqs))
      ((afn (seqs)
        (if (some no seqs)  
            nil
            (cons (apply f (map1 car seqs))
                  (self (map1 cdr seqs)))))
       seqs)))

; from arc.arc
(def listtab (al)
  (let h (table)
    (map (fn ((k v)) (= (h k) v))
         al)
    h))

(set join +)
