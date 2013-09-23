# Chicken-SLIP

  [SLIP]:http://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol

This is a CHICKEN-implementatino of [SLIP].

You can make ports which `#!eof` at end of packet-mark (`"\300"`)

```scheme
(read-string #f (make-slip-port (open-input-string "A\300B"))) => "A"
```

Or read a packet-string directly:
```scheme
(slip-read (open-input-string "A\300B")) => "A"
```

You write packets like this:

```scheme
(with-output-to-string (lambda () (slip-write "A\300B"))) => "A\333\334B\300"
```
