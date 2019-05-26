;; this program will collect gerber files from an Altium "Outputs"
;; directory and build two zip files, one for OSHPark PCBoards, and one for
;; OSHStencil stencils. Run it from the directory containing the PrjPcb project file.
#lang racket
(require file/zip)
(require "clilib.rkt")

(define *execute-mode* (make-parameter #f))
;; you may override the board base filename on the command line.
;; if you don't, the program will find it from the .CSPcbDoc file in the project directory
(define *board-base* (make-parameter #f))
(command-line
  #:usage-help "Package Altium CircuitStudio gerber files for OSH Park and OSH Stencils"
  "Version 1.1"
  "ex: oshpark_pkg.exe -x <board-name>"
  "<board-name> is optional, it defaults to the base name of the .CSPcbDoc file found in the project directory."
  #:once-each [("-x" "--execute") "Create 2 zip archives of files for OSH Park and OSH Stencil"
                                 (*execute-mode* #t)]
  #:args ([board-base #f]) (*board-base* (if (string? board-base) (string-upcase board-base) #f)))

(define prj-file-ext ".PrjPcb")
(define pcb-file-ext ".CSPcbDoc")
(define outline-file-ext ".Outline")
(define brd-exts2 (string-split ".GTO .GTP .GTS .GTL .GBO .GBP .GBS .GBL .GKO .TXT"))
(define brd-exts4 (string-split ".GTO .GTP .GTS .GTL .GBO .GBP .GBS .GBL .GKO .G2L .G3L .TXT"))

(displayln ">>>oshpark_pkg.exe v 1.1")

(define (file-base-with-ext ext)
  (define (get-file-base p)
    (path->string (path-replace-extension (file-name-from-path p) "")))
  (define (has-ext? p) (path-has-extension? p ext))
  (let ([files (find-files has-ext?)])
    (if (empty? files) #f (string-upcase (get-file-base (first files)))))) 

(define (in-target-dir?)
  (string-ci=? "Outputs" (path->string (last (explode-path (current-directory))))))

(define (make-validator)
  (let ([errors '()])
    (lambda ([msg 'is?])
      (cond
        [(string? msg) (set! errors (append errors (list msg)))]
        [(symbol? msg)
         (case msg [(is?) (empty? errors)] [(report) (for ([m errors]) (cprintf 'r m))])]))))

;; move to the ./Outputs directory, save the original for resetting after we finish
(define orig-directory (current-directory))
(printf "current directory is ~a\n" (~a/green orig-directory))
(cond
  [(in-target-dir?)
    (displayln "current directory is the target directory: 'Outputs'")]
  [(file-base-with-ext prj-file-ext)
    (displayln "current directory is the project directory, changing to ./Outputs")
    (current-directory (build-path (current-directory) "Outputs"))
    (printf "current directory has been changed to ~a\n" (~a/green (current-directory)))]
  [else (cprintf 'red "Invalid current-directory, or project file not found:
                 must be in project directory or './Outputs'!\n") (exit)])

; We are now in Outputs, the target directory, or we have exited
; Move up to the Project directory
(current-directory "../")
;; get project base name
(define prj-base (file-base-with-ext prj-file-ext))
(unless prj-base (cprintf 'r "Project file not found!\n") (exit))
(printf "Base project name=~a\n" (~a/green prj-base))
; set pcb base *board-base* name if user did not provide it
(unless (*board-base*)
  (*board-base* (file-base-with-ext pcb-file-ext))
  (unless (*board-base*) (cprintf 'r "PCB file not provided or found!\n") (exit)))
(printf "PCB project name=~a\n" (~a/green (*board-base*)))
(current-directory (build-path (current-directory) "Outputs"))
;; back in the target directory

;; some functions that depend on *board-base* being set first
;; build the template sets, all uppercase
(define (build-filename ext) (string-upcase (string-append (*board-base*) ext)))
(define board-fileset-template2 (apply set (for/list ([x brd-exts2]) (build-filename x))))
(define board-fileset-template4 (apply set (for/list ([x brd-exts4]) (build-filename x))))
;;

(define validator (make-validator))

(define (copy-maybe src dest)
  (let ([full-src (string-append (*board-base*) src)]
        [full-dest (string-append (*board-base*) dest)])
    (cond
      [(file-exists? full-src)
        (copy-file full-src full-dest #t)
        (cprintf 'white "Copied ~a to ~a\n" full-src full-dest)
        #t]
      [else #f])))

(displayln (if (*execute-mode*) "will execute..." "will not execute."))

(define (execute)
  ;; if there is a .Outline file, it might be newer than a .GKO file, but can't be older
  ;; so we look for the .Outline first and use that if found, if not we expect a .gko
  (unless (copy-maybe ".Outline" ".GKO") (cprintf 'yellow "No .Outline file found, will expect a .GKO file\n"))
  ;; rename inner layers if they exist
  (copy-maybe ".G1" ".G2L")
  (copy-maybe ".G2" ".G3L")

  (when (validator)
    (define (boardfile? p) (set-member? board-fileset-template4 (string-upcase (path->string p))))
    (define all-found-files (map string-upcase (map path->string (find-files boardfile?))))
    ;(print all-found-files)
    ;(print board-fileset-template4)
    (cond
      [(equal? (apply set all-found-files) board-fileset-template4) (cprintf 'white "All files found for 4-layer board\n")]
      [(equal? (apply set all-found-files) board-fileset-template2) (cprintf 'white "All files found for 2-layer board\n")]
      [else (validator "Could not find all files necessary, aborting!")])

    (when (validator)
      (zip->output (list (build-filename ".gtp") (build-filename ".gbp"))
        (open-output-file (string-append prj-base "_stencil" ".zip") #:exists 'replace))
      (zip->output all-found-files
        (open-output-file (string-append prj-base "_board" ".zip") #:exists 'replace))
      (displayln "Done!"))))

(when (*execute-mode*) (execute))
(current-directory orig-directory)
(validator 'report)

    


