#!/bin/sh
# Script to parse and rewrite the hpacucli output so we can feed it to Zabbix.
# sven@timegate.de - 2010-05-13
 
#set -x
VERSION=0.5
 
cleanup() {
    if [ -e $clog ]; then
        rm $clog
    fi
}
 
check_ok() {
    if [ $rawv -eq 1 ]; then
        echo 0
    else
        echo 1
    fi
}
 
controllerstat() {
    sudo hpacucli ctrl all show status > $clog
 
    #Check if another hpacucli has been active, sleep and try again
    if [ $(grep -c '^Another' $clog) -eq 1 ]; then
        sleep 10
        controllerstat
        cleanup
        exit
    fi
 
    constat=1
    chachestat=1
    battstat=1
 
    #Check Controller overall status
    rawv=$(grep Controller $clog|awk '{print $3}'|grep -c OK)
    constat=$(check_ok)
 
    #Check Cache Status
    rawv=$(grep Cache $clog|awk '{print $3}'|grep -c OK)
    cachestat=$(check_ok)
 
    #Check for a battery and it's status if available
    if [ $(grep -c Battery $clog) -eq 0 ]; then
        battstat=0
    else
        rawv=$(grep Battery $clog|awk '{print $3}'|grep -c OK)
        battstat=$(check_ok)
    fi
 
    #Calculate overall status and return it
    allstat=$(( $constat + $cachestat + $battstat ))
    if [ $allstat -eq '0' ]; then
        echo 0
    else
        echo 1
    fi
}
 
diskstat() {
    sudo hpacucli ctrl slot=2 pd all show > $clog
 
    #Check if another hpacucli has been active, sleep and try again
    if [ $(grep -c '^Another' $clog) -eq 1 ]; then
        sleep 10
        diskstat
        cleanup
        exit
    fi
 
    drivecount=$(grep -c physicaldrive $clog)
    driveok=$(grep -c OK $clog)
 
    if [ $driveok -eq $drivecount ]; then
        echo 0
    else
        echo 1
    fi
}
 
### Main script ###
while getopts ":cdh" opt; do
    case $opt in
        c)
        #Create a save tempfile with mktemp
        clog=$(mktemp /var/tmp/clog.XXXXXXXXXXXX)
        controllerstat
        cleanup
        ;;
        d)
        #Create a save tempfile with mktemp
        clog=$(mktemp /var/tmp/clog.XXXXXXXXXXXX)
        diskstat
        cleanup
        ;;
        h)
        echo "HP disk and controller check version $VERSION"
        echo "Usage:"
        echo "-c Outputs controler overall status as 0 or 1"
        echo "-d Outputs disk overall status as 0 or 1"
        echo "-h Print this help"
        echo "Output legend: 0 equals OK, 1 indicates something went wrong"
        exit 1
        ;;
        \?)
        echo "Unknown option: -$OPTARG"
        echo "Try -h to get help"
        exit 1
        ;;
    esac
done
