#!/bin/sh

# set variables
webpath=https://openhab.ci.cloudbees.com/job/openHAB/$1/artifact/distribution/target/
version=1.4.0-
dist=-${version}SNAPSHOT

if  [ "$#" -ne 1 ]
 then
  echo "get Snapshot of openhab"
  echo ""
  echo "Usage: `basename $0` {snapshot-number}"
  exit 1
fi

# create path
mkdir /opt/openhab_habmin/${version}$1
cd /opt/openhab_habmin/${version}$1
mkdir zips

echo "Created Directory /opt/openhab_habmin/${version}$1"
echo "let's download openHAB${dist}-$1"

# get snapshot
echo "Get designer"
wget -nv ${webpath}distribution${dist}-designer-linux.zip
echo "Got designer"
echo "Get runtime"
wget -nv ${webpath}distribution${dist}-runtime.zip
echo "Got runtime"
echo "Get demo"
wget -nv ${webpath}distribution${dist}-demo.zip
echo "Got demo"
echo "Get addons"
wget -nv ${webpath}distribution${dist}-addons.zip
echo "Got addons"
echo "Get greent"
wget -nv ${webpath}distribution${dist}-greent.zip
echo "Got greent"
wget -nv https://github.com/cdjackson/HABmin/archive/master.zip
echo "Got HABmin"
mv distribution${dist}* zips
mv master.zip zips

echo "unzipping..."
# unzip to folders
unzip -q zips/distribution${dist}-designer-linux.zip -d ide
unzip -q zips/distribution${dist}-runtime.zip -d runtime
unzip -q zips/distribution${dist}-demo.zip -d runtime/demo
unzip -q zips/distribution${dist}-addons.zip -d runtime/addons_inactive
unzip -q zips/distribution${dist}-greent.zip -d runtime/webapps
unzip -q zips/master.zip -d runtime/webapps
mv runtime/webapps/HABmin-master runtime/webapps/habmin

echo "move addons"
# move all needed addons to activate
mv runtime/addons_inactive/org.openhab.binding.http${dist}.jar  runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.knx${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.mpd${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.networkhealth${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.ntp${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.tcp${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.vdr${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.wol${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.persistence.db4o${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.persistence.gcal${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.persistence.logging${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.persistence.rrd4j${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.persistence.exec${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.persistence.mysql${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.action.xmpp${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.action.mail${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.action.nma${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.action.prowl${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.action.twitter${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.action.xbmc${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.exec${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.onkyo${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.samsungtv${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.serial${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.sonos${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.systeminfo${dist}.jar runtime/addons/
mv runtime/addons_inactive/org.openhab.binding.zwave${dist}.jar runtime/addons/
mv runtime/webapps/habmin/addons/org.openhab.*.jar runtime/addons/

echo "make links..."
# link configs, images and databases
mv runtime/configurations runtime/configurations_old
mv runtime/etc runtime/etc_old
mv runtime/webapps/images runtime/webapps/images_old

ln -s /opt/openhab_habmin/configurations/ runtime/configurations
ln -s /opt/openhab_habmin/etc/ runtime/etc
ln -s /opt/openhab_habmin/images/ runtime/webapps/images

echo "copy default.cfg and logback.xml"
cp runtime/configurations_old/openhab_default.cfg runtime/configurations
#mv runtime/configurations/logback.xml runtime/configurations/logback.xml.old
#mv runtime/configurations/logback_debug.xml runtime/configurations/logback_debug.xml.old
#cp runtime/configurations_old/logback.xml runtime/configurations/logback.xml
#cp runtime/configurations_old/logback_debug.xml runtime/configurations/logback_debug.xml

echo "ready to switch to openHAB${dist}-$1"

