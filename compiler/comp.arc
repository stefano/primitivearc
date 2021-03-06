; the compiler
; compile an s-expr into PIR code
; code is emitted on stdout

; from arc.arc (anarki)
(def makeproper (lst)
  (if (no (acons lst))
      lst
      (cons (car lst)
            (if (alist (cdr lst))
              (makeproper (cdr lst))
              (list (cdr lst))))))

(def cdddr (x)
  (cdr (cdr (cdr x))))

(def caddr (x)
  (cadr (cdr x)))

; hold compiler state

(def empty-state () (listtab '((reg 0) (loc nil) (lex nil))))

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

(def find-loc-aux (s args depth)
  (if args
    (if (is (arg-name (car args)) s)
      (car args)
      (if (and (is depth 0) (is (arg-type (car args)) 'dest))
        (or (find-loc-aux s (arg-expr (car args)) 1)
            (find-loc-aux s (cdr args) 0))
        (find-loc-aux s (cdr args) depth)))))

(def find-loc (cs s)
  (find-loc-aux s cs!loc 0))

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
          e (mac-ex e)
          e (a-conv e)
          main-id (uniq)
          (fns consts expr) (collect-fns-and-consts e nil main-id
                                                    t nil consts-tbl)
          cs (empty-state))
    (prn ".HLL 'Arc'")
    (prn ".loadlib 'primitivearc_ops'")
    (prn ".loadlib 'primitivearc_group'")
    ; all the constants
    (prn ".sub _const_init :load :init :anon")
    (each const consts
      (compile-const (empty-state) const))
    (prn ".return ()")
    (prn ".end")
    ; entry function
    (prn ".sub _main :init :load :anon :subid('" main-id "')")
    (compile-expr cs expr nil)
    (prn "set_hll_global '***', " (c-pop cs))
    (prn ".return ()")
    (prn ".end")
    ; all the functions
    (each f fns
      (compile-fn (empty-state) f))))

(let escape-table (listtab '((#\newline "\\n")
                             (#\return "\\r")
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
      sym (let loc (find-loc cs e)
            (if
              loc
                (prn out-reg " = " (arg-p-name loc))
              (alex cs e)
                (prn out-reg " = find_lex '" e "'")
              (prn out-reg " = arc_get_global '" e "'")))
      cons (compile-special-or-call cs e out-reg is-tail))))

(def compile-special-or-call (cs e out-reg is-tail)
  (case (car e)
    $function (compile-function cs e out-reg)
    $closure (compile-closure cs e out-reg)
    if (compile-if cs e out-reg is-tail)
    assign (compile-assign cs e out-reg)
    apply (compile-call cs (cdr e) out-reg is-tail t)
    ; else
    (if (a-let e)
      (compile-let cs e out-reg is-tail)
      (compile-call cs e out-reg is-tail nil))))

(def compile-let (cs e out-reg is-tail)
  (with (args (collect-args ((car e) 1))
         body (cddr (car e))
         vals (cdr e))
    ((afn (args vals)
        (if args
          (do
            (= cs!loc (cons (car args) cs!loc))
            (if (is (arg-type (car args)) 'rest)
              (emit-local-init cs (car args) vals vals)
              (do
                (emit-local-init cs (car args) (car vals) vals)
                (self (cdr args) (cdr vals)))))))
     args vals)
    (with (old-lex cs!lex
           old-loc cs!loc)
      ;(= cs!lex (join (arg-names ((car e) 1)) cs!lex))
      ;(= cs!loc (join args cs!loc))
      (compile-seq cs body is-tail)
      (= cs!loc old-loc)
      (= cs!lex old-lex))
    (prn out-reg " = " (c-pop cs))))

(def compile-call (cs e out-reg is-tail is-apply)
  ; compile function args
  (each arg e
    (compile-expr cs arg nil))
  (with (args (rev (map (fn (ignore) (c-pop cs)) e)) ; pop args registers
         _arcall (if is-apply 
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
      (pr ".tailcall " _arcall "(")
      (pr out-reg " = " _arcall "("))
    (each arg (intersperse ", " args)
      (pr arg))
    (if is-apply
      (prn " :flat)")
      (prn ")"))))

;(def compile-const-ref (cs e out-reg)
;  (let name (uniq)
;    (prn ".const 'Sub' " name " = '" (cadr e) "'")
;    (prn out-reg " = " name)))

(def compile-const (cs const)
  (let emit-const (afn (e)
                    (case (e-type e)
                      sym (prn (c-push cs) " = 'intern'('" e "')")
                      cons (do
                             (self (car e))
                             (self (cdr e))
                             (with (a (c-pop cs) b (c-pop cs))
                               (prn (c-push cs) " = 'cons'(" b "," a ")")))
                      ; else
                      (compile-expr cs e nil)))
    ;(prn ".sub '" const!name "' :subid('" const!name "') :immediate")
    (emit-const const!expr)
    ;(prn ".return (" (c-pop cs) ")")
    ;(prn ".end")))
    (prn "set_hll_global '" const!name "', " (c-pop cs))))

(def emit-fn-head (cs name dbg-name outer)
  ;(pr ".sub '" (or dbg-name name) "' :nsentry('" name "')")
  ;(if dbg-name
  ;  (pr " :subid('" name "')"))
  (pr ".sub '" (or dbg-name name) "'")
  (pr " :subid('" name "')")
  (if (no (iso outer ""))
    (pr " :outer('" outer "')"))
  (prn))

; emit a sequence of operations
; if sequence is empty, emit code to return nil
(def compile-seq (cs seq is-tail)
  (if (no seq)
    (compile-expr cs nil is-tail)
    ((afn (e)
       (if 
         (no e) nil
         (no (cdr e)) ; last expression
           (compile-expr cs (car e) is-tail)
         (do
           (compile-expr cs (car e) nil)
           (c-pop cs) ; discard ret. value
           (self (cdr e))))) seq)))

; compiles a global function expression
; takes a fn-info object
; ($fn name (arg1 ... . rest-arg) ...)
(def compile-fn (cs f)
  ;(ero "compiling: " (or f!dbg-name (cadr f!expr)))
  (withs (e f!expr
          name e.1
          args (collect-args e.2)
          body (cdddr e))
    (unless (isa name 'sym)
      (err:string "not a symbol: " name))
    (emit-fn-head cs name f!dbg-name f!outer)
    (with (old-lex cs!lex
           old-loc cs!loc)
      (= cs!lex f!lex)
      (= cs!loc args)
      ; emit args declaration & initialization
      (emit-args cs args)
      ; emit the body
      (reset-reg cs)
      (compile-seq cs body t)
      (= cs!loc old-loc)
      (= cs!lex old-lex))
    (prn ".return (" (c-pop cs) ")")
    (prn ".end")))

; compile closure creation form
; ($closure code-name)
(def compile-closure (cs expr out-reg)
;  (prn out-reg " = get_hll_global '" expr.1 "'")
;  (prn out-reg " = newclosure " out-reg))
  (let name (uniq)
    (prn ".const 'Sub' " name " = '" expr.1 "'")
    (prn out-reg " = newclosure " name)))

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

(def compile-assign (cs expr out-reg)
  (with (name expr.1
         val expr.2)
    (unless (and (isa name 'sym) (is (len expr) 3))
      (err "wrong 'assign form: " expr))
    (compile-expr cs val nil)
    (prn out-reg " = " (c-pop cs))
    (let loc (find-loc cs name)
      (if
        loc
          (prn (arg-p-name loc) " = " out-reg)
        (alex cs name)
          (prn "store_lex '" name "', " out-reg)
        (prn "set_hll_global '" name "', " out-reg)))))

(def aquote (e)
  (and (acons e) (is (car e) 'quote)))

(def a-fn (e)
  (and (acons e) (is (car e) 'fn)))

(def a-fn-assign (e)
  (and (acons e) (is (car e) 'assign) (a-fn (caddr e))))

(def mk-const (name expr)
  (listtab (list (list 'name name) (list 'expr expr))))

(def mk-fn (expr outer lex dbg-name)
  (listtab (list (list 'expr expr) (list 'outer outer) 
                 (list 'lex lex) (list 'dbg-name dbg-name))))

(def arg-names (args)
  ; consider destructuring too
  ; don't count optionals (o ...) 'o symbol and init expression
  (if (and args (isa args 'sym))
    (list args)
    (flat (map [if (is-opt _) (cadr _) _] (makeproper args)))))

(def a-let (e)
  (and (acons e) (a-fn (car e))))

(def map1-imp (f l)
  (if 
    (no l) nil
    (atom l) (f l)
    (cons (f (car l)) (map1-imp f (cdr l)))))

; alpha-conversion
(def a-conv (e (o transf))
  (if
    (atom e)
      (or (cdr (assoc e transf)) e)
    (aquote e) e
    (a-fn e)
      (withs (args (arg-names (cadr e))
              ;new-args (map [uniq] args)
              ;new-transf (join (map cons args new-args) transf)
              (a-converted-args new-transf) (a-conv-args (cadr e) nil transf));args new-args transf))
        (cons 'fn (cons a-converted-args (map [a-conv _ new-transf] (cddr e)))))
    ; else
    (map1-imp [a-conv _ transf] e)))

(def a-conv-args (args new-args transf)
  (if (no args) (list (rev new-args) transf)
      (acons args) (withs (names (arg-names (list (car args)))
                           new-transf (join (map [cons _ (uniq)] names) transf)
                           converted-arg (if (is-opt (car args)) ; don't convert first o in case (o o ...)
                                           (cons 'o (a-conv (cdr (car args)) new-transf))
                                           (a-conv (car args) new-transf)))
                     (a-conv-args (cdr args) (cons converted-arg new-args) new-transf))
      ; rest arg
      (let new-transf (cons (cons args (uniq)) transf)
        (list (join (rev new-args) (a-conv args new-transf)) new-transf))))

; TODO: doesn't work with destructoring: args may have less elements than
; arg-names, e.g.: ((x y)) vs. (x y)
; treat optional arg (o ...) to avoid converting all o in (o o ...)
; add a new conversion to transf incrementally for each arg
(def a-conv-args-2 (args arg-names new-args transf)
  (let new-transf (cons (cons (car arg-names) (car new-args)) transf)
    (if (acons args)
      (cons (if (is-opt (car args))
              (cons 'o (a-conv (cdr (car args)) new-transf))
              (a-conv (car args) new-transf))
            (a-conv-args (cdr args) (cdr arg-names) (cdr new-args) new-transf))
      (a-conv args new-transf))))

(def collect-fns-and-consts (expr lex outer is-main is-seq consts (o have-name nil))
;  (ero (string "collect: " expr))
  (if
    (in (e-type expr) 'sym 't 'nil) 
      (list nil nil expr)
    (or (in (e-type expr) 'int 'num 'char 'string) (aquote expr))
      (let expr (if (aquote expr) (cadr expr) expr)
        (if (consts expr)
          (list nil nil (consts expr))
          (let name (uniq)
            (= (consts expr) name)
            ;(ero (string "    name: " name " -> " expr))
            ; TODO: optimize simple constants (int, num, char, string)
            (list nil (list (mk-const name expr)) name))))
    (a-fn-assign expr)
      (let (f c e) (collect-fns-and-consts (caddr expr) lex outer is-main
                                           is-seq consts (cadr expr))
        (list f c (list 'assign (cadr expr) e)))
    (a-fn expr)
      (withs (name (uniq)
              args expr.1
              body (cddr expr)
              new-lex (join (arg-names args) lex))
        (let (fns consts expr) (collect-fns-and-consts body new-lex 
                                                       name nil t consts)
          (list (cons (mk-fn (cons '$fn (cons name (cons args expr)))
                              outer lex have-name) ; pass old-lex, args taken from cs!loc
                      fns)
                consts (list (if is-main '$function '$closure) name))))
    (and (no is-seq) (a-let expr))
      (withs (args ((car expr) 1)
              body (cddr (car expr))
              (fval cval vals) (collect-fns-and-consts (cdr expr) lex outer nil
                                                       t consts)
              new-lex (join (arg-names args) lex)
              (fns consts expr) (collect-fns-and-consts body new-lex outer nil
                                                        t consts))
        (list (join fval fns) (join cval consts) 
              (cons (cons 'fn (cons args expr)) vals)))
    (let res (map [collect-fns-and-consts _ lex outer is-main nil consts] expr)
      ;(ero "res: " res)
      (let res (apply map list res)
        ;(ero "  res2: " res)
        (list (apply join res.0) (apply join res.1) res.2)))))

(def mac-ex (e)
  ; expands quasiquotations too
  (if (atom e) 
    e
    (let op (car e)
      (if 
        (is op 'fn)
          (cons 'fn (cons (cadr e) (map mac-ex (cddr e))))
        (is op 'quote)
          e
        ;(is op 'quasiquote)
        ;  (qq-expand (cadr e))
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
  (string "'" pos "'(" gs ")"))

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

(def emit-arg-dest (a)
  (each loc (arg-expr a)
    (prn ".local pmc " (arg-p-name loc))
    (if (arg-name loc)
      (pr-lex (arg-name loc) (arg-p-name loc)))
    (prn (arg-p-name loc) " = " (arg-expr loc))))

; emit initialization code for arg
(def emit-arg-init (cs a)
  (case (arg-type a)
    simple (pr-lex (arg-name a) (arg-p-name a))
    opt (let next (label)
          (pr-lex (arg-name a) (arg-p-name a))
          (prn "if has_" (arg-p-name a) " goto " next)
          (compile-expr cs (arg-expr a) nil)
          (prn (arg-p-name a) " = " (c-pop cs))
          (prn next ":"))
    dest (emit-arg-dest a)
    rest (do
           (pr-lex (arg-name a) (arg-p-name a))
           (prn (arg-p-name a) " = list(" (arg-p-name a) " :flat)"))
    (err:string "Unknown arg: " a)))

(def emit-simple-local (cs arg val)
  (compile-expr cs val nil)
  (prn ".local pmc " (arg-p-name arg))
  (pr-lex (arg-name arg) (arg-p-name arg))
  (prn (arg-p-name arg) " = " (c-pop cs)))

; like emit-arg-init, but for 'let like forms
(def emit-local-init (cs a val has-val)
  (case (arg-type a)
    simple (if has-val
             (emit-simple-local cs a val)
             (err "Wrong number of arg passed"))
    opt (if has-val
          (emit-simple-local cs a val)
          (emit-simple-local cs a (arg-expr a)))
    dest (if has-val
           (do
             (compile-expr cs val nil)
             (prn ".local pmc " (arg-p-name a))
             (prn (arg-p-name a) " = " (c-pop cs))
             (emit-arg-dest a))
           (err "Wrong number of arg passed"))
    rest (if has-val
           (emit-simple-local cs a (cons 'list val))
           (emit-simple-local cs a nil))
    (err "Unknow arg type")))

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

(def emit-args (cs args)
  (each arg args
    (emit-arg-dec arg))
  (let old-loc cs!loc
    (= cs!loc nil)
    (each arg args
      (= cs!loc (cons arg cs!loc))
      (emit-arg-init cs arg))
    (= cs!loc old-loc)))
