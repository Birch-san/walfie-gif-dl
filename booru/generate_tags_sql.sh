#!/usr/bin/env bash
# need to multiply by gif frames
GENERAL_TAGS="$(jq -r '.[] | [.id, .tag_string_general] | @tsv' processed.json)"
ARTIST_TAGS="$(jq -r '.[] | [.id, .tag_string_artist] | @tsv' processed.json)"
COPYRIGHT_TAGS="$(jq -r '.[] | [.id, .tag_string_copyright] | @tsv' processed.json)"
CHARACTER_TAGS="$(jq -r '.[] | [.id, .tag_string_character] | @tsv' processed.json)"

awk -F'\t' 'BEGIN {
  # GENERAL = TAG_CAT 0
  file_idx_to_tag_cat[0] = 0;
  # ARTIST = TAG_CAT 1
  file_idx_to_tag_cat[1] = 1;
  # (there is no TAG_CAT 2 in booru-chars, so we will not use it either)
  # COPYRIGHT = TAG_CAT 3
  file_idx_to_tag_cat[2] = 3;
  # CHARACTER = TAG_CAT 4
  file_idx_to_tag_cat[3] = 4;

  OFS=" ";
  idx=-1;
  registry_tag_id=0;

  generic_booru_fr[0] = "GENERAL";
  generic_booru_fr[1] = "ARTIST";
}
fname != FILENAME {
  fname = FILENAME;
  idx++;
  tag_cat = file_idx_to_tag_cat[idx];
  # initialize tags_to_ids[tag_cat] as an array by indexing into it
  tags_to_ids[tag_cat][0];
  # remove the empty string that was inserted by our accessing the nested element
  delete tags_to_ids[tag_cat][0];
}
file_idx_to_tag_cat[idx] == 3 {
  split($2, tags, " ");
  fid_copyright[$1] = tags[1];
}
{
  split($2, tags, " ");
  fid_tag_ix = 0;
  for(i in tags) {
    tag = tags[i];
    if (tag in tags_to_ids[tag_cat]) {
      tag_id = tags_to_ids[tag_cat][tag];
    } else {
      tag_id = registry_tag_id++;
      tags_to_ids[tag_cat][tag] = tag_id;
      tag_ids_to_cats[tag_id] = tag_cat;
      tag_ids_to_tags[tag_id] = tag;
    }
    fid_tag_ids[$1][tag_cat][fid_tag_ix++] = tag_id;
  }
}
END {
  for(fid in fid_tag_ids) {
    print "INSERT INTO tags (BOORU, FID, TAG, TAG_ID, TAG_CAT, DANB_FR) VALUES";
    is_first = 1;
    for(cat in fid_tag_ids[fid]) {
      for(tag_ix in fid_tag_ids[fid][cat]) {
        if (!is_first) {
          printf ",\n"
        }
        is_first = 0;
        tag_id = fid_tag_ids[fid][cat][tag_ix];
        tag = tag_ids_to_tags[tag_id];
        tag_cat = tag_ids_to_cats[tag_id];
        danbooru_fr = (tag_cat == 0 || tag_cat == 1) ? generic_booru_fr[tag_cat] : fid_copyright[fid];
        # print(fid, tag_ids_to_cats[tag_id], tag_id, tag_ids_to_tags[tag_id]);
        printf "  (\"danbooru_manual_walfie\", %d, \"%s\", %d, \"%s\")", fid, tag, tag_cat, danbooru_fr;
      }
    }
    print ";";
  }
}' <(echo "$GENERAL_TAGS") <(echo "$ARTIST_TAGS") <(echo "$COPYRIGHT_TAGS") <(echo "$CHARACTER_TAGS") #> manual_walfie_booru_tags.sql