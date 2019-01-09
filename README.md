# racket-oshpark_pkg

This program will create two zip packages, one with PC board gerber files for upload to OSHPark, and certain other vendors such as ALLPCB, and one with only the stencil information, suitible for OSHStencils etc.

Altium Circuit Studio names the board outline file with the extension "Outline", this program changes that to "GKO" for OSHPark.

The zip packages produced may work with other vendors as well, they have been tested with ALLPCB.

The program must be run from either the Outputs directory in the Altium project directory, or the project directory itself. Run with no arguments to simply report what it will do, without doing it. Use the -x flag to cause it to execute.


