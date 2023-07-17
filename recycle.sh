#!/bin/bash

#Script to recycle the input file to a recyclebin
#Written by Wenyuan(Craig) Li

#Function to check if recyclebin exist and create recyclebin if it doesnt
function create(){
        if [ ! -d $HOME/recyclebin ]
        then
                mkdir $HOME/recyclebin
        fi
}

#Function to determine the user input option
#By default there is no option selected by the user and all other is off
function optFunc(){

        noOpt=true
        info=false
        verb=false
        recur=false

        while getopts :ivr optVar
        do
                case $optVar in
                i) info=true
                   noOpt=false ;;
                v) verb=true
                   noOpt=false ;;
                r) recur=true
                   noOpt=false ;;
                *) echo "ERROR option '$optVar' is invalid"
                   exit 1
                esac
        done
}

#Function to check if there is no input argument
function checkNO(){
        if [ $# -eq 0 ]
        then
                echo "ERROR no input argument provided"
                exit 1
        fi
}

#Function to check for errors and run recycle function if no errors
#If error occurs display error message and move on to next argument
#If all error checks are passed then run process function
#If recursive option is true then don not check for directory
function checkOTH(){
        if [ $recur = false ]
        then
                for arg in $*
                do
                        if [ "$(readlink -e "$arg")" = "$(readlink -e ~/scripts/recycle)" ]
                        then
                                echo "Attempting to delete recycle script - operation aborted"
                                continue
                        elif [ ! -e $arg ]
                        then
                                echo "ERROR '$arg' does not exist"
                                continue
                        elif [ -d $arg ]
                        then
                                echo "ERROR '$arg' is a directory"
								continue
                        fi
                        processFunc $arg
                done
        else
                for arg in $*
                do
                        if [ "$(readlink -e "$arg")" = "$(readlink -e ~/project/recycle)" ]
                        then
                                echo "Attempting to delete recycle script - operation aborted"
                                continue
                        elif [ ! -e $arg ]
                        then
                                echo "ERROR '$arg' does not exist"
                                continue
                        fi
                        processFunc $arg
                done
        fi
}

#Function to process the selected option
function processFunc(){
        #If no input option is true run rcyFunc
        if [ $noOpt = true ]
        then
                rcyFunc $*
        #If both inform and verbose option are true run inveFunc
        elif [ $info = true ] && [ $verb = true ]
        then
                inveFunc $*
        #If inform option is true then run infoFunc
        elif [ $info = true ]
        then
                infoFunc $*
        #If verbose option is true then run rcyFunc and display message
        elif [ $verb = true ]
        then
                rcyFunc $*
                echo "Recycled '$*'"
        #If the recursive option is true then run recurFunc
        elif [ $recur = true ]
        then
                recurFunc $*
        fi
}


#Function for inform option
#Similar to rm display different message if file is empty or not
function infoFunc(){
        if [ -s $* ]
        then
                read -p "recycle: recycle regular file '$*'? " respVar
                case $respVar in
                y*|Y*) rcyFunc $* ;;
                *)       ;;
                esac
        else
                read -p "recycle: recycle regular empty file '$*'? " respVar
                case $respVar in
                y*|Y*) rcyFunc $* ;;
                *)       ;;
                esac
        fi
}

#Function for when both inform and verbose option are selected
#Same as infoFunc but display message on operation
function inveFunc(){
        if [ -s $* ]
        then
                read -p "recycled: recycle regular file '$*'? " respVar
                case $respVar in
                y*|Y*) rcyFunc $*
                       echo "Recycled '$*'" ;;
                *)     echo "File '$*' not recycled" ;;
                esac
        else
                read -p "recycle: recycle regular empty file '$*'? " respVar
                case $respVar in
                y*|Y*) rcyFunc $*
                       echo "Recycled '$*'" ;;
                *)     echo "File '$*' not recycled" ;;
                esac
        fi
}


#Function for the recursive option
function recurFunc(){
        #If input is a directory run recurDir
        if [ -d $* ]
        then
                recurDir $*
        #If it is not a directory run rcyFunc
        else
                rcyFunc $*
        fi
}

#Function to read content of directory
function recurDir (){
        #Depth of directory with depthFunc
        dep=$(depthFunc $*)
        #dep=$(find $* -type d -printf '%d\n' | sort -rn | head -1)
        #List all the directories with specified depth
        drLt=$(find $* -maxdepth $dep -type d)
        #Get the number of directories
        noDr=$(echo $drLt | wc -w)

        #For each directory we find the contents and recycle
        for ((i=1; i<=$noDr; i++))
        do
                #The directory name and path that was listed
                dirN=$(echo $drLt | cut -d " " -f$i)
                path=$(readlink -e $dirN)
                #Contents and number of contents in directory
                content=$(ls $path)
                no_cont=$(echo $content | wc -w)
                #If nothing in input directory just remove
                if [ $no_cont -eq 0 ]
                then
                        rmdir $path
                else
                #If the main directory is not empty each content in the directory
                        for ((ii=1; ii<=$no_cont; ii++))
						do
                                #The file and path
                                file=$(echo $content | cut -d " " -f$ii)
                                filepath=$(readlink -e $path/$file)
                                #If the file is not a directory run rcyFunc
                                if [ ! -d $filepath ]
                                then
                                        rcyFunc $filepath
                                #If directory is empty then remove
                                elif [ -z "$(ls $filepath)" ]
                                then
                                        rmdir $filepath
                                fi
                        done
                fi
        done

        #List all the directories again once they are empty
        drLt1=$(find $* -maxdepth $dep -type d)
        #Get number of directories left
        noDr1=$(echo $drLt | wc -w)
        #For each empty directory perform remove directory
        for ((i=$noDr1; i>=1; i--))
        do
                dir1=$(echo $drLt1 | cut -d " " -f$i)
                dirPath1=$(readlink -e $dir1)
				rmdir $dirPath1
        done
}

#Function to perform recycle
function rcyFunc(){
        inode=$(ls -i $1 | cut -d " " -f1)
        fName=$(basename $1)
        newName=$fName"_"$inode
        abspath=$(readlink -f $1)
        mv $1 ~/recyclebin/$newName
        echo $newName':'$abspath >> $HOME/.restore.info
}

#Function to find the maximum directory depth
#Easier to use printf but dont think it is allowed
#Max directory depth in Unix is 4096
function depthFunc(){
        for ((i=1; i<=4096; i++))
        do
                depth="$(($i-1))"
                compVar1=$(find $* -maxdepth $depth -type d)
                compVar2=$(find $* -maxdepth $i -type d)
                if [ "$compVar1" = "$compVar2" ]
                then
                        echo $depth
                        break
                fi
        done
}


###
#Main Operation#
###

create $*
optFunc $*
shift $[$OPTIND - 1]
checkNO $*
checkOTH $*

