#!/bin/bash
usage () { echo "Usage: $0 [-u] for update " 1>&2; exit 1; }

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


while getopts "uhd" o; do 
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
        elseif [ "$version_running_low" -eq "$version_avi_low" ] 
          echo "You are up to date"
          exit
        else
          echo "Update available"
          update=true
        fi
       else 
        echo "Major numbers are not matchin we are running $version_running_maj and page shows that we have $version_av_maj" 
        exit
       fi

     ;;
     h)
       usage
     ;;
     d)
       debug=true
     ;;
     *)
     ;;
   esac
done 

DATE=`date +%d_%m_%Y_%H%M`

if $debug; then 
  echo "Debug not performing any copy"
else
 if cp -r /home/bbrowaros/domoticz/domoticz.db /home/bbrowaros/domoticz_manual_backup/domoticz_$DATE.db
 then
  chown -R bbrowaros:plex /home/bbrowaros/domoticz_manual_backup/domoticz_$DATE.db
  echo "Copy of DB done"
 else
  echo "Copy of DB failed"
  exit
 fi
fi


if $update; then 

if $debug; then 
 echo "Debug not performing copy of db and update"
else
if cp -r /home/bbrowaros/domoticz /home/bbrowaros/domoticz_old_vers/domoticz$DATE
 then
 chown -R bbrowaros:plex /home/bbrowaros/domoticz_old/vers/domoticz$DATE
 echo "Copy of domoticz folder done"
else 
 echo "Copy of domoticz folder failed, please check manually" 
 exit
fi

cd /home/bbrowaros/domoticz
./updatebeta
fi

fi

