#!/usr/bin/env bash
# TWEET_IDS="$(jq -r '. | map(.source) | .[]' ./posts.json | awk -F'/' '/https:\/\/twitter.com\/walfieee\/status\// { if (subsequent) { printf(","); } else { subsequent=1 } printf("%s", $6) } END { $0=""; print '' }')"
# TWEET_URLS="$(jq -r '. | map(.source) | map(select(. | test("^https://twitter.com/walfieee/status/\\d+$"))) | .[]' ./posts.json)"
# jq -r '. | map(select(.source | test("^https://twitter.com/walfieee/status/\\d+$"))) | map({id, source, large_file_url, image_width, image_height, md5, tag_string, file_size, tag_string_general, tag_string_character, tag_string_copyright, tag_string_artist, tag_string_meta, file_ext})' ./posts.json > processed.json


jq -r '[4273591, 4293409, 4293432, 4354181, 5059826] as $denylist | . | map(select((.source | test("^https://twitter.com/walfieee/status/\\d+$")) and (.id as $in | $denylist | index($in) | not))) | map({id, source, large_file_url, image_width, image_height, md5, tag_string, file_size, tag_string_general, tag_string_character, tag_string_copyright, tag_string_artist, tag_string_meta, file_ext })' ./posts.json > processed.json

# jq -r '. | map(.source) | .[]' ./posts.json | awk -F'/' '/https:\/\/twitter.com\/walfieee\/status\// { print $6 }'
# TWEET_URL="$(jq --raw '.[0].source' ./posts.json)"

# looks like we won't be able to get anything other than the mp4
# we can use youtube-dl to get every mp4.
# we can extract frames with ffmpeg.
# there's few enough that we could manually correlate these with the gifs we already have.

# remember that for now we only need the captions.

# we may have gifs that are outside of this set.
# we have manual captions for some.

# curl \
# -H "Authorization: Bearer $TWITTER_BEARER_TOKEN" \
# "https://api.twitter.com/2/tweets/1524622734449332224?tweet.fields=attachments"