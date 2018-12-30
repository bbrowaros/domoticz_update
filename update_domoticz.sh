#!/bin/bash

#########################################
#	PUMBA DOMOTICZ UPDATE SCRIPT	#
# Script vrote to automatic backup and 	#
# update domoticz BETA releases 	#
#					#
#########################################

VERSION="0.2"

##Version tracking
# 0.2 - added some nice look during auto-update to prevent from seeing blank screen during copy, added version control 
# 0.1 - first release, basic options -u and -h, support for detecting if script was stared as root 


usage () { echo "Usage: $0 "
           echo " Script needs to be started as root" 
           echo "      [-u] for update " 
           echo "      [-v] for version " 1>&2; exit 1; }
version_show () {
           echo "Version $VERSION"
            }


if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


update=false
debug=false

version_running=`curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=getversion' | python3 -c "import sys, json; print(json.load(sys.stdin)['version'])"`

wget -q -O temp http://releases.domoticz.com/releases/downloads.php
ver_av=`grep Beta temp -A 5 | tail -1`

version_av=${ver_av##*>}


while getopts "uhdv" o; do 
   case ${o} in 
     u) 
       version_running=`curl -s 'http://127.0.0.1:8080/json.htm?type=command&param=getversion' | python3 -c "import sys, json; print(json.load(sys.stdin)['version'])"`
       wget -q -O temp http://releases.domoticz.com/releases/downloads.php
       ver_av=`grep Beta temp -A 5 | tail -1`

       version_av=${ver_av##*>}
       #checking if both are on 3 .... if not we have a major update and we need to decide manually
       version_running_maj=${version_running%.*}
       version_av_maj=${version_av%.*}
       if [ "$version_av_maj" -eq "$version_running_maj" ]; then 
       version_running_low=${version_running##*.}
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

DATE=`date +%d_%m_%Y_%H%M`

if $debug; then 
  echo "Debug not performing any copy actual copy" 
  
else
 echo -n "Copy of DB ..."
 if cp -r /home/bbrowaros/domoticz/domoticz.db /home/bbrowaros/domoticz_manual_backup/domoticz_$DATE.db
 then
  chown -R bbrowaros:plex /home/bbrowaros/domoticz_manual_backup/domoticz_$DATE.db
  echo "done"
 else
  echo "failed"
  exit
 fi


echo -n "Copy of script folder ...." 
 if cp -r /home/bbrowaros/domoticz/scripts /home/bbrowaros/domoticz_manual_backup/scripts_$DATE
 then
  chown -R bbrowaros:plex /home/bbrowaros/domoticz_manual_backup/scripts_$DATE
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

echo -n "Copy of domoticz folder ... "
if cp -r /home/bbrowaros/domoticz /home/bbrowaros/domoticz_old_vers/domoticz$DATE
 then
 chown -R bbrowaros:plex /home/bbrowaros/domoticz_old/vers/domoticz$DATE
 echo "done"
else 
 echo "failed, please check manually" 
 exit
fi

cd /home/bbrowaros/domoticz
./updatebeta
fi

fi

