# xteve, guide2go in one docker with cron

docker runs in host mode \
access xteve webui ip:34400/web/

after docker start check your config folder and do your setups, setup is persistent, start from scratch by delete them

cron and xteve start options are updated on docker restart.

mounts to use as sample \
Container Path: /root/.xteve <> /mnt/user/appdata/xteve/ \
Container Path: /config <> /mnt/user/appdata/xteve/_config/ \
Container Path: /guide2go <> /mnt/user/appdata/xteve/_guide2go/ \
Container Path: /tmp/xteve <> /tmp/xteve/ \
Container Path: /TVH <> /mnt/user/appdata/tvheadend/data/ << not needed if no TVHeadend is used \
while /mnt/user/appdata/ should fit to your system path ...

setup guide2go SD subscrition as follows or copy your existing .json files into your mounted /guide2go folder \
docker exec -it "dockername" guide2go -configure /guide2go/"your_epg_name".json

to test the cronjob functions \
docker exec -it "dockername" ./config/cronjob.sh

included functions are (all can be individual turned on / off)

xteve - iptv and epg proxy server for plex, emby, etc ... thanks to @marmei \
website: http://xteve.de \
Discord: https://discordapp.com/channels/465222357754314767/465222357754314773

guide2go - xmltv epg grabber for schedules direct, thanks to @marmei \
github: https://github.com/mar-mei/guide2go \
Schedules Direct web: http://www.schedulesdirect.org/

some small script lines cause i personally use tvheadend and get playlist for xteve and cp xml data to tvheadend

so, credits to the programmers, i just putted this together in a docker to fit my needs
