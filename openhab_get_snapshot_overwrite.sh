#!/bin/sh
#
# created by Christoph Wempe
# 2013-08-10
#
# inspired by udo1toni
# http://knx-user-forum.de/331773-post1.html
#
# This script automates the update-process for the latest snapshot.
#
# What this script does:
# - download the latest snapshot files (nightly build)
#   custom build-number can be passed to the script
#     ./<script.sh> 412
# - unzip downloaded files to temp folder
# - copy/overwrite old files with new snapshot files
#   new config files won't overwrite existing ones
#
# Make sure to execute this script as the same user that runs openhab
#


### set variables

# Check if build-number is manually passed to the script
# otherwise use latest successfull build
if [ -n "$1" ]
    then
        build="$1"
    else
        build="lastSuccessfulBuild"
fi

webpath="https://openhab.ci.cloudbees.com/job/openHAB/${build}/artifact/distribution/target"
version="1.3.0"
dist="${version}-SNAPSHOT"
backupsuffix="default_${version}"

### set paths
# path where the current openhab files are
openhabfolder="/opt/openhab_test"
designerfolder="${openhabfolder}/openhab_designer"
# folder where the files can be stored temporarily 
tempfolder="/tmp/openhab"
# folder where the openhab runtime should be extracted
tempruntime="${tempfolder}/runtime"
# all addons will be xtracted to this folder
tempalladdons="${tempfolder}/all_addons"
# but only the selected addons will be copied to the runtime folder
tempaddons="${tempruntime}/addons"
tempwebapps="${tempruntime}/webapps"
tempdesigner="${tempfolder}/designer"

### list of files to be updated
# space separated
# example: "runtime addons demo drools greent designer-linux designer-linux64bit designer-macosx64 designer-win"
filelist="runtime \
          addons \
          demo \
          drools \
          greent"

### list of addons to be used
# space separated
# if "demo" is selected in ${filelist}, the included addons will be copied anyway
# example: "persistence.exec persistence.rrd4j binding.http binding.hue io.multimedia.tts.freetts"
addonlist="action.xbmc \
          action.xmpp \
          binding.exec \
          binding.http \
          binding.networkhealth \
          binding.ntp \
          binding.onewire \
          binding.onkyo \
          binding.vdr \
          persistence.logging \
          persistence.rrd4j"

### list of files to exclude from copying to openhab-folder
# space separated, including path (relative to ${tempruntime})
# example: "start.sh configurations/users.cfg configurations/persistence/rrd4j.persist"
excludelist="start.sh \
             start_debug.sh \
             configurations/logback.xml \
             configurations/logback_debug.xml \
             configurations/users.cfg \
             configurations/persistence/rrd4j.persist \
             configurations/persistence/exec.persist"

### print parameters
echo ""
echo "Parameters:"
echo "  build:          ${build}"
echo "  webpath:        ${webpath}"
echo "  version:        ${version}"
echo "  dist:           ${dist}"
echo "  backupsuffix:   ${backupsuffix}"
echo "  openhabfolder:  ${openhabfolder}"
echo "  designerfolder: ${designerfolder}"
echo "  tempfolder:     ${tempfolder}"
echo "  tempruntime:    ${tempruntime}"
echo "  tempalladdons:  $tempalladdons"
echo "  tempaddons:     ${tempaddons}"
echo "  tempwebapps:    ${tempwebapps}"
echo "  tempdesigner:   ${tempdesigner}"
echo "  filelist:       "`echo ${filelist} | sed 's/\ +/ /g'`
echo "  addonlist:      "`echo ${addonlist} | sed 's/\ +/ /g'`
echo "  excludelist:    "`echo ${excludelist} | sed 's/\ +/ /g'`


### check if the user selected more than one designer
if [ `echo "${filelist}" | tr -s ' ' '\n' | grep -c "designer"` -gt 1 ]
    then 
        echo ""
        echo "There are more than one designer selected in the filelist."
        echo "This makes no sense and won't work with this script."
        exit 1
