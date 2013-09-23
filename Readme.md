# Chicken-SLIP

  [SLIP]:http://en.wikipedia.org/wiki/Serial_Line_Internet_Protocol

This is a CHICKEN-implementatino of [SLIP]. [SLIP] is designed to allow concatenating packets
into a stream while maintaing their message boundaries.

You can make ports which `#!eof` at end of packet-mark (`"\300"`)

```scheme
(read-string #f (make-slip-port (open-input-string "A\300B"))) => "A"
```

To read multiple packets, you must make multiple slip-ports. Or read a packet as a string directly:

```scheme
(slip-read (open-input-string "A\300B")) => "A"
```

You write packets like this:

```scheme
(with-output-to-string (lambda () (slip-write "A\300B"))) => "A\333\334B\300"
```

As shown, this escapes characters and appends the end of packet mark (`"\300"`).

This egg has not been benchmarked but is probably very slow.
