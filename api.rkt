#lang racket/base

(require
  racket/contract/base)

(define verb? (symbols 'GET 'POST 'PUT 'DELETE))
(define alist? (listof (cons/c symbol? any/c)))

(provide/contract
  [current-api-version (parameter/c (symbols 'v6 'v7))]
  [current-expand-mode (parameter/c boolean?)]
  [get-consumer-key (-> string?)]
  [ovh-api-query (->* (verb? string?) (#:headers alist?
                                       #:data (or/c string? #f))
                      #:rest alist?
                      string?)])

(require
  racket/match
  racket/string
  racket/port
  racket/format
  srfi/26
  net/url
  file/sha1
  json
  "url.rkt")

(define current-app-key (make-parameter (or (getenv "OVH_APP_KEY") "")))
(define current-secret-key (make-parameter (or (getenv "OVH_SECRET_KEY") "")))
(define current-consumer-key (make-parameter (or (getenv "OVH_CONSUMER_KEY") "")))
(define current-api-version (make-parameter 'v6))
(define current-expand-mode (make-parameter #f))

(define base-url (string->url "https://eu.api.ovh.com/1.0"))
(define credential-url (url-append base-url "/auth/credential"))
(define timestamp-url (url-append base-url "/auth/time"))

(define (base-headers)
  (define headers
    '([Accept . "application/json"]
      [User-Agent . "Racket OVH Console"]))
  (when (eq? (current-api-version) 'v7)
    (set! headers (append headers '([X-Ovh-ApiVersion . "beta"]))))
  (when (current-expand-mode)
    (set! headers (append headers '([X-Ovh-ApiV7-Expand . 1]))))
  headers)

(define (get-consumer-key)
  (define payload (jsexpr->bytes
                    #hasheq([accessRules . #hasheq([method . "GET"]
                                                   [path . "/*"])]
                            [redirection . "https://api.ovh.com/console/"])))
  (call/input-url
    credential-url
    (cut post-pure-port <> payload <>)
    (lambda (in)
      (let* ([response (port->string in)]
             [result (hash-ref (string->jsexpr response) 'consumerKey #f)])
        (or result response)))
    (format-headers (append `([X-Ovh-Application . ,(current-app-key)])
                            (base-headers)))))

(define (call/get-string url [headers '()])
  (call/input-url url get-pure-port
    (lambda (in) (port->string in))
    (format-headers headers)))

(define (make-signature method query body timestamp)
  (string-append
    "$1$"
    (sha1
      (open-input-string
        (string-join
          (map ~a (list (current-secret-key)
                        (current-consumer-key)
                        method query body timestamp))
          "+")))))

(define get-timestamp #f)
(define (make-timestamp-retriever)
  (define server-time (string->number (call/get-string timestamp-url)))
  (let ([time-delta (- server-time (current-seconds))])
    (lambda ()
      (+ (current-seconds) time-delta))))

(define (authenticate method query body headers)
  (define timestamp (get-timestamp))
  (append headers
          `([X-Ovh-Application . ,(current-app-key)]
            [X-Ovh-Consumer . ,(current-consumer-key)]
            [X-Ovh-Signature . ,(make-signature method query body timestamp)]
            [X-Ovh-Timestamp . ,timestamp])))

(define (build-api-url url-string params)
  (when (pair? params)
    (set! url-string (string-append url-string (format-params params))))
  (url-append base-url url-string))

(define (pretty-headers headers)
  (string-join (format-headers headers) "\n"))

(define (ovh-api-get url headers)
  (displayln (format "GET ~a~%~a~%" (url->string url) (pretty-headers headers)))
  (call/get-string url headers))

(define (ovh-api-post url headers data)
  'todo)

(define (ovh-api-put url headers data)
  'todo)

(define (ovh-api-delete url headers)
  'todo)

(define (ovh-api-query verb url-string #:headers [headers '()]
                                       #:data [data #f]
                                       . params)
  (when (not get-timestamp)
    (set! get-timestamp (make-timestamp-retriever)))
  (define url (build-api-url url-string params))
  (define full-headers
    (authenticate
      verb
      (url->string url)
      (or data "")
      (append (base-headers) headers)))
  (match verb
    ['GET (ovh-api-get url full-headers)]
    ['POST (ovh-api-post url full-headers data)]
    ['PUT (ovh-api-put url full-headers data)]
    ['DELETE (ovh-api-delete url full-headers)]
    [_ (raise-user-error 'unsupported-verb "~a" verb)]))
