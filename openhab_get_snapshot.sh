#!/bin/bash

# This version includes getting HABmin and
# functionality to get the latest Snapshot without knowing it's number, version or status (Snapshot or not)
# It also includes support for grafana and weather-binding (link to directories)

. /lib/lsb/init-functions

# by default getsnap gets information from /etc/default/getsnap
getsnapconf=/srv/openhab/getsnap.cfg
# ohpath is the real path of openHAB-files
ohpath=/srv/openhab/
# buildpath is the web-adress of build-server
buildpath=https://openhab.ci.cloudbees.com/job/openHAB/


if  [ "$#" -eq 0 ]
 then
  log_daemon_msg "Get lastBuild-Number"
  number=`wget --quiet -O - ${buildpath}lastBuild/ | sed -n 's/^\(.*\)\(<title>openHAB .\)\([0-9][0-9][0-9]\)\(.*\)$/\3/p'`
  log_end_msg $?
  echo lastBuild-Number is ${number}
  webpath=${buildpath}lastBuild/artifact/distribution/target/
 else
  if  [ "$#" -ne 1 ]
   then
    echo "get Snapshot of openhab"
    echo ""
    echo "Usage: $(basename $0) [Snapshotnumber]"
    exit 1
  fi
  number=${1}
  webpath=${buildpath}${number}/artifact/distribution/target/
fi

log_daemon_msg "Get openHAB-Version-Number of ${number}"
wget  --quiet -O /tmp/getsnap.data ${buildpath}${number}/
version=`sed -n 's/^\(.*\)\(artifact\/distribution\/target\/distribution-\)\([0-9]\.[0-9]\.[0-9]\)\(.*\)$/\3/p' /tmp/getsnap.data`
snapshot=`sed -n 's/^\(.*\)\(artifact\/distribution\/target\/distribution-\)\([0-9]\.[0-9]\.[0-9]\)\(.*\)\(-runtime.zip.*\)$/\4/p' /tmp/getsnap.data`
log_end_msg $?
if [ -z "$version" ]
 then
  echo "fatal error!"
  echo "${number} not found on server!"
  exit 1
fi
echo Nightly-Version is ${version}
if [ -n "$snapshot" ]
 then
  echo and is a ${snapshot}
fi
dist=-${version}${snapshot}

# create path
mkdir ${ohpath}${version}-${number}
mkdir ${ohpath}${version}-${number}/zips
cd ${ohpath}${version}-${number}/zips

echo "Created Directory ${ohpath}${version}-${number}"
echo "let's download openHAB${dist}-${number}"

# get snapshot
  log_daemon_msg "getting runtime"
   wget --quiet ${webpath}distribution${dist}-runtime.zip
  log_end_msg $?
  log_daemon_msg "unzipping runtime"
   unzip -q distribution${dist}-runtime.zip -d ../runtime
  log_end_msg $?
  log_daemon_msg "getting addons"
   wget --quiet ${webpath}distribution${dist}-addons.zip
  log_end_msg $?
  log_daemon_msg "unzipping addons to addons_inactive"
   unzip -q distribution${dist}-addons.zip -d ../runtime/addons_inactive
  log_end_msg $?

while read line
 do
case ${line:0:1} in
 \#)
;;
 *)
  case ${line} in
 macos_designer)
  log_daemon_msg "getting MacOSX-Designer"
   wget --quiet ${webpath}distribution${dist}-designer-macosx64.zip
  log_end_msg $?
  log_daemon_msg "unzipping MacOSX-Designer"
   unzip -q distribution${dist}-designer-macosx64.zip -d ../ide
  log_end_msg $?
;;
 linux32_designer)
  log_daemon_msg "getting Linux32bit-Designer"
   wget --quiet ${webpath}distribution${dist}-designer-linux.zip
  log_end_msg $?
  log_daemon_msg "unzipping Linux32bit-Designer"
   unzip -q distribution${dist}-designer-linux.zip -d ../ide
  log_end_msg $?
