# racket-oshpark_pkg

This program will create two zip packages, one with PC board gerber files for upload to OSHPark, and certain other vendors such as ALLPCB, and one with only the stencil information, suitible for OSHStencils etc. They will be named with the project base name followed by "_board.zip" and "_stencil.zip".

Altium Circuit Studio names the board outline file with the extension "Outline", this program changes that to "GKO" for OSHPark. Similarly, for inner layers on a 4 layer board, the extensions are changed from G1 and G2 to G2L and G3L.

The zip packages produced may work with other vendors as well, they have been tested with ALLPCB, OSHPark, and OSHStencils.

The program must be run from either the "Outputs" directory in the Altium project directory, or the project directory itself. Run with no arguments to simply report what it will do, without executing. Use the -x flag to cause it to execute.

To build on Windows:
First (if you don't already have it) install Racket from racket-lang-org.
In the source directory, type "raco exe oshpark_pkg.rkt", and then move oshpark_pkg.exe to some directory in your PATH, or just move it to your Altium project directory.
Run it from the command line like so:

"oshpark_pkg.exe -h", for help
"oshpark_pkg.exe" to report what it will do
"oshpark_pkg.exe -x" to execute




