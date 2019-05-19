#! /bin/sh
echo "will build oshpark_pkg.exe and deploy it to c:/bin"
echo "working..."
raco exe oshpark_pkg.rkt
mv oshpark_pkg.exe /c/bin/
echo "done."

