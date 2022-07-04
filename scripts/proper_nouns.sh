#!/usr/bin/env zsh
DIR=${0:a:h}
# tags, freq
gawk '{
  match($0, /\[PROPER_NOUNS:](.*)$/, pickn_match);
  pickn_str = substr($0, pickn_match[1, "start"], pickn_match[1, "length"]);
  split(pickn_str, pickn_arr, "\t");
  for(i in pickn_arr) {
    picked = pickn_arr[i];
    counts[picked]++;
  }
}
END {
  for(i in counts) {
    count = counts[i];
    print(i "\t" count);
  }
}' "$DIR/../out/tags.tsv"