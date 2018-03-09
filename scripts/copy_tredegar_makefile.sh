#!/bin/bash

cp $(dirname $0)/Makefile ./"$1"/

echo
echo "******************************************************"
echo
echo "Makefile copied to the current directory from $(dirname $0)."
echo "Run 'make' to run the pipeline."
echo "See https://github.com/VADGS/Tredegar for more information."
echo
echo "******************************************************"
echo
