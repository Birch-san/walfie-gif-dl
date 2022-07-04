#!/usr/bin/env zsh
DIR=${0:a:h}

cat "$DIR/../out/general_tags_manual.tsv" \
"$HOME/machine-learning/tokenization/distinct_tags_and_freqs.tsv" | \
awk -F"\t" '{
  counts[$1] += $2;
}
END {
  for(i in counts) {
    count = counts[i];
    print(i "\t" count);
  }
}' | sort > "$HOME/machine-learning/general_tags_plus_manual.tsv"