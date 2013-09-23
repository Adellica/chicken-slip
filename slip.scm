(module slip (slip-read-char
              slip-write-char
              make-slip-port
              slip-read
              slip-write)

(import chicken scheme)
(use srfi-4   ;; homogeneous lists
     extras   ;; read-string
     ports    ;; make-input-port
     srfi-13) ;; strings

;; Scheme implementation of SLIP (http://tools.ietf.org/html/rfc1055)
;; The reference implementation (in C) was not used because it did not
;; allow signalling a full buffer, neither did it handle EOF. We only
;; need the byte-stream --> packet conversion which is implemented
;; below.
(define END     (integer->char #o300))
(define ESC     (integer->char #o333))
(define ESC_END (integer->char #o334))
(define ESC_ESC (integer->char #o335))

;; return escaped characters. returns #!eof at END-markers or
;; underlying port #!eof.
(define (slip-read-char port)
  (let ((c (read-char port)))
    (cond ((eq? END c) #!eof)
          ((eq? ESC c)
           (let ((c2 (read-char port)))
             (if (or (eq? c2 ESC_END) (eq? c2 ESC_ESC))
                 c2 ;; return escaped char
                 (error (format "invalid escape token #o~o in input" (char->integer c2))))))
          (else c))))

;; returns a new port whose bytes will be escaped, and end with
;; END-mark or end of underlying port.
(define (make-slip-port port)
  (make-input-port
   ;;read-char
   (let ((dead? #f))
     (lambda ()
       (if dead? #!eof
           (let ((c (slip-read-char port)))
             (if (eof-object? c) (set! dead? #t))
             c))))
   ;;ready?
   (lambda () (char-ready? port))
   ;;close
   (lambda () (close-input-port port))))

;; read a slip-packet from port until #!eof or end-of-packet mark,
;; escaping input.
;;
;; obs! does not return #!eof, watch for empty strings instead.
(define (slip-read #!optional (port (current-input-port)))
  (read-string #f (make-slip-port port)))

(define (slip-write-char char #!optional (port (current-output-port)))
  (define (w char) (write-char char port))
  (cond ((eq? END char) (w ESC) (w ESC_END))
        ((eq? ESC char) (w ESC) (w ESC_ESC))
        (else (w char))))

(define (slip-write string #!optional (port (current-output-port)))
  (string-for-each (lambda (c) (slip-write-char c port)) string)
  (write-char END port))

)
