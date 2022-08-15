#!/usr/bin/env zsh
find ./out_seq -type f -name '*.gif' -exec bash -c 'BASENAME="$(basename {})" && LEAFNAME="${BASENAME%.*}" && convert -coalesce {} "$(dirname {})"/"$LEAFNAME.%d.png"' \;