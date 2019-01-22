
(define (equal? l1 l2)
  (print l1)
  (print l2)
  (print "")
  (cond ((and (null? l1) (null? l2)) #t)
	((or (null? l1) (null? l2)) #f)
	(else (let ((l1-car (car l1))
		    (l1-cdr (cdr l1))
		    (l2-car (car l2))
		    (l2-cdr (cdr l2)))
		(cond ((and (pair? l1-car) (pair? l2-car))
		       (if (equal? l1-car l2-car) (equal? l1-cdr l2-cdr) #f))
		      ((and (not (pair? l1-car)) (not (pair? l2-car))) 
		       (if (eq? l1-car l2-car) (equal? l1-cdr l2-cdr) #f))
		      (else #f))))))

; ; (equal? '(this is a list) '(this is a list))
; (equal? '(this is (a) list) '(this is a list))
; ; (equal? '(this is a list) '(this (is a) list))

; (equal? '(1 2 3 (4 5) 6) '(1 2 3 (4 5 7) 6)) 


; simplify towards nonofficial solution:
; -> 
(define (equal? l1 l2)
  (print l1)
  (print l2)
  (print "")
  (cond ((and (null? l1) (null? l2)) #t)
	((or (null? l1) (null? l2)) #f)
	((and (not (pair? list1)) (not (pair? list2))) 
	 (eq? list1 list2))
	(else (let ((l1-car (car l1))
		    (l1-cdr (cdr l1))
		    (l2-car (car l2))
		    (l2-cdr (cdr l2)))
		(cond ((and (pair? l1-car) (pair? l2-car))
		       (if (equal? l1-car l2-car) (equal? l1-cdr l2-cdr) #f))
		      ((and (not (pair? l1-car)) (not (pair? l2-car))) 
		       (if (equal? l1-car l2-car) (equal? l1-cdr l2-cdr) #f))
		      (else #f))))))

; -> 
(define (equal? l1 l2)
  (print l1)
  (print l2)
  (print "")
  (cond ((and (null? l1) (null? l2)) #t)
	((or (null? l1) (null? l2)) #f)
	((and (not (pair? list1)) (not (pair? list2))) 
	 (eq? list1 list2))
	((and (pair? list1) (pair? list2))
	 (if (equal? (car l1) (car l2)) (equal? (cdr l1) (cdr l2)) #f))
	(else #f)
	))

; -> 
(define (equal? l1 l2)
  (print l1)
  (print l2)
  (print "")
  (cond ((and (null? l1) (null? l2)) #t)
	((or (null? l1) (null? l2)) #f)
	((and (not (pair? list1)) (not (pair? list2))) 
	 (eq? list1 list2))
	((and (pair? list1) (pair? list2))
	 (and (equal? (car l1) (car l2)) (equal? (cdr l1) (cdr l2))))
	(else #f)
	))

; since (pair? '())
; => #f
; (eq? '() '())
; => true
(define (equal? l1 l2)
  (print l1)
  (print l2)
  (print "")
  (cond ((and (not (pair? list1)) (not (pair? list2))) 
	 (eq? list1 list2))
	((and (pair? list1) (pair? list2))
	 (and (equal? (car l1) (car l2)) (equal? (cdr l1) (cdr l2))))
	(else #f)
	))


(define (equal? list1 list2) 
  (print "")
  (print list1)
  (print list2)
  (cond ((and (not (pair? list1)) (not (pair? list2))) 
	 (eq? list1 list2)) 
	((and (pair? list1) (pair? list2)) 
	 (and (equal? (car list1) (car list2)) (equal? (cdr list1) (cdr list2)))) 
	(else #f))) 

;  (equal? '(1 2 3 (4 5) 6) '(1 2 3 (4 5) 6)) 
(equal? '(1) '(1 2))


