; Copyright (c) 2008 Dissegna Stefano

; functions needed to run compiled pbc compiler

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

(def cadr (x) (car (cdr x)))
(def cddr (x) (cdr (cdr x)))

(def map1 (f l)
  (if l (cons (f (car l)) (map1 f (cdr l)))))

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
