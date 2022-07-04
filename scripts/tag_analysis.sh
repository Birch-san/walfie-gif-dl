#!/usr/bin/env zsh
DIR=${0:a:h}
# tags, freq
gawk '{
	match($0, /\[GENERAL_PICKN:]([^[]*)/, pickn_match);
  pickn_str = substr($0, pickn_match[1, "start"], pickn_match[1, "length"]);
  split(pickn_str, pickn_arr, "\t");
  for(i in pickn_arr) {
  	picked = pickn_arr[i];
  	counts[picked]++;
  }

  match($0, /\[GENERAL_CRUCIAL:]([^[]*)/, cru_match);
  cru_str = substr($0, cru_match[1, "start"], cru_match[1, "length"]);
  split(cru_str, cru_arr, "\t");
  for(i in cru_arr) {
  	picked = cru_arr[i];
  	counts[picked]++;
  }
}
END {
	for(i in counts) {
  	count = counts[i];
  	print(i "\t" count);
	}
}' "$DIR/../out/tags.tsv"