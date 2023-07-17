#!/bin/bash

#Script to restore the input from the recyclebin
#Written by Wenyuan(Craig) Li

###
#Testing for error condtions stated
###
#If there is no input argument script displays error message and exit with status
if [ $# -eq 0 ]
then
        echo "ERROR no filename is provided"
        exit 1
#If input file does not exist displays error message and exit
elif [ ! -e $HOME/recyclebin/$1 ]
then
        echo "ERROR '$1' does not exist"
        exit 2
fi

###
#File restore
###
#The matching line in the restore file
matchLine=$(cat $HOME/.restore.info | grep -w "^$1")

#The originial file path and directory
filePath=$(echo $matchLine | cut -d ":" -f2)

#Can use paramter expansion ${$filePath%/*} to get directory as well if dirname is not allowed
fileDir=$(dirname $filePath)

#If file exists prompt notification asking decision
#No directory check because if file exist in target directory, the directory exist
if [ -e $filePath ]
then
        read -p "Do you want to overwrite? y/n " optVar
        case $optVar in
        y|Y|y*|Y*) mv -f $HOME/recyclebin/$1 $filePath
                   grep -v "$matchLine" $HOME/.restore.info > $HOME/.restoreTemp.info
                   mv -f $HOME/.restoreTemp.info $HOME/.restore.info
                   echo "File overwrite complete"
                   echo "File '$1' restored" ;;
        *)         echo "File overwrite incomplete"
                   echo "File '$1' not restored"
                   exit 0 ;;
        esac
#If the target directory does not exist create directory and move the file
#No file check is done because if directory doesnt exist no file will exist in target directory
elif [ ! -d $fileDir ]
then
        mkdir -p $fileDir
        mv $HOME/recyclebin/$1 $filePath
        grep -v "$matchLine" $HOME/.restore.info > $HOME/.restoreTemp.info
        mv -f $HOME/.restoreTemp.info $HOME/.restore.info
        echo "File '$1' restored"
#If file doesnt exist (check1) and directory exist (check2) restore it
else
        mv $HOME/recyclebin/$1 $filePath
        grep -v "$matchLine" $HOME/.restore.info > $HOME/.restoreTemp.info
        mv -f $HOME/.restoreTemp.info $HOME/.restore.info
        echo "File '$1' restored"
fi
