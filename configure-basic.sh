#!/usr/bin/env bash
# This script runs the most basic part of the XNAT docker compose configuration,
# which is required to run a demo XNAT instance with 'docker-compose -f docker-compose.yml up -d'
#
# Author: Tom Close (tom.close@monash.edu)

set -e

# Change to the directory where the configure file is
pushd $(dirname $0)

echo ""
echo "##########################################"
echo " Docker-compose XNAT Configuration Script"
echo "##########################################"
echo ""


if [ -f '.env' ]; then
    # Load previously saved configuration variables
    source .env
else
    echo "No existing configuration found at '$(pwd)/.env'"
fi

echo ""
echo "------------------------------------------------------------"
echo " Configuring log directories in $(pwd)/logs"
echo "------------------------------------------------------------"

mkdir -p ./logs/tomcat
mkdir -p ./logs/xnat

echo ""
echo "---------------------------"
echo " Downloading XNAT WAR file"
echo "---------------------------"

mkdir -p ./webapps

if [ -z "$XNAT_VER" ]; then
    read -p 'Please enter version of XNAT to download and install [1.7.5.6] (XNAT_VER): ' XNAT_VER
    if [ -z "$XNAT_VER" ]; then
        XNAT_VER=1.7.5.6
    fi
else
    echo "Loaded saved value for XNAT_VER=$XNAT_VER"
fi

# Download requested XNAT web version
mkdir -p downloads
WEBAPP_DOWNLOAD=./downloads/$XNAT_VER.war

if [ ! -f "$WEBAPP_DOWNLOAD" ]; then
    wget https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VER}.war 
    mv xnat-web-${XNAT_VER}.war $WEBAPP_DOWNLOAD
else
    echo "Skipping download of $WEBAPP_DOWNLOAD as it has already been downloaded"
fi

# Clear out existing webapps and add link to new webapp
sudo rm -r ./webapps
mkdir -p ./webapps
cp $WEBAPP_DOWNLOAD ./webapps/ROOT.war

echo "Moved v$XNAT_VER WAR file to '$(pwd)/webapps/ROOT.war', to upgrade to a later version of XNAT simply replace it with a new WAR file"
echo ""

echo ""
echo "----------------------------"
echo " Downloading useful plugins"
echo "----------------------------"

mkdir -p ./plugins

CONTAINER_SERVICE_PLUGIN_VER=2.1.0
SIMPLE_UPLOAD_PLUGIN_VER=2.04

# Container service plugin
if [ ! -f ./plugins/container-service-plugin.jar ]; then
    echo "Downloading container service plugin"
    pushd downloads
    wget https://github.com/NrgXnat/container-service/releases/download/$CONTAINER_SERVICE_PLUGIN_VER/containers-$CONTAINER_SERVICE_PLUGIN_VER-fat.jar
    popd
    mv ./downloads/containers-$CONTAINER_SERVICE_PLUGIN_VER-fat.jar ./plugins/container-service-plugin.jar
else
    echo "Skipping download of the Container Service plugin as it is already present at $(pwd)/plugins/container-service-plugin.jar"
fi


# Simple upload plugin
if [ ! -f ./plugins/simple-upload-plugin.jar ]; then
    echo "Downloading simple upload plugin (for non-DICOM uploads)"
    pushd downloads
    # Need to fix up the version number of the plugin that is uploaded in the release
    wget https://github.com/MonashBI/xnat-simple-upload-plugin/releases/download/feature_release$SIMPLE_UPLOAD_PLUGIN_VER/xnat-simple-upload-plugin-2.0.0.jar
    popd
    mv ./downloads/xnat-simple-upload-plugin-2.0.0.jar ./plugins/simple-upload-plugin.jar
else
    echo "Skipping download of the \"simple upload\" plugin as it is already present at $(pwd)/plugins/simple-upload-plugin.jar"
fi

# QC pipeline
# docker pull manishkumr/xnat-qc-pipeline

popd
