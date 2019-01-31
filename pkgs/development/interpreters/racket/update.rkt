#!/usr/bin/env nix-shell
#! nix-shell -i racket -p racket
#lang racket

(define table-url "https://mirror.racket-lang.org/installers/recent/table.rktd")
(define version-pattern #rx#"(version = \")([0-9.]*)(\";)")
(define (version-replace version) (lambda (_ prefix __ suffix)
  (bytes-append prefix version suffix)))

(require net/url)

(define table (read (get-pure-port (string->url table-url))))
(define filename (hash-ref table "{1} Racket | {4} Source"))
(define components (regexp-match #rx"racket-([0-9.]*)-src.tgz" filename))
(define version (string->bytes/utf-8 (second components)))

(with-output-to-file #:exists 'replace "default.nix.new" (lambda ()
  (with-input-from-file "default.nix" (lambda ()
    (let loop ()
      (define line (read-bytes-line))
      (cond
        [(eof-object? line) (void)]
        [(regexp-match version-pattern line)
         (define edited-line (regexp-replace version-pattern line (version-replace version)))
         (displayln edited-line)
         (loop)]
        [else
         (displayln line)
         (loop)]))))))