fi

### create or clean folders if needed
echo ""
echo "Checking folders:"
if [ ! -d "${openhabfolder}" ]
    then
        echo " - openhab folder (${openhabfolder}) does not exist"
        echo "   will be created now ..."
        mkdir ${openhabfolder}
    else
        echo " - openhab folder (${openhabfolder}) does already exist"
fi

if [ `echo "${filelist}" | tr -s ' ' '\n' | grep -c "designer"` -eq 1 ]
    then
        if [ ! -d "${designerfolder}" ]
            then
                echo " - designer folder (${designerfolder}) does not exist"
                echo "   will be created now ..."
                mkdir ${designerfolder}
            else
                echo " - designer folder (${designerfolder}) does already exist"
        fi
    else
        echo " - designer folder (${designerfolder}) is not required"
fi

if [ ! -d "${tempfolder}" ]
    then
        echo " - temp folder (${tempfolder}) does not exist"
        echo "   will be created now ..."
        mkdir ${tempfolder}
    else
        echo " - temp folder (${tempfolder}) does already exist"
        echo "   cleaning folder ..."
        rm -r ${tempfolder}/*
fi


### download and extract snapshot files
echo ""
echo "Downloading and extracting shapshot files:"
for file in ${filelist}
do
    filename="distribution-${dist}-${file}"
    echo " - ${file}"
    echo "   - downloading ..."
    wget -q -P ${tempfolder} ${webpath}/${filename}.zip
    case ${file} in
        designer*) extractfolder="${tempfolder}/${file}";;
        runtime)   extractfolder="${tempruntime}";;
        addons)    extractfolder="${tempalladdons}";;
        demo)      extractfolder="${tempruntime}";;
        drools)    extractfolder="${tempruntime}";;
        greent)    extractfolder="${tempwebapps}";;
        *)         extractfolder="${tempwebapps}";;

    esac
    echo "   - extracting to ${extractfolder} ..."
    unzip -uq ${tempfolder}/${filename}.zip -d ${extractfolder}
#    echo ""
done


### copy selected addons to runtime folder
echo ""
echo "Copying selected addons to runtime folder:"
for addon in ${addonlist}
do
    echo " - ${addon}"
    addonfilename="org.openhab.${addon}-${dist}.jar"
    cp ${tempalladdons}/${addonfilename} ${tempaddons}/${addonfilename}
done
echo " !!! Make sure there are no duplicate addons in your addon folder !!!"


### rename files to avoid overwriting of existing configs etc.
echo ""
echo "Rename files to avoid overwriting:"
for excludefile in ${excludelist}
do
    # check if source file exists
    if [ -f ${tempruntime}/${excludefile} ]
        then
            # check if destination file exists
            if [ -f ${openhabfolder}/${excludefile} ]
                then
                    # check if source and desitination files differ
                    if [ "`md5sum ${tempruntime}/${excludefile} | awk '{print $1}'`" != "`md5sum ${openhabfolder}/${excludefile} | awk '{print $1}'`" ]
                        then
                            echo " - renaming ${excludefile} ..."
                            mv ${tempruntime}/${excludefile} ${tempruntime}/${excludefile}.${backupsuffix}
                        else
                            echo " - ${excludefile}: Source and destination are identical."
                            echo "   Renaming not necessary."
                    fi
                else
                    echo " - ${openhabfolder}/${excludefile} does not exist!"
                    echo "   Renaming not necessary."
            fi
        else
            echo " - ${tempruntime}/${excludefile} does not exist!"
            echo "   Nothing to rename."
    fi
done


### copy all files from the runtime folder to the openhab folder
echo ""
echo "Copy all files from ${tempruntime} to ${openhabfolder} ..."
cp -r ${tempruntime}/* ${openhabfolder}

### copy all files from the designer temp folder to the designer folder
echo "Copy all files from ${tempdesigner} to ${designerfolder} ..."
cp -r ${tempdesigner}/* ${designerfolder}

echo ""
echo "All done."

exit 0

#EOF