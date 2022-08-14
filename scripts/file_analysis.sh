#!/usr/bin/env zsh
# ./file_analysis.sh > ../out/gif_stats.tsv
DIR=${0:a:h}
find "$DIR/../gifs" -type f -exec bash -c 'FNAME="$(basename {})"; STATS="$(identify -ping -format "%n %w %h %B\n" {} | head -n 1 | tr " " "\t")"; MD5="$(md5sum {} | cut -d" " -f1)"; printf "%s\t%s\t%s\n" "$FNAME" "$STATS" "$MD5"' \;