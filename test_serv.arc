; a server to avoid launching a new Arc for each test

(load "compiler/comp.arc")

(def upto-eof (i)
  (let e (read i)
    (if (is e 'eof)
      nil
      (cons e (upto-eof i)))))

(w/socket s 4321
  (prn "Started")
  (while t
    ; one client at a time
    (let (i o ip) (socket-accept s)
      (prn "Serving: " ip)
      (let it `((fn () ,@(upto-eof i)))
        (w/stdout o
          (errsafe (tl-compile it))))
      (close i)
      (close o))))
