#!/usr/bin/env zsh
find ./gifs -type file -name '*.gif' -exec zsh -c 'identify -format "%n\n" {} | head -1 | xargs -0 printf "$(basename {})\t%s"' \;