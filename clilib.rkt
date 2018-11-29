#lang racket
; clilib - console color printing and interactive cli helpers, including logging
;
(provide ~a/color ~a/clr ~a/fore-back ~a/bold ~a/color-b ~a/color-u ~a/color-bu ~a/color-i ~a/color-bi ~a/color-iu ~a/color-biu)
(provide cprintf uncolor)
(provide ~a/decorate ~a/red ~a/green ~a/blue ~a/cyan ~a/yellow ~a/magenta)
(provide cursor-hmove cursor-upscroll screen-clear)
(provide cli-run-interactive cli-exit-interactive cli-set-prompt)
(provide get-logger)

;; Utility interfaces to the low-level command
(define (capability? cap) (system (~a "tput "cap" > /dev/null 2>&1")))
(define (tput . xs) (system (apply ~a 'tput " " (add-between xs " "))) (void))
(define (colorterm?) (and (capability? 'setaf) (capability? 'setab)))
(define color-map '([black "0"] [k "0"] [red "1"] [r "1"] [green "2"] [g "2"] [yellow "3"] [y "3"]
                    [blue "4"] [b "4"] [magenta "5"] [m "5"] [cyan "6"] [c "6"] [white "7"] [w "7"]))
;(define (foreground color) (tput 'setaf (cadr (assq color color-map))))
;(define (background color) (tput 'setab (cadr (assq color color-map))))
;(define (reset) (tput 'sgr0) (void))

(define reset "\e[0m")
(define (decorate text fg bg b i u)
  (~a "\e[3" (cadr (assq fg color-map))
    (if bg (~a ";4" (cadr (assq bg color-map))) "")
    (if b ";1" "") (if i ";3" "") (if u ";4" "") "m" text reset))

; main API
(define (~a/decorate color s #:bg [bg #f] #:bold [bold #f] #:italic [italic #f] #:under [under #f])
  (decorate s color bg bold italic under))
(define (~a/color color s)
  (~a/decorate color s))
(define (~a/color-u color s)
  (~a/decorate color s #:under #t))
(define (~a/color-b color s)
  (~a/decorate color s #:bold #t))
(define (~a/color-bu color s)
  (~a/decorate color s #:bold #t #:under #t))
(define (~a/color-i color s)
  (~a/decorate color s #:italic #t))
(define (~a/color-iu color s)
  (~a/decorate color s #:italic #t #:under #t))
(define (~a/color-bi color s)
  (~a/decorate color s #:bold #t #:italic #t))
(define (~a/color-biu color s)
  (~a/decorate color s #:bold #t #:italic #t #:under #t))

(define (~a/fore-back foreground background s)
  (~a "\e[3" (cadr (assq foreground color-map)) "m;4" (cadr (assq background color-map)) s reset))
(define (~a/bold s)
  (~a "\e[1m" s reset))

; shortcut API
(define (~a/red s) (~a/color 'red s))
(define (~a/green s) (~a/color 'green s))
(define (~a/blue s) (~a/color 'blue s))
(define (~a/cyan s) (~a/color 'cyan s))
(define (~a/yellow s) (~a/color 'yellow s))
(define (~a/magenta s) (~a/color 'magenta s))
(define (~a/black s) (~a/color 'black s))
(define (~a/white s) (~a/color 'white s))

(define (cprintf color fmt . args)
  (apply printf (~a/color color fmt) args))

; obsolete legacy - a simpler interface for non-bold color foreground only
(define (~a/clr clr s)
  (~a/decorate clr s))

(define (uncolor s)
  (string-replace s #px"[[:cntrl:]][[]3[0-9]m|[[:cntrl:]][[]0m" ""))

; cursor moving and clearing
(define (cursor-hmove n) (printf "\e[~aG" n))
(define (cursor-upscroll [n 1]) (printf "\e[~aS" n))
(define (screen-clear) (printf "\e[2J"))
;(display (~a/red "foo\n"))
;(display (~a/bold "BoldBar\n"))
;(display (~a/bold/color 'blue "boldblue\n"))
;(display (~a/color 'green "foobar\n"))

; logging
(define (get-logger logfile [mode 'append])
  (lambda (line)
    (define (logit p)
      (displayln line)
      (displayln (uncolor line) p))
    (call-with-output-file logfile logit #:exists mode)))

; ==================================================
; functions for interactive console input
(define *prompt* (make-parameter ">>"))
; act : ( lst ) -> (or/c any/c #f)
(define (cli-run-interactive act [leader ">>"])
  (*prompt* leader)
  (printf (*prompt*))
  (let ([tokens (string-split (string-downcase (read-line)))])
    (when (act tokens) (cli-run-interactive act (*prompt*)))))

(define (cli-set-prompt p) (*prompt* p))

(define (cli-exit-interactive tokens)
  (match (first tokens)
    [(or "q" "x" "e" "quit" "exit") #t]
    [_ #f]))

; you must define a fn to pass to cli-run, here is an example:
;
;;(define (act tokens)
;;  (and (not (cli-exit-interactive tokens))
;;    (match tokens
;;      [(or ("Done" ...) ("Finish" ...)) #t] ; other exit codes if desired
;;      ;; put your various commands here, must evaluate to #t or else youll exit
;;      ;; example below, entering 'list acting' will call (list-acting on the remainder of the line
;;      [(list (regexp #rx"lis.*") (regexp #rx"act.*") a) (list-acting a)]
;;      [_ (~a/red "Huh?\n")])))

; then start the interactive cli by calling:
; (cli-run-interactive act)

