#!/usr/bin/env zsh
sqlite3 -batch ../out/test.db <<'SQL'
.mode tabs
.import '|awk "BEGIN { OFS=\"\t\" } ! /\"/ { print \"hey\", \$0; }" ../out/gif_stats.tsv' x
SQL