(def newstring (n (o c #\space))
  (tostring 
    (repeat n
      (disp c))))

(def read ((o p (stdin)) (o eof nil))
  (let r (_read p)
    (if (is r "#<eof>")
      eof
      r)))

(= sread read)
