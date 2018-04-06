#lang racket/base

(require
  racket/contract/base
  net/url)

(define alist? (listof (cons/c symbol? any/c)))

(provide/contract
  [url-append (url? string? . -> . url?)]
  [format-headers (alist? . -> . (listof string?))]
  [format-params (alist? . -> . string?)])

(define (url-append base-url url-string)
  (define current-path (url-path base-url))
  (define additional-url (string->url url-string))
  (define additional-path (url-path additional-url))
  (define new-path (append current-path additional-path))
  (struct-copy url base-url [path new-path]
                            [query (url-query additional-url)]
                            [fragment (url-fragment additional-url)]))

(define (format-headers headers)
  (map (lambda (header)
         (format "~a: ~a" (car header) (cdr header)))
       headers))

(define (format-params params)
  (local-require net/uri-codec)
  (string-append "?" (alist->form-urlencoded params)))
