#!/bin/bash

# Script for disk monitoring
# Author Epikhin Mikhail
# michael.nomanlab.org
# version 1.1

NUBMER=100500
FROMFILE=$1
DISK=$2
METRIC=$3

case "$3" in
"rrqm/s")
	NUMBER=2
;;
"wrqm/s")
	NUMBER=3
;;
"r/s")
	NUMBER=4
;;
"w/s")
	NUMBER=5
;;
"rsec/s")
	NUMBER=6
;;
"wsec/s")
	NUMBER=7
;;
"avgrq-sz")
	NUMBER=8
;;
"avgqu-sz")
	NUMBER=9
;;
"await")
	NUMBER=10
;;
"svctm")
	NUMBER=11
;;
"util")
	NUMBER=12
;;
esac

cat $FROMFILE | grep $DISK | tail -n +2 | tr -s ' ' | cut -f$NUMBER -d' ' | awk 'BEGIN {sum=0.0;count=0;} {sum=sum+$1;count=count+1;} END {printf("%.2f\n", sum/count);}'

#iostat -x | grep $1 | tr -s ' ' | cut -f$NUMBER -d' '
