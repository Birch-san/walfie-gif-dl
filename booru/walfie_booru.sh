#!/usr/bin/env bash
source ./env.sh
echo $BOORU_USERNAME
curl -Ss \
-u "$BOORU_USERNAME:$BOORU_TOKEN" \
"https://danbooru.donmai.us/posts.json?tags=walfie&limit=100" > posts.json