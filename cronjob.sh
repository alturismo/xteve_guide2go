#!/bin/sh

##### Config

use_guide2go="yes"		# xml grabber for SD
use_guide2goproxy="no"		# yes enables proxy functions for images, EITHER use_guide2goproxy OR use_guide2gocache
use_guide2gocache="yes"		# yes enables proxy functions for images while caching them local
use_guide2goclean="yes"		# yes checks xml's and will cleanup "old" images, only useful use_guide2gocache=yes ...
use_xTeveAPI="yes"		# yes enables API update calls after each xml update, may disable xteve's update schedule in webui
use_embyAPI="no"		# yes enables emby API call to update EPG after each xml update
use_plexAPI="yes"		# yes enables plex API call to update EPG after each xml update
use_TVH_Play="no"		# yes will fetch the playlist from tvheadend after each run to keep updated.
use_TVH_move="yes"		# yes will copy the xml to tvheadend's data dir for easy import, consider proper mount's

### List of created lineup json files in /guide2go
# sample with 3 yaml lineups, adjust to yours
JsonList="CBLguide.yaml SATguide.yaml SATSport.yaml"

# Hostname or ip and port where proxy is reachable from clients, default port 8080, seperated from xteve.
guide2gohost="xteve"
guide2goport="8080"
# if guide2gocache is active, disable guide2goproxy (no) or vice vers
images_path='/guide2go/images/'

### to create your lineups do as follows and follow the instructions
# docker exec -it <yourdockername> guide2go -configure /guide2go/<lineupnamehere>.json

### xTeve ip, Port in case API is used to update XEPG
xTeveIP="192.168.1.2"
xTevePORT="34400"

### setup rewrite rule für Reverse Proxy https xml usage
# the rewritten url will be then http://yourxtevedomain.de/xmltv/xteverp.xml
xtevelocal="http://192.168.1.67:34400"
xteveRP="https://xteve.mydomain.de"
xtevelocalfile="/root/.xteve/data/xteve.xml"
xteveRPfile="/root/.xteve/data/xteverp.xml"
# if wished, a ready RP m3u file generator, url will be http://yourxtevedomain.de/xmltv/xteverp.m3u
xtevelocalm3ufile="/root/.xteve/data/xteve.m3u"
xteveRPm3ufile="/root/.xteve/data/xteverp.m3u"

### Emby ip, Port, apiKey, update ID in case API is used to update EPG directly after guide2go
# ONLY when xteve API is in use, otherwise obsolete
# API Key, https://github.com/MediaBrowser/Emby/wiki/Api-Key-Authentication
# embyID, settings, scroll down click API, Scheduled Task Service, GET /ScheduledTasks, Try, Execute, look for "Refresh Guide" ID, sample here 9492d30c70f7f1bec3757c9d0a4feb45
embyIP="192.168.1.2"
embyPORT="8096"
embyApiKey=""
embyID="9492d30c70balblac9d0a4feb45"

### Plex ip, Port, Token, TV Section ID in case API is used to update EPG directly after guide2go
# ONLY when xteve API is in use, otherwise obsolete
# Plex Token, https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/
# plexID, http://YOUR_IP_HERE:32400/?X-Plex-Token=YOUR_TOKEN_HERE , look for "tv.plex.providers.epg.xmltv:  ", sample here 11
plexIP="192.168.1.2"
plexPORT="32400"
plexToken="yourtokenhere"
plexID="11"

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

