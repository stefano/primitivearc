; Copyright (c) 2008 Dissegna Stefano

; functions needed to run compiled pbc compiler

; helper fns

(assign sig (table))
(assign help* (table))
(assign source-file* (table))
(assign source* (table))
(assign current-load-file* nil)

; TODO: make it really atomic
(assign atomic-invoke (fn (f) (f)))

(assign no (fn (x) (if x nil t)))

(assign sym intern)

(def atom (x) (no (is (type x) 'cons)))
(def acons (x) (is (type x) 'cons))
(assign alist acons)

(def isa (x what) (is (type x) what))

(def caar (x) (car (car x)))
(def cadr (x) (car (cdr x)))
(def cddr (x) (cdr (cdr x)))

(def map1 (f l)
  ((afn (l acc)
     (if l
       (self (cdr l) (cons (f (car l)) acc))
       (rev acc))) l nil))

(def mem (x l)
  (if (no l) l
    (is (car l) x) x
    (mem x (cdr l))))

(assign coerce-table* (table))

(def coerce (what into)
  (if (isa what into)
    what
    (let f (coerce-table* (cons (type what) into))
      (if f
        (f what)
        (err (string "Can't coerce " what " into " into))))))

(def dcoerce (a b f)
  (= (coerce-table* (cons a b)) f))

(= (coerce-table* '(char . int)) char->int)
(= (coerce-table* '(int . char)) int->char)

(dcoerce 'char 'string string)
(dcoerce 'char 'sym [sym (string _)])
(dcoerce 'int 'string string)
(dcoerce 'num 'string string)
(dcoerce 'string 'sym sym)
(dcoerce 'string 'cons [str>lst _ 0])

(dcoerce 'string 'int 
  [let it (read (instring _))
    (if (isa it 'int)
      it
      (err (string "Can't coerce string " it " to int")))])

(dcoerce 'cons 'string
  [let o (outstring)
    (call-w/stdout o (fn () (map1 pr _)))
    (inside o)])

(dcoerce 'nil 'string (fn (it) ""))
(dcoerce 'sym 'string string)

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

; not the official some
(def at-least-one (test l)
  (if l
    (or (test (car l)) (at-least-one test (cdr l)))
    nil))

; from arc.arc (minus string stuff)
(def map (f . seqs)
  (if (no (cdr seqs)) 
       (map1 f (car seqs))
      ((afn (seqs acc)
        (if (at-least-one no seqs)  
            (rev acc)
            (self (map1 cdr seqs) 
                  (cons (apply f (map1 car seqs)) acc))))
       seqs nil)))

; from arc.arc
(def listtab (al)
  (let h (table)
    (map (fn ((k v)) (= (h k) v))
         al)
    h))

(assign join +)

(def exact (x) (isa x 'int))

; from arc.arc
(def assoc (key al)
  (if (atom al)
       nil
      (and (acons (car al)) (is (caar al) key))
       (car al)
      (assoc key (cdr al))))

(def load-and-dump (file-in file-out)
  (let o (outfile file-out)
    (call-w/stdout o (fn () (load file-in t)))
    (close o)))
