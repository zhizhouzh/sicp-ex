(define (tagged-list? exp tag)
  (if (pair? exp)
    (eq? (car exp) tag)
    false))

(define (self-evaluating? exp)
  (cond ((number? exp) true)
        ((string? exp) true)
        (else false)))

(define (variable? exp) (symbol? exp))

(define (quoted? exp) (tagged-list? exp 'quote))
(define (text-of-quotation exp) (cadr exp))

(define (assignment? exp) (tagged-list? exp 'set!))
(define (assignment-variable exp) (cadr exp))
(define (assignment-value exp) (caddr exp))
(define (eval-assignment exp env)
  (set-variable-value! (assignment-variable exp)
                       (eval (assignment-value exp) env)
                       env)
  'ok)

(define (definition? exp) (tagged-list? exp 'define))
(define (definition-variable exp)
  (if (symbol? (cadr exp))
    (cadr exp)
    (caadr exp)))
(define (definition-value exp)
  (if (symbol? (cadr exp))
    (caddr exp)
    (make-lambda (cdadr exp)   ; formal parameters
                 (cddr exp)))) ; body
(define (eval-definition exp env)
  (define-variable! (definition-variable exp)
                    (eval (definition-value exp) env)
                    env)
  'ok)

(define (lambda? exp) (tagged-list? exp 'lambda))
(define (lambda-parameters exp) (cadr exp))
(define (lambda-body exp) (cddr exp))
(define (make-lambda parameters body) (cons 'lambda (cons parameters body)))

(define (if? exp) (tagged-list? exp 'if))
(define (if-predicate exp) (cadr exp))
(define (if-consequent exp) (caddr exp))
(define (if-alternative exp)
  (if (not (null? (cdddr exp)))
    (cadddr exp)
    'false))
(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))
(define (eval-if exp env)
  (if (true? (eval (if-predicate exp) env))
    (eval (if-consequent exp) env)
    (eval (if-alternative exp) env)))

(define (begin? exp) (tagged-list? exp 'begin))
(define (begin-actions exp) (cdr exp))
(define (last-exp? seq) (null? (cdr seq)))
(define (first-exp seq) (car seq))
(define (rest-exps seq) (cdr seq))
(define (sequence->exp seq)
  (cond ((null? seq) seq)
        ((last-exp? seq) (first-exp seq))
        (else (make-begin seq))))
(define (make-begin seq) (cons 'begin seq))
(define (eval-sequence exps env)
  (cond ((last-exp? exps) (eval (first-exp exps) env))
        (else (eval (first-exp exps) env)
              (eval-sequence (rest-exps exps) env))))

(define (application? exp) (pair? exp))
(define (operator exp) (car exp))
(define (operands exp) (cdr exp))
(define (no-operands? ops) (null? ops))
(define (first-operand ops) (car ops))
(define (rest-operands ops) (cdr ops))
(define (list-of-values exps env)
  (if (no-operands? exps)
    '()
    (cons (eval (first-operand exps) env)
          (list-of-values (rest-operands exps) env))))

(define (cond? exp) (tagged-list? exp 'cond))
(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause) (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) (car clause))
(define (cond-actions clause) (cdr clause))
(define (cond->if exp) (expand-clauses (cond-clauses exp)))
(define (expand-clauses clauses)
  (if (null? clauses)
    'false                          ; no else clause
    (let ((first (car clauses))
          (rest (cdr clauses)))
      (if (cond-else-clause? first)
        (if (null? rest)
          (sequence->exp (cond-actions first))
          (error "ELSE clause isn't last -- COND->IF"
                 clauses))
        (make-if (cond-predicate first)
                 (sequence->exp (cond-actions first))
                 (expand-clauses rest))))))

(define apply-in-underlying-scheme apply)

(define (print-procedure object)
  (if (compound-procedure? object)
    (list 'compound-procedure
          (procedure-parameters object)
          (procedure-body object)
          '<procedure-env>)
    object))


(define (apply procedure arguments)
  ; (newline)
  ; (write-line (list "APPLY" (print-procedure procedure) arguments))
  (cond ((primitive-procedure? procedure)
         (apply-primitive-procedure procedure arguments))
        ((compound-procedure? procedure)
         (eval-sequence
           (procedure-body procedure)
           (extend-environment
             (procedure-parameters procedure)
             arguments
             (procedure-environment procedure))))
        (else
          (error
            "Unknown procedure type -- APPLY" procedure))))

; Naive table put/get
(define table '())
(define (get . args)
  (let ((target-list (find (lambda (entry) (equal? args (sublist entry 0 (length args)))) table)))
    (if target-list
      (list-ref target-list (length args))
      #f)))
(define (put . args) (set! table (cons args table)))
;

(define (install-eval-mutiple)
  (put 'eval 'quote (lambda (exp env) (text-of-quotation exp)))
  (put 'eval 'set! eval-assignment)
  (put 'eval 'define eval-definition)
  (put 'eval 'if eval-if)
  (put 'eval 'lambda (lambda (exp env) (make-procedure (lambda-parameters exp)
                                                       (lambda-body exp)
                                                       env)))
  (put 'eval 'begin (lambda (exp env) (eval-sequence (begin-actions exp) env)))
  (put 'eval 'cond (lambda (exp env) (eval (cond->if exp) env)))
  'done)

(install-eval-mutiple)


(define (eval exp env)
  ; (newline)
  ; (write-line (list "EVAL" exp))
  ; (write-line env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((get 'eval (operator exp)) ((get 'eval (operator exp)) exp env))
        ((pair? exp) (apply (eval (operator exp) env)
                            (list-of-values (operands exp) env)))
        (else
          (error "Unknown expression type -- EVAL" exp))))

(define (true? x) (not (eq? x false)))
(define (false? x) (eq? x false))


(define (make-procedure parameters body env)
  (list 'procedure parameters body env))
(define (compound-procedure? p)
  (tagged-list? p 'procedure))
(define (procedure-parameters p) (cadr p))
(define (procedure-body p) (caddr p))
(define (procedure-environment p) (cadddr p))

(define (enclosing-environment env) (cdr env))
(define (first-frame env) (car env))
(define the-empty-environment '())

(define (make-frame variables values)
  (cons variables values))
(define (frame-variables frame) (car frame))
(define (frame-values frame) (cdr frame))
(define (add-binding-to-frame! var val frame)
  (set-car! frame (cons var (car frame)))
  (set-cdr! frame (cons val (cdr frame))))

(define (extend-environment vars vals base-env)
  (if (= (length vars) (length vals))
    (cons (make-frame vars vals) base-env)
    (if (< (length vars) (length vals))
      (error "Too many arguments supplied" vars vals)
      (error "Too few arguments supplied" vars vals))))

(define (lookup-variable-value var env)
  (define (env-loop env)
    (define (scan vars vals)
      (cond ((null? vars)
             (env-loop (enclosing-environment env)))
            ((eq? var (car vars))
             (car vals))
            (else (scan (cdr vars) (cdr vals)))))
    (if (eq? env the-empty-environment)
      (error "Unbound variable" var)
      (let ((frame (first-frame env)))
        (scan (frame-variables frame)
              (frame-values frame)))))
  (env-loop env))

(define (set-variable-value! var val env)
  (define (env-loop env)
    (define (scan vars vals)
      (cond ((null? vars)
             (env-loop (enclosing-environment env)))
            ((eq? var (car vars))
             (set-car! vals val))
            (else (scan (cdr vars) (cdr vals)))))
    (if (eq? env the-empty-environment)
      (error "Unbound variable -- SET!" var)
      (let ((frame (first-frame env)))
        (scan (frame-variables frame)
              (frame-values frame)))))
  (env-loop env))

(define (define-variable! var val env)
  (let ((frame (first-frame env)))
    (define (scan vars vals)
      (cond ((null? vars)
             (add-binding-to-frame! var val frame))
            ((eq? var (car vars))
             (set-car! vals val))
            (else (scan (cdr vars) (cdr vals)))))
    (scan (frame-variables frame)
          (frame-values frame))))

(define primitive-procedures
  (list (list 'car car)
        (list 'cdr cdr)
        (list 'cons cons)
        (list 'null? null?)
        (list '* *)
        (list '+ +)
        (list '- -)
        (list '= =)
        (list 'map map)
        (list 'write-line (lambda (x) (newline) (write-line x)))
        ))

(define (primitive-procedure-names)
  (map car primitive-procedures))

(define (primitive-procedure-objects)
  (map (lambda (proc) (list 'primitive (cadr proc)))
       primitive-procedures))

(define (setup-environment)
  (let ((initial-env
          (extend-environment (primitive-procedure-names)
                              (primitive-procedure-objects)
                              the-empty-environment)))
    (define-variable! 'true true initial-env)
    (define-variable! 'false false initial-env)
    (define-variable! '*unassigned* '*unassigned* initial-env)
    initial-env))
(define the-global-environment (setup-environment))

(define (primitive-procedure? proc)
  (tagged-list? proc 'primitive))

(define (primitive-implementation proc) (cadr proc))
(define (apply-primitive-procedure proc args)
  (apply-in-underlying-scheme (primitive-implementation proc) args))

; let from ex4.6
(define (let->combination exp)
  (let ((binding-list (cadr exp))
        (body (cddr exp)))
    (cons
      (make-lambda (map car binding-list) body)
      (map cadr binding-list))))

(define (install-let)
  (put 'eval 'let (lambda (exp env) (eval (let->combination exp) env)))
  'done)
(install-let)

; scan-out-defines from ex4.16
(define (transform-internal-definitions body)
  (let ((define-exp-list (filter definition? body)))
    (if (null? define-exp-list)
      body
      (let ((define-vars (map definition-variable define-exp-list))
            (define-vals (map definition-value define-exp-list))
            (rest-exp-list (filter (lambda (exp) (not (definition? exp))) body)))

        (list
          (cons 'let
                (cons (map (lambda (var) (list var '*unassigned*)) define-vars)
                      (append
                        (map (lambda (var val) (list 'set! var val)) define-vars define-vals)
                        rest-exp-list))))))))

(define (make-procedure parameters body env)
  (list 'procedure parameters (transform-internal-definitions body) env))


; a 
(define (letrec->let exp)
  (let ((var-val-list (cadr exp))
        (body-in-list (cddr exp)))
    (let ((vars (map car var-val-list))
          (vals (map cadr var-val-list)))
      (cons 'let
            (cons (map (lambda (var) (list var '*unassigned*)) vars)
                  (append
                    (map (lambda (var val) (list 'set! var val)) vars vals)
                    body-in-list))))))

(letrec->let '(letrec ((fact
                         (lambda (n)
                           (if (= n 1)
                             1
                             (* n (fact (- n 1)))))))
                (fact 10)))
(let->combination
  (letrec->let '(letrec ((fact
                           (lambda (n)
                             (if (= n 1)
                               1
                               (* n (fact (- n 1)))))))
                  (fact 10))))


(define (install-letrec)
  (put 'eval 'letrec (lambda (exp env) (eval (letrec->let exp) env)))
  'done)
(install-letrec)


(eval '(letrec ((fact
                  (lambda (n)
                    (if (= n 1)
                      1
                      (* n (fact (- n 1)))))))
         (fact 10))
      the-global-environment)

; b.


; Simply replace letrec into let won't work because for let
; the procedures of even? odd? and fact are bound to global env or the topmost env
; which inherited by a new env in which let converted lambda being executed and even?, odd? and fact bound to
; But the execution of those procedures inherit from global or top most env directly
; So even?, odd? or fact cannot be found

; Env diagram for 
; (let ((fact
;         (lambda (n)
;           (if (= n 1)
;             1
;             (* n (fact (- n 1)))))))
;   (fact 10))
; 
; Same as
; (
;  (lambda (fact) (fact 10)) 
;  (lambda (n) 
;    (if (= n 1) 1 (* n (fact (- n 1)))))
;  )

; _____________________________________________________________________________
;
; global env:
;
;          To eval
;           (
;            (lambda (fact) (fact 10)) 
;            (lambda (n) 
;             (if (= n 1) 1 (* n (fact (- n 1)))))
;           )
;         
;           eval (lambda (fact) (fact 10)) 
;                => '(procedure <...>)
;           eval (lambda (n) (if <...>))
;                => '(procedure <...>)
;
;           apply ...
; _____________________________________________________________________________
;                       ^                   ^
;                       |                   |
;                       |             ______|__________________________________________________________________
;                       |         
;                       |              E1: fact = procedure of (lambda (n) (if (= n 1) 1 (* n (fact (- n 1)))))
;                       |
;                       |                  To eval (fact 10)
;                       |
;                       |                  eval fact 
;                       |                       => procedure of (lambda (n) (if <...>))
;                       |
;                       |                  eval 10 
;                       |                       => 10
;                       |
;                       |                  apply ...
;                       |             _________________________________________________________________________
;                       |
;                       |
;                 ______|________________________________________
;             
;                  E2: n = 10
;
;                      To eval (if (= n 1) 1 (* n (fact (- n 1))))
;
;                      eval ....
;                      eval ....
;                      eval (fact (- n 1))  => fact not found
;                 ________________________________________________
;
;

; Env diagram for 
; (letrec ((fact
;            (lambda (n)
;              (if (= n 1)
;                1
;                (* n (fact (- n 1)))))))
;   (fact 10))
;
; Same as
; (
;  (lambda (fact) 
;    (set! fact (lambda (n) (if (= n 1) 1 (* n (fact (- n 1))))))
;    (fact 10))
;  *unassigned*)

; _____________________________________________________________________________
;
; global env:
;
;          To eval
;           (
;            (lambda (fact) 
;              (set! fact (lambda (n) (if (= n 1) 1 (* n (fact (- n 1))))))
;              (fact 10))
;            *unassigned*)
;           
;         
;           eval (lambda (fact) (set! fact (lambda <...>) <...>))
;                => '(procedure <...>)
;           eval '*unassigned*
;                => '*unassigned*
;
;           apply ...
; _____________________________________________________________________________
;                                   ^
;                                   |
;                                   |
;                                   |
;        ___________________________|_____________________________________________
;    
;         E1: fact = '*unassigned*
;             fact = procedure of (lambda (n) (if (= n 1) 1 (* n (fact (- n 1))))))
;   
;             To eval (set! fact (lambda (n) <...>))
;                and (fact 10)
;
;             eval (lambda (n) (if (= n 1) <...>))
;                => '(procedure <..>)
;   
;             eval fact 
;                  => procedure of (lambda (n) (if <...>))
;   
;             eval 10 
;                  => 10
;   
;             apply ...
;        _________________________________________________________________________
;                                      ^
;                                      |
;                                      |
;                                      |
;                 _____________________|_________________________
;             
;                  E2: n = 10
;
;                      To eval (if (= n 1) 1 (* n (fact (- n 1))))
;
;                      eval ....
;                      eval ....
;                      eval (fact (- n 1))  => fact can be found
;                 ________________________________________________
;
;
