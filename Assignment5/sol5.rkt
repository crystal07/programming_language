#lang racket
(provide (all-defined-out)) ;; exports the defined variables in this file.

;; definition of structures for MUPL programs - Do NOT change
(struct var  (string) #:transparent)  ;; a variable, e.g., (var "foo")
(struct int  (num)    #:transparent)  ;; a constant number, e.g., (int 17)
(struct add  (e1 e2)  #:transparent)  ;; add two expressions
(struct ifgreater (e1 e2 e3 e4)    #:transparent) ;; if e1 > e2 then e3 else e4
(struct fun  (nameopt formal body) #:transparent) ;; a recursive(?) 1-argument function
(struct call (funexp actual)       #:transparent) ;; function call
(struct mlet (var e body) #:transparent) ;; a local binding (let var = e in body) 
(struct apair (e1 e2)     #:transparent) ;; make a new pair
(struct fst  (e)    #:transparent) ;; get first part of a pair
(struct snd  (e)    #:transparent) ;; get second part of a pair
(struct aunit ()    #:transparent) ;; unit value -- good for ending a list
(struct isaunit (e) #:transparent) ;; evaluate to 1 if e is unit else 0

;; a closure is not in "source" programs; it is what functions evaluate to
(struct closure (env fun) #:transparent) 

;; Problem 1

;; CHANGE (put your solutions here)
(define (racketlist->mupllist rlist)
  (cond
    [(null? rlist) (aunit)]
    [#t (apair (car rlist) (racketlist->mupllist (cdr rlist)))]
  )
)

(define (mupllist->racketlist mlist)
  (cond
    [(aunit? mlist) '()]
    [#t (cons (apair-e1 mlist) (mupllist->racketlist (apair-e2 mlist)))]
  )
)

;; Problem 2

;; lookup a variable in an environment
;; Do NOT change this function
(define (envlookup env str)
  (cond [(null? env) (error "unbound variable during evaluation" str)]
        [(equal? (car (car env)) str) (cdr (car env))]
        [#t (envlookup (cdr env) str)]))

;; Do NOT change the two cases given to you.  
;; DO add more cases for other kinds of MUPL expressions.
;; We will test eval-under-env by calling it directly even though
;; "in real life" it would be a helper function of eval-exp.
(define (eval-under-env e env)
  (cond [(var? e) 
         (envlookup env (var-string e))]
        [(add? e) 
         (let ([v1 (eval-under-env (add-e1 e) env)]
               [v2 (eval-under-env (add-e2 e) env)])
           (if (and (int? v1)
                    (int? v2))
               (int (+ (int-num v1) 
                       (int-num v2)))
               (error "MUPL addition applied to non-number")))]
        ;; CHANGE add more cases here
        [(int? e) e]
        [(aunit? e) e]
        [(fun? e) (closure env e)]
        [(ifgreater? e)
         (let ([v1 (eval-under-env (ifgreater-e1 e) env)]
               [v2 (eval-under-env (ifgreater-e2 e) env)])
           (if (and (int? v1) (int? v2))
             (if (> (int-num v1) (int-num v2))
             (eval-under-env (ifgreater-e3 e) env)
             (eval-under-env (ifgreater-e4 e) env)) (error "bad expression: not int"))
         )]
        [(mlet? e)
         (let ([v1 (eval-under-env (mlet-e e) env)])
         (eval-under-env (mlet-body e) (cons (cons (mlet-var e) v1) env)))]
        [(call? e)
         (let ([c (eval-under-env (call-funexp e) env)])
         (if (closure? c)
             (let* ([fn (closure-fun c)]
                     [v (eval-under-env (call-actual e) env)]
                     [env (cons (cons (fun-formal fn) v) (closure-env c))]
                     [env2 (cons (cons (fun-nameopt fn) c) env)])
                (if (fun-nameopt fn) (eval-under-env (fun-body fn) env2) (eval-under-env (fun-body fn) env)))
             (error (format ("bad expression: funexp not closure")))
           ))]
        [(apair? e) (apair (eval-under-env (apair-e1 e) env) (eval-under-env (apair-e2 e) env))]
        [(fst? e)
         (let ([v1 (eval-under-env (fst-e e) env)])
         (if (apair? v1) (apair-e1 v1) (error (format ("bad expression: fst expression not pair")))))]
        [(snd? e)
         (let ([v2 (eval-under-env (snd-e e) env)])
         (if (apair? v2) (apair-e2 v2) (error (format "bad expression: snd expression not pair"))))]
        [(closure? e) e]
        [(isaunit? e)
         (let ([v1 (eval-under-env (isaunit-e e) env)])
         (if (aunit? v1) (int 1) (int 0)))]
        [#t (error (format "bad MUPL expression: ~v" e))]))

;; Do NOT change
(define (eval-exp e)
  (eval-under-env e null))
        
;; Problem 3

(define (ifaunit e1 e2 e3)
  (ifgreater (isaunit e1) (int 0) e2 e3)
  )

(define (mlet* lstlst e2)
  (if (null? lstlst)
      e2
      (mlet (car (car lstlst)) (cdr (car lstlst)) (mlet* (cdr lstlst) e2))))

(define (ifeq e1 e2 e3 e4)
  (mlet* (list (cons "_x" e1) (cons "_y" e2))
         (ifgreater (var "_x") (var "_y") e4
                    (ifgreater (var "_y") (var "_x") e4 e3))))

;; Problem 4

(define mupl-map
  (fun "fname" "fn" (fun "iter" "lst" (ifaunit(var "lst")
                                      (aunit)
                                      (apair (call (var "fn") (fst (var "lst"))) (call (var "iter") (snd (var "lst"))))))))

(define mupl-mapAddN 
  (mlet "map" mupl-map
        (fun #f "ad" (call (var "map") (fun #f "x" (add (var "x") (var "ad")))))))


(struct fun-challenge (nameopt formal body freevars) #:transparent) ;; a recursive(?) 1-argument function

;; We will test this function directly, so it must do
;; as described in the assignment
(define (compute-free-vars e) "CHANGE")

;; Do NOT share code with eval-under-env because that will make grading
;; more difficult, so copy most of your interpreter here and make minor changes
(define (eval-under-env-c e env) "CHANGE")

;; Do NOT change this
(define (eval-exp-c e)
  (eval-under-env-c (compute-free-vars e) null))