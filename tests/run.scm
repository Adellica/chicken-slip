(use test slip srfi-1)

(define ois open-input-string)

(test "end" '#\a                      (slip-read-char (ois "a")))
(test "eof" #!eof                     (slip-read-char (ois "")))
(test "esc end" (integer->char #o334) (slip-read-char (ois "\333\334")))
(test "esc esc" (integer->char #o335) (slip-read-char (ois "\333\335")))
(test-error "esc error"               (slip-read-char (ois "\333\336")))

(test "no end-of-packet, but eof" "a" (slip-read (ois "a")))

(test "a" (read-string #f (make-slip-port (ois "a\300b"))))
(test "a\334" (read-string #f (make-slip-port (ois "a\333\334\300b"))))


;; the empty packet "" could also be allowed here
;; the first \300 is an empty packet, but nobody wants it
(test "drop empty packet" "" (slip-read (ois "\300a\300")))

(test-group
 "subsequent packets"
 (define p (ois "a\300b\300"))
 (test "packet 1 from stream" "a" (slip-read p))
 (test "packet 2 from stream" "b" (slip-read p))
 (test "no packets left" "" (slip-read p)))

(test-group
 "slip-port doesn't overflow into next packet"
 (define p (ois "a\300b"))
 (define p1 (make-slip-port p))
 (define p2 (make-slip-port p))
 (test "packet 1 read" "a" (read-string #f p1))
 (test "packet 1 doesn't run into b" "" (read-string #f p1))
 (test "packet 2 still intact" "b" (read-string #f p2))
 (test "packet 2 now also gone" "" (read-string #f p2)))

(test-group
 "slip-write"
 (define (sw str) (with-output-to-string (lambda () (slip-write str))))

 (test "wrap in END"          "A\300"          (sw "A"))
 (test "escape end"           "\333\334\300"   (sw "\300"))
 (test "escane esc"           "\333\335\300"   (sw "\333"))
 (test "empty packet"           "\300"   (sw ""))

 (test "bigger string " "ABCD\300" (sw "ABCD"))

 (test "uses explicit port argument"
       "A\333\334B\333\335C\300"
       (let ((p (open-output-string)))
         (slip-write "A\300B\333C" p)
         (get-output-string p)))

 (test-begin "byterange unchange (except END and ESC)")
 (for-each (lambda (char)
             (test (conc "slip-write char "(char->integer char)) ;; <- description
                   (conc char "\300") ;; <-- expected
                   (sw (conc char))))        ;; <-- actual
           (remove (lambda (x) (or (eq? (integer->char #o300) x)
                              (eq? (integer->char #o333) x)))
                   (map integer->char (iota 256))))
 (test-end))

(test-exit)
