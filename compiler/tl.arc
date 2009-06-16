; command line compilation

(load "compiler/comp.arc")

(tl-compile `((fn () ,@(readall (stdin)))))
