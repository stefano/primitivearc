; a server to avoid launching a new Arc for each test

; arc2 def
(set def (annotate 'mac
               (fn (name parms . body)
                 `(do (sref sig ',parms ',name)
                      (safeset ,name (fn ,parms ,@body))))))

; no prints
(set safeset (annotate 'mac
                  (fn (var val)
                    `(do (set ,var ,val)))))

(load "compiler/comp.arc")

(def upto-eof (i)
  (let e (read i)
    (if (is e 'eof)
      nil
      (cons e (upto-eof i)))))

(def ss-expand (l)
  (if (no l) nil
      (no (acons l)) (if (and (isa l 'sym) (ssyntax l))
                       (ssexpand l)
                       l)
      (acons l) (cons (ss-expand (car l)) (ss-expand (cdr l)))))

(w/socket s 4321
  (prn "Started")
  (while t
    ; one client at a time
    (let (i o ip) (socket-accept s)
      (prn "Serving: " ip)
      (let it `((fn () ,@(ss-expand (upto-eof i))))
        (w/stdout o
          (errsafe (tl-compile it))))
      (close i)
      (close o))))
