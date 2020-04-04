#!/bin/bash

#########################################
#	PUMBA DOMOTICZ UPDATE SCRIPT	#
# Script wrote to automatic backup and 	#
# update domoticz BETA releases 	#
#					#
#########################################

VERSION="0.7"

# Description:
#
# This script can be used to backup a domoticz.db file and a script folder, with '-u' option will start a full backup of the domoticz instance and start update via cli of domoticz"
# I'm using this script to automatically backup all scripts in domoticz/scripts directory and domoticz.db via cron periodic runs. Manual run is done adding '-u' to perform a update proces. Update process will check if newer version is available and only run when newer version is there. If major version is changed a manual imput is required to update. 
# NOTE this script require a root access (in my configuration required however maybe not required in all configs can be disabled)


##Version tracking
# 0.7 - changed the version checking to allign with new schema on domoticz, make some changes to allow publishing this script
# 0.6 - adding a new centralized backup point (this will be mounted from nas) removing chmod no need for it
# 0.5 - adding description where the file are copy for easy recovery 
# 0.4 - adding cert copy after upgrade
# 0.3 - changed the time format in filename to better list all copies via ls 
# 0.2 - added some nice look during auto-update to prevent from seeing blank screen during copy, added version control 
# 0.1 - first release, basic options -u and -h, support for detecting if script was stared as root 


#Where the data will be sotred as backup before update
BACKUP_PATH="/home/bbrowaros/domoticz_backup"

#Where the domoticz running instance is located
DOMOTICZ_PATH="/home/bbrowaros/domoticz"

#Domoticz web access for the version checking mechanism
DOMOTICZ_IP="192.168.1.101"
DOMOTICZ_PORT="8080"


#If root access is required set this to true. Script will check firs if was run with sudo
ROOT_NEEDED=true

usage () { echo "Usage: $0 "
           echo " Script needs to be started as root" 
           echo "      [-u] for update " 
           echo "      [-v] for version " 1>&2; exit 1; }
version_show () {
           echo "Version $VERSION"
            }

if $ROOT_NEEDED ; then 
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

fi

update=false
debug=false

DOMOTICZ_ADDRESS="http://$DOMOTICZ_IP:$DOMOTICZ_PORT/json.htm?type=command&param=getversion"
RESULT=`curl -s $DOMOTICZ_ADDRESS`

version_running=`echo $RESULT | python3 -c "import sys, json; print(json.load(sys.stdin)['version'])"`

wget -q -O temp http://releases.domoticz.com/releases/downloads.php
ver_av=`grep Beta temp -A 5 | tail -1`

version_av=${ver_av##*>}


while getopts "uhdv" o; do 
   case ${o} in 
     u) 
       version_running=`curl -s 'http://192.168.1.101:8080/json.htm?type=command&param=getversion' | python3 -c "import sys, json; print(json.load(sys.stdin)['version'])"`
       wget -q -O temp http://releases.domoticz.com/releases/downloads.php
       ver_av=`grep Beta temp -A 5 | tail -1`

       version_av=${ver_av##*>}
       #checking if both are on 3 .... if not we have a major update and we need to decide manually
       # v0.7 domoticz changed major version syntax
       #version_running_maj=${version_running%.*}
       version_running_maj=`echo $version_running | cut -d' ' -f1`
       version_av_maj=${version_av%.*}
       
      #since the major version number has following format 2020.1 we need to split it and change the way we check the major version 
       #checking if we are running the same first part 2020 or whatever
       version_av_maj_p1=${version_av_maj%%.*}
       version_running_maj_p1=${version_running_maj%%.*}

       #second part after .1
       version_av_maj_p2=${version_av_maj#*.}
       version_running_maj_p2=${version_running_maj#*.}
      
       #version majcor checking
       maj=false
       if [ "$version_av_maj_p1" -eq "$version_running_maj_p1" ]; then 
          if [ "$version_av_maj_p2" -eq "$version_running_maj_p2" ]; then 
                 maj=true
   	  fi
       fi

  
       if  $maj ; then 
       #changing this as numbering changed
       #version_running_low=${version_running##*.}
       version_running_low_t=`echo $version_running | awk {' print $3 '}`
       version_running_low=`echo $version_running_low_t | cut -d')' -f1`
       version_av_low=${version_av##*.}
       echo "Running version of Domoticz: $version_running"
       echo "Version available on page: $version_av"

        if [ "$version_running_low" -gt "$version_av_low" ]; then 
          echo "You are running later version, possibly manually make was issued"
          exit
        else
          if [ "$version_running_low" -eq "$version_av_low" ]; then
           echo "You are up to date"
           exit
          else
           echo "Update available"
           update=true
          fi
        fi
       else 
        echo "Major numbers are not matchin we are running $version_running_maj and page shows that we have $version_av_maj" 
       read -p "Do you want to update the major version of Domoticz [y/n]?" yn
       case $yn in 
        [Yy]* ) update=true;
                break;;
        [Nn]* ) exit;;
       esac
       fi

     ;;
     h)
       usage
     ;;
     d)
       debug=true
     ;;
     v)
       version_show
       exit
     ;;
     *)
     ;;
   esac
done 

DATE=`date +%Y_%m_%d_%H%M`

if $debug; then 
  echo "Debug not performing any copy actual copy" 
  
else
 echo -n "Copy of DB to ..."
 if cp -pr $DOMOTICZ_PATH/domoticz.db $BACKUP_PATH/domoticz_manual_backup/domoticz_$DATE.db
 then
  #chown -R bbrowaros:plex $BACKUP_PATH/domoticz_manual_backup/domoticz_$DATE.db
  echo "done"
 else
  echo "failed"
  exit
 fi


echo -n "Copy of script folder ...." 
 if cp -r /home/bbrowaros/domoticz/scripts $BACKUP_PATH/domoticz_manual_backup/scripts_$DATE
 then
  #chown -R bbrowaros:plex $BACKUP_PATH/domoticz_manual_backup/scripts_$DATE
  echo "done" 
 else
  echo "failed" 
  exit
 fi

fi


if $update; then 

if $debug; then 
 echo "Debug not performing copy of db and update"
else

echo -n "Copy of domoticz folder to $BACKUP_PATH/domoticz_old_vers/domoticz$DATE/ ... "
if cp -r /home/bbrowaros/domoticz $BACKUP_PATH/domoticz_old_vers/domoticz$DATE
 then
 #chown -R bbrowaros:plex $BACKUP_PATH/domoticz_old/vers/domoticz$DATE
 echo "done"
else 
 echo "failed, please check manually" 
 exit
fi

cd $DOMOTICZ_PATH
./updatebeta
#restoring cert
cp /home/bbrowaros/domoticz/server_cert.pem_back /home/bbrowaros/domoticz/server_cert.pem

fi

fi

