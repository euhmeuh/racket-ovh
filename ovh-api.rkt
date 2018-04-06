#!/usr/bin/env racket
#lang racket/base

(require
  racket/cmdline
  "api.rkt")

(define current-params (make-parameter (make-hasheq)))
(command-line
  #:once-any
  [("-R" "--refresh-consumer") "Ask for a new consumer key"
                               (begin (displayln (get-consumer-key))
                                      (exit))]
  #:once-any
  ["--v7" "Use APIv7" (current-api-version 'v7)]
  ["--v6" "Use APIv6" (current-api-version 'v6)]
  #:once-any
  [("-e" "--expand") "Expand results (only with APIv7)"
                     (current-expand-mode #t)]
  #:multi
  [("-a" "--arg") key value
                  "Optional query argument"
                  (hash-set! (current-params) (string->symbol key) value)]
  #:args (method url)
  (displayln
    (apply ovh-api-query (append (list (string->symbol (string-upcase method)) url)
                                 (hash->list (current-params))))))
