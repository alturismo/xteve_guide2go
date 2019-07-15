#!/bin/sh

##### Config

use_guide2go="yes"
use_xTeveAPI="yes"
use_TVH_Play="no"
use_TVH_move="no"

### List of created lineup json files in /guide2go
# sample with 3 jsons lineups
JsonList="CBLguide.json SATguide.json SATSport.json"

### to create your lineups do as follows and follow the instructions
# docker exec -it <yourdockername> guide2go -configure /guide2go/<lineupnamehere>.json

### xTeve ip, Port in case API is used to update XEPG
xTeveIP="192.168.1.2"
xTevePORT="34400"

### TVHeadend ip, Port in case m3u Playlist is wanted
TVHIP="192.168.1.2"
TVHPORT="9981"
TVHUSER="username"
TVHPASS="password"
TVHOUT="/root/.xteve/data/channels.m3u"

### Copy a final xml (sample xteve) to tvheadend Data ### u have to mount TVHPATH data dir
TVHSOURCE="/root/.xteve/data/xteve.xml"
TVHPATH="/TVH"

# cronjob, check sample_cron.txt with an editor to adjust time

### END Config
##
#

# run guide2go in loop
if [ "$use_guide2go" = "yes" ]; then
	for jsons in $JsonList
		do
		jsonefile="${jsons%.*}"
		filecache='  "file.cache": "/guide2go/cache_'$jsons'",'
		fileoutput='  "file.output": "/guide2go/'$jsonefile'.xml",'
		sed -i "/file.cache/c $filecache" /guide2go/$jsons
		sed -i "/file.output/c $fileoutput" /guide2go/$jsons
		guide2go -config /guide2go/$jsons
	done
fi

sleep 1

# get TVH playlist
if [ "$use_TVH_Play" = "yes" ]; then
	if [ -z "$TVHIP" ]; then
		echo "no TVHeadend credentials"
	else
		if [ -z "$TVHUSER" ]; then
			wget -O $TVHOUT http://$TVHIP:$TVHPORT/playlist
		else
			wget -O $TVHOUT http://$TVHUSER:$TVHPASS@$TVHIP:$TVHPORT/playlist
		fi
	fi
fi

sleep 1

# update xteve via API
if [ "$use_xTeveAPI" = "yes" ]; then
	if [ -z "$xTeveIP" ]; then
		echo "no xTeve credentials"
	else
		curl -X POST -d '{"cmd":"update.xmltv"}' http://$xTeveIP:$xTevePORT/api/
		sleep 1
		curl -X POST -d '{"cmd":"update.xepg"}' http://$xTeveIP:$xTevePORT/api/
		sleep 1
	fi
fi

# copy file to TVHeadend
if [ "$use_TVH_move" = "yes" ]; then
	if [ -z "$TVHPATH" ]; then
		echo "no Path credential"
	else
		cp $TVHSOURCE $TVHPATH/guide.xml
	fi
fi

exit