;;
 linux64_designer)
  log_daemon_msg "getting Linux64bit-Designer"
   wget --quiet ${webpath}distribution${dist}-designer-linux64bit.zip
  log_end_msg $?
  log_daemon_msg "unzipping Linux64bit-Designer"
   unzip -q distribution${dist}-designer-linux64bit.zip -d ../ide
  log_end_msg $?
;;
 windows_designer)
  log_daemon_msg "getting Windows-Designer"
   wget --quiet ${webpath}distribution${dist}-designer-win.zip
  log_end_msg $?
  log_daemon_msg "unzipping Windows-Designer"
   unzip -q distribution${dist}-designer-win.zip -d ../ide
  log_end_msg $?
;;
 demo)
  log_daemon_msg "getting demo"
   wget --quiet ${webpath}distribution${dist}-demo.zip
  log_end_msg $?
  log_daemon_msg "unzipping demo"
  unzip -q distribution${dist}-demo.zip -d ../runtime/demo
  log_end_msg $?
;;
 greent)
  log_daemon_msg "getting greent"
   wget --quiet ${webpath}distribution${dist}-greent.zip
  log_end_msg $?
  log_daemon_msg "unzipping greent"
  unzip -q distribution${dist}-greent.zip -d ../runtime/webapps
  log_end_msg $?
;;
 habmin)
  log_daemon_msg "getting HABmin"
   wget -nv https://github.com/cdjackson/HABmin/archive/master.zip
  log_end_msg $?
  log_daemon_msg "unzipping HABmin"
   unzip -q master.zip -d ../runtime/webapps
   mv ../runtime/webapps/HABmin-master ../runtime/webapps/habmin
   mv ../runtime/webapps/habmin/addons/org.openhab.*.jar ../runtime/addons/
   if [ -e ../runtime/addons_inactive/org.openhab.binding.zwave${dist}.jar ]
     then
       mv ../runtime/addons_inactive/org.openhab.binding.zwave${dist}.jar ../runtime/addons/
   fi
  log_end_msg $?
;;
*)
  log_daemon_msg "activated ${line}"
  mv ../runtime/addons_inactive/org.openhab.${line}${dist}.jar ../runtime/addons/
  log_end_msg $?
;;
esac
;;
esac
done < ${getsnapconf}

cd ../runtime
touch ./${number}

echo "create links..."
# link configs, images and databases
mv ./configurations ./configurations_old
mv ./etc ./etc_old
mv ./webapps/images ./webapps/images_old

ln -s ${ohpath}configurations/ ./configurations
ln -s ${ohpath}etc/ ./etc
ln -s ${ohpath}webapps/images/ ./webapps/images
ln -s ${ohpath}webapps/static/ ./webapps/static
ln -s ${ohpath}webapps/grafana/ ./webapps/grafana

if [ -e ${ohpath}webapps/grafana ]
  then
    ln -s ${ohpath}webapps/grafana/ ./webapps/grafana
fi
if [ -e ${ohpath}webapps/weather-data ]
  then
    ln -s ${ohpath}webapps/weather-data/ ./webapps/weather-data
fi
if [ -e ${ohpath}webapps/static/uuid ]
  then
    cp ${ohpath}webapps/static/uuid ./webapps/static/
fi
if [ -e ${ohpath}webapps/static/secret ]
  then
    cp ${ohpath}webapps/static/secret ./webapps/static/
fi

chmod 755 ./start*.sh

echo "copy default.cfg and logback.xml"
cp ./configurations_old/openhab_default.cfg ./configurations
mv ./configurations/logback.xml ./configurations/logback.xml.old
mv ./configurations/logback_debug.xml ./configurations/logback_debug.xml.old
cp ./configurations_old/logback.xml ./configurations/logback.xml
cp ./configurations_old/logback_debug.xml ./configurations/logback_debug.xml

mv /opt/openhab /opt/openhab_old-${number}
ln -s ${ohpath}${version}-${number}/runtime /opt/openhab

echo "ready to switch to openHAB${dist}-${number}"

exit 0
