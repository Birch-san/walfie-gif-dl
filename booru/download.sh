#!/usr/bin/env bash
# ./download.sh | xargs -n 3 wget

# jq -r '.[] | [.id, .file_ext, .large_file_url] | join(" ")' ./processed.json
# jq -r '.[] | sprintf("%s", .id)' ./processed.json
jq -r '.[] | [.large_file_url, "-O", "out/" + (.id|tostring) + "." + .file_ext] | @sh' ./processed.json