f [ "$use_guide2go" = "yes" ]; then
	for jsons in $JsonList
		do
		pkill guide2go
		jsonefile="${jsons%.*}"
		filecache='Cache: /guide2go/'$jsonefile'_cache.json'
		fileoutput='XMLTV: /guide2go/'$jsonefile'.xml'
		hostoutput='Hostname: '$guide2gohost':'$guide2goport''
		sed -i "/  Cache/c \    $filecache" /guide2go/$jsons
		sed -i "/XMLTV/c \    $fileoutput" /guide2go/$jsons
		sed -i "/Hostname/c \    $hostoutput" /guide2go/$jsons
		sleep 1
		if [ "$use_guide2goproxy" = "yes" ]; then
			guide2goproxy='Proxy Images: true'
			sed -i "/Proxy/c \    $guide2goproxy" /guide2go/$jsons
		else
			guide2goproxy='Proxy Images: false'
			sed -i "/Proxy/c \    $guide2goproxy" /guide2go/$jsons
		fi
		if [ "$use_guide2gocache" = "yes" ]; then
			guide2gocache='Local Images Cache: true'
			sed -i "/Local/c \    $guide2gocache" /guide2go/$jsons
			sed -i "/  Images/c \    Images Path: $images_path" /guide2go/$jsons
		else
			guide2gocache='Local Images Cache: false'
			sed -i "/Local/c \    $guide2gocache" /guide2go/$jsons
		fi
		sleep 1
		guide2go -config /guide2go/$jsons &
		while ! nc -z localhost $guide2goport; do
			sleep 5
		done
		echo "jump to next config.yaml"
	done
	echo "done and g2g started listening"
fi

sleep 1

# cleanup image Dir
if [ "$use_guide2goclean" = "yes" ]; then
        cat /guide2go/*.xml | grep -i $guide2gohost:$guide2goport | sed 's/.*images\///' | cut -f1 -d'"' | sort | uniq > /guide2go/listimages
        sleep 1
        find $images_path -type f \( ! -name "/guide2go/listimages" $(printf ' -a ! -name %s\n' $(< /guide2go/listimages)) \) -exec rm {} +
fi

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

# create rewritten xml and m3u file
if [ "$use_xTeveRP" = "yes" ]; then
	if [ -z "$xteveRPfile" ]; then
		echo "no Path credential"
	else
		sleep 10
		cp $xtevelocalfile $xteveRPfile
		sed -i "s;$xtevelocal;$xteveRP;g" $xteveRPfile
		sleep 2
		gzip -kf $xteveRPfile
	fi
	if [ -z "$xteveRPm3ufile" ]; then
		echo "no Path credential"
	else
		cp $xtevelocalm3ufile $xteveRPm3ufile
		sed -i "s;$xtevelocal;$xteveRP;g" $xteveRPm3ufile
	fi
fi

# update Emby via API
if [ "$use_embyAPI" = "yes" ]; then
	if [ -z "$embyIP" ]; then
		echo "no Emby credentials"
	else
		curl -X POST "http://$embyIP:$embyPORT/emby/ScheduledTasks/Running/$embyID?api_key=$embyApiKey" -H "accept: */*" -d ""
		sleep 1
	fi
fi

# update Plex via API
if [ "$use_plexAPI" = "yes" ]; then
	if [ -z "$plexIP" ]; then
		echo "no Plex credentials"
	else
		curl -s "http://$plexIP:$plexPORT/livetv/dvrs/$plexID/reloadGuide?X-Plex-Product=Plex%20Web&X-Plex-Version=4.8.4&X-Plex-Client-Identifier=$plexToken&X-Plex-Platform=Firefox&X-Plex-Platform-Version=69.0&X-Plex-Sync-Version=2&X-Plex-Features=external-media&X-Plex-Model=bundled&X-Plex-Device=Linux&X-Plex-Device-Name=Firefox&X-Plex-Device-Screen-Resolution=1128x657%2C1128x752&X-Plex-Language=de" -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:69.0) Gecko/20100101 Firefox/69.0" -H "Accept: text/plain, */*; q=0.01" -H "Accept-Language: de" --compressed -H "X-Requested-With: XMLHttpRequest" -H "Connection: keep-alive" -H "Referer: http://$plexIP:$plexPORT/web/index.html" --data ""
		sleep 1
	fi
fi

chown -R 99:100 /root/.xteve

exit
