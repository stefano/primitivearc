; the compiler
; compile an s-expr into PIR code
; code is emitted on stdout

(def cdddr (x)
  (cdr:cdr:cdr x))

(def caddr (x)
  (cadr:cdr x))

; hold compiler state

(def empty-state () (listtab '((reg 0) (lex nil))))

; register management

(def next-reg (cs)
  (string "$P" (++ cs!reg)))

(def reset-reg (cs)
  (= cs!reg 0))

(def free-reg (cs)
  (let r cs!reg
    (= cs!reg (- cs!reg 1))
    (string "$P" r)))

(= c-push next-reg)
(= c-pop free-reg)

(def top (cs)
  cs!reg)

(def alex (cs s)
  (mem s cs!lex))

(def e-type (e)
  (if 
    (is e t) t
    (in e nil '()) nil
    (type e)))

; expression compiler

(def tl-compile (e)
  (withs (consts-tbl (table)
          (fns consts expr) (collect-fns-and-consts (mac-ex e) nil 
                                                    "" nil consts-tbl)
          cs (empty-state))
    (prn ".HLL 'Arc'")
    ; all the functions
    (each f fns
      (compile-fn (empty-state) f))
    ; all the constants
    (prn ".sub _const_init :load :init :anon")
    (each const consts
      (compile-const (empty-state) const))
    (prn ".return ()")
    (prn ".end")
    ; entry function
    (prn ".sub _main :load :init :anon")
    (compile-expr cs expr nil)
    (prn "set_hll_global '***', " (c-pop cs))
    (prn ".return ()")
    (prn ".end")))

(let escape-table (listtab '((#\newline "\\n")
                             (#\\ "\\\\")
                             (#\tab "\\t")
                             (#\" "\\\"")))
  (def pr-escape (x)
    (each c (coerce x 'cons)
      (aif (escape-table c)
        (pr it)
        (pr c)))))

; compile a single expression
(def compile-expr (cs e is-tail)
  (let out-reg (c-push cs)
    (case (e-type e)
      nil (prn out-reg " = get_hll_global 'nil'")
      t (prn out-reg " = get_hll_global 't'")
      string (do
               (prn out-reg " = new 'ArcStr'")
               (pr out-reg " = \"") 
               (pr-escape e)
               (prn "\""))
      int (do 
            (prn out-reg " = new 'ArcInt'") 
            (prn out-reg " = " e))
      num (do
            (prn out-reg " = new 'ArcNum'") 
            (prn out-reg " = " e))
      char (do 
             (prn out-reg " = new 'ArcChar'")
             (pr out-reg " = \"")
             (pr-escape (string e))
             (prn  "\""))
      sym (if (alex cs e)
            (prn out-reg " = find_lex '" e "'")
            (prn out-reg " = arc_get_global '" e "'"))
      cons (compile-special-or-call cs e out-reg is-tail))))

(def compile-special-or-call (cs e out-reg is-tail)
  (case (car e)
    $function (compile-function cs e out-reg)
    $closure (compile-closure cs e out-reg)
    if (compile-if cs e out-reg is-tail)
    set (compile-set cs e out-reg)
    apply (compile-call cs (cdr e) out-reg is-tail t)
    ; else
    (compile-call cs e out-reg is-tail nil)))

(def compile-call (cs e out-reg is-tail is-apply)
  ; compile function args
  (each arg e
    (compile-expr cs arg nil))
  (with (args (rev (map [c-pop cs] e)) ; pop args registers
         arcall (if is-apply 
                  "arcall"
                  (case (- (len e) 1) ; don't count function
                    1 "arcall1"
                    2 "arcall2"
                    ; else
                    "arcall")))
    (if is-apply
      (let last (args (- (len args) 1))
        (prn last " = _list_to_array(" last ")")))
    (if is-tail
      (pr ".tailcall " arcall "(")
      (pr out-reg " = " arcall "("))
    (each arg (intersperse ", " args)
      (pr arg))
    (if is-apply
      (prn " :flat)")
      (prn ")"))))

(def compile-const (cs const)
  (let emit-const (afn (e)
                    (if 
                      (aquote e)
                        (self (cadr e))
                      (case (e-type e)
                        sym (prn (c-push cs) " = 'intern'('" e "')")
                        cons (do
                               (self (car e))
                               (self (cdr e))
                               (with (a (c-pop cs) b (c-pop cs))
                                 (prn (c-push cs) " = 'cons'(" b "," a ")")))
                        ; else
                        (compile-expr cs e nil))))
    (emit-const const!expr)
    (prn "set_hll_global '" const!name "', " (c-pop cs))))

(def emit-fn-head (cs name outer)
  (if (iso outer "")
    (prn ".sub " name)
    (prn ".sub " name " :outer('" outer "')")))

; emit a sequence of operations
; if sequence is empty, emit code to return nil
(def compile-seq (cs seq)
  (if (no seq)
    (compile-expr cs nil t)
    ((afn (e)
       (if 
         (no e) nil
         (no (cdr e)) ; last expression
           (compile-expr cs (car e) t)
         (do
           (compile-expr cs (car e) nil)
           (c-pop cs) ; discard ret. value
           (self (cdr e))))) seq)))

; compiles a global function expression
; takes a fn-info object
; ($fn name (arg1 ... . rest-arg) ...)
(def compile-fn (cs f)
  (withs (e f!expr
          name e.1
          args (collect-args e.2)
          body (cdddr e))
    (unless (isa name 'sym)
      (err:string "not a symbol: " name))
    (emit-fn-head cs name f!outer)
    (emit-args args)
    ; emit the body
    (reset-reg cs)
    (let old cs!lex
      (= cs!lex f!lex)
      (compile-seq cs body)
      (= cs!lex old))
    (prn ".return (" (c-pop cs) ")")
    (prn ".end")))

; compile closure creation form
; ($closure code-name)
(def compile-closure (cs expr out-reg)
  (prn out-reg " = get_hll_global '" expr.1 "'")
  (prn out-reg " = newclosure " out-reg))

; compile function creation form
; ($function code-name)
(def compile-function (cs expr out-reg)
  (prn out-reg " = get_hll_global '" expr.1 "'"))

(def label ()
  (uniq))

; if form: (if t1 then1 t2 then2 ... else)
; TODO: give better names to labels
(def compile-if (cs expr out-reg is-tail)
  (let end (label)
    ((afn (expr)
       (if 
         (no expr)
           (prn out-reg " = get_hll_global 'nil'")
         (no (cdr expr))
           (do
             (compile-expr cs (car expr) is-tail)
             (prn out-reg " = " (c-pop cs)))
         ; else len > 1
         (with (else (label)
                test expr.0
                then expr.1)
           (compile-expr cs test nil)
           (prn "unless " (c-pop cs) " goto " else)
           (compile-expr cs then is-tail)
           (prn out-reg " = " (c-pop cs))
           (prn "goto " end)
           (prn else ":")
           (self (cddr expr))))) (cdr expr)) ; cut 'if
     (prn end ":")))

(def compile-set (cs expr out-reg)
  (with (name expr.1
         val expr.2)
    (unless (and (isa name 'sym) (is (len expr) 3))
      (err "wrong 'set form: " expr))
    (compile-expr cs val nil)
    (prn out-reg " = " (c-pop cs))
    (if (alex cs name)
      (prn "store_lex '" name "', " out-reg)
      (prn "set_hll_global '" name "', " out-reg))))

(def aquote (e)
  (and (acons e) (is (car e) 'quote)))

(def a-fn (e)
  (and (acons e) (is (car e) 'fn)))

(def mk-const (name expr)
  (listtab (list (list 'name name) (list 'expr expr))))

(def mk-fn (expr outer lex)
  (listtab (list (list 'expr expr) (list 'outer outer) (list 'lex lex))))

(def arg-names (args)
  ; consider destructuring too
  ; don't count optionals (o ...) 'o symbol and init expression
  (if (isa args 'sym)
    (list args)
    (flat (map [if (is-opt _) (cadr _) _] (makeproper args)))))

(def collect-fns-and-consts (expr lex outer is-seq consts)
  (if
    (isa expr 'sym) 
      (list nil nil expr)
    (or (in (e-type expr) 'int 'num 'char 'string) (aquote expr))
      (if (consts expr)
        (list nil nil (consts expr))
        (let name (uniq)
          (= (consts expr) name)
          (list nil (list (mk-const name expr)) name)))
    (a-fn expr)
      (withs (name (uniq)
              args expr.1
              body (cddr expr)
              new-lex (join (arg-names args) lex))
        (let (fns consts expr) (collect-fns-and-consts body new-lex name t consts)
          (list (cons (mk-fn (cons '$fn (cons name (cons args expr)))
                              outer new-lex)
                      fns)
                consts (list (if (iso outer "") '$function '$closure) name))))
    (let res (map [collect-fns-and-consts _ lex outer nil consts] expr)
      (let res (apply map list res)
        (list (apply join res.0) (apply join res.1) res.2)))))

(def mac-ex (e)
  (if (atom e) 
    e
    (let op (car e)
      (if 
        (is op 'fn)
          (cons 'fn (cons (cadr e) (map mac-ex (cddr e))))
        (is op 'quote)
          e
        (and (isa op 'sym)
             (bound op)
             (isa (eval op) 'mac))
          ; we have a macro
          (let expander (rep (eval op))
            (mac-ex (apply expander (cdr e))))
        ; a list
        (map mac-ex e)))))

; fn args

(def arg-name (a) a!name)
(def arg-p-name (a) a!p-name)
(def arg-type (a) a!type)
(def arg-expr (a) a!expr)

(def mk-arg (name p-name expr type)
  (listtab (list (list 'name name) (list 'p-name p-name)
                 (list 'expr expr) (list 'type type))))

(def mk-darg (name p-name expr)
  (mk-arg name p-name expr 'dest))

(def assign-str (pos gs)
  (string pos "(" gs ")"))

(def des-arg (a gs pos)
  (if 
    (isa a 'sym)
      (list (mk-darg a (uniq) (assign-str pos gs)))
    (acons a)
      (let gs-2 (if (is pos 'top) gs (uniq))
        (join (if (is pos 'top) 
                nil 
                (list (mk-darg nil gs-2 (assign-str pos gs))))
              (des-arg (car a) gs-2 'car)
              (if (cdr a) 
                (des-arg (cdr a) gs-2 'cdr)
                nil)))
    (no a)
      nil
    (err:string "Can't destructure: " a)))

(def pr-param (p-name extra)
  (prn ".param pmc " p-name extra))

(def pr-lex (name p-name)
  (prn ".lex '" name "', " p-name))

; emit code to declare a parameter
(def emit-arg-dec (a)
  (case (arg-type a)
    simple (pr-param (arg-p-name a) "")
    opt (do
          (pr-param (arg-p-name a) " :optional")
          (prn ".param int has_" (arg-p-name a) " :opt_flag"))
    dest (pr-param (arg-p-name a) "")
    rest (pr-param (arg-p-name a) " :slurpy")
   (err:string "Unknown arg type: " a)))

; emit initialization code for arg
(def emit-arg-init (a)
  (case (arg-type a)
    simple (pr-lex (arg-name a) (arg-p-name a))
    opt (with (next (label)
               cs (empty-state))
          (pr-lex (arg-name a) (arg-p-name a))
          (prn "if has_" (arg-p-name a) " goto " next)
          (compile-expr cs (arg-expr a) nil)
          (prn (arg-p-name a) " = " (c-pop cs))
          (prn next ":"))
    dest (each loc (arg-expr a)
           (prn ".local pmc " (arg-p-name loc))
           (if (arg-name loc)
             (pr-lex (arg-name loc) (arg-p-name loc)))
           (prn (arg-p-name loc) " = " (arg-expr loc)))
    rest (do
           (pr-lex (arg-name a) (arg-p-name a))
           (prn (arg-p-name a) " = list(" (arg-p-name a) " :flat)"))
    (err:string "Unknown arg: " a)))

(def is-opt (x)
  (and (acons x) (is (car x) 'o)))

(def collect-args (args)
  (if
    (no args)
      nil
    (and args (no (acons args))) ; rest arg
      (list (mk-arg args (uniq) nil 'rest))
    (isa (car args) 'sym)
      (cons (mk-arg (car args) (uniq) nil 'simple)
            (collect-args (cdr args)))
    (is-opt (car args))
      (let o (car args)
        (cons (mk-arg (cadr o) (uniq) (caddr o) 'opt)
              (collect-args (cdr args))))
    (acons (car args))
      (let p-name (uniq)
        (cons (mk-arg nil p-name (des-arg (car args) p-name 'top) 'dest)
              (collect-args (cdr args))))
    (err:string "Unknow arg type:" args)))

(def emit-args (args)
  (each arg args
    (emit-arg-dec arg))
  (each arg args
    (emit-arg-init arg)))
