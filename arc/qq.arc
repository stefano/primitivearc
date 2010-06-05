; quasiquoting

(assign tag-data cadr)
(assign tag-backquote?
  (fn (x) (if (acons x) (is (car x) 'quasiquote))))
(assign tag-comma?
  (fn (x) (if (acons x) (is (car x) 'unquote))))
(assign tag-comma-atsign?
  (fn (x) (if (acons x) (is (car x) 'unquote-splicing))))

(assign qq-expand 
  (fn (x)
   (if 
     (tag-comma? x)
       (tag-data x)
     (tag-comma-atsign? x)
       (err "Illegal")
     (tag-backquote? x)
       (qq-expand
         (qq-expand (tag-data x)))
     (acons x)
       (list '+
             (qq-expand-list (car x))
             (qq-expand (cdr x)))
     (list 'quote x))))

(assign qq-expand-list 
  (fn (x)
    (if
      (tag-comma? x)
        (list 'list (tag-data x))
      (tag-comma-atsign? x)
        (tag-data x)
      (tag-backquote? x)
        (qq-expand-list
          (qq-expand (tag-data x)))
      (acons x)
         (list 'list
               (list '+
                 (qq-expand-list (car x))
                 (qq-expand (cdr x))))
      (list 'quote (list x)))))

(assign quasiquote
  (annotate 'mac qq-expand))
