#lang racket
(require file/zip)
(require "clilib.rkt")

(define *execute-mode* (make-parameter #f))
(command-line
 #:once-each [("-x" "--execute") "Execute build of compressed files for OSH Park and OSH Stencil"
                                 (*execute-mode* #t)])
(define (get-file-base p)
  (path->string (path-replace-extension (file-name-from-path p) "")))
  
(define (is-project-file? p)
  (path-has-extension? p ".PrjPcb"))

(define in-target-dir? (string-ci=? "Outputs"
                                    (path->string (last (explode-path (current-directory))))))

(define in-targets-parent-dir?
  (not (empty? (find-files is-project-file? #f #:skip-filtered-directory? #t))))

(define (is-board-file? p)
  (or (path-has-extension? p ".GTO")
      (path-has-extension? p ".GTP")
      (path-has-extension? p ".GTS")
      (path-has-extension? p ".GTL")
      (path-has-extension? p ".GBO")
      (path-has-extension? p ".GBP")
      (path-has-extension? p ".GBS")
      (path-has-extension? p ".GBL")
      (path-has-extension? p ".GKO")))
  
(define (is-screen-file? p)
  (or (path-has-extension? p ".GTP")
      (path-has-extension? p ".GBP")))

(define (is-drill-file? p)
  (path-has-extension? p ".TXT"))

(define (extension-checker ext) (lambda (x) (path-has-extension? x ext)))

(define (make-validator)
  (let ([errors '()])
    (lambda ([msg 'is?])
      (cond
        [(string? msg) (set! errors (append errors (list msg)))]
        [(symbol? msg)
         (case msg [(is?) (empty? errors)] [(report) (for ([m errors]) (cprintf 'r m))])]))))


(define orig-directory (current-directory))
(printf "current directory is ~a\n" (~a/green orig-directory))
(cond
  [in-target-dir? (displayln "current directory is the target directory")]
  [in-targets-parent-dir? (displayln "current directory is the project directory, changing to ./Outputs")
                          (current-directory (build-path (current-directory) "Outputs"))
                          (printf "current directory has been changed to ~a\n" (~a/green (current-directory)))]
  [else (println "Invalid current-directory: must be in project directory or 'Outputs'!") (exit)])

; We are now in Outputs, the target directory, or we have exited
;

(current-directory "../")
(define project-files (find-files is-project-file? #:skip-filtered-directory? #t))
(when (empty? project-files) (cprintf 'r "Project file not found!\n") (exit))
(current-directory (build-path (current-directory) "Outputs"))

(define validator (make-validator))

(displayln (if (*execute-mode*) "will execute..." "will not execute."))

(define (execute)
  (define outline-files (find-files (extension-checker ".Outline")))
  (define gko-files (find-files (extension-checker ".GKO")))
  (cond
    [(not (empty? outline-files))
     (println "renaming outline file...")
     (rename-file-or-directory (first outline-files) (path-replace-extension (first outline-files) ".GKO") #t)]
    [(not (empty? gko-files)) ; and we know already outline-files must be empty
     (cprintf 'yellow "Could not find .Outline file to rename, using existing .GKO file.\n")]
    [else ; there is no .GKO and no .Outline to make one from
      (validator "Could not find new .Outline file and there is no existing .GKO file!")])
  
  (when (validator)
    (define base (get-file-base (first project-files)))
    
    (define screen-files (find-files is-screen-file? #:skip-filtered-directory? #t))
    (if (empty? screen-files)
      (validator  "No paste file found in Outputs directory, aborting!")
      (cprintf 'white "~a paste file(s) found\n" (length screen-files)))
    (define board-files (find-files is-board-file? #:skip-filtered-directory? #t))

    (if (empty? board-files)
      (validator  "No board files found in Outputs directory, aborting!")
      (cprintf 'white "~a board files found.\n" (length board-files)))

    (define drill-files (find-files is-drill-file? #:skip-filtered-directory? #t))
    (when (empty? drill-files) (validator  "No drill files found in Outputs directory, aborting!"))
    (when (validator)
      (zip->output screen-files (open-output-file (string-append base "_stencil" ".zip") #:exists 'replace))
      (zip->output (append board-files drill-files) (open-output-file (string-append base "_board" ".zip") #:exists 'replace))
      (println "Done!"))))

(when (*execute-mode*) (execute))
(current-directory orig-directory)
(validator 'report)

    


