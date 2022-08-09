#!/usr/bin/env bash
# need to multiply by gif frames
GENERAL_TAGS="$(jq -r '.[] | [.id, .tag_string_general] | @tsv' processed.json)"
ARTIST_TAGS="$(jq -r '.[] | [.id, .tag_string_artist] | @tsv' processed.json)"
COPYRIGHT_TAGS="$(jq -r '.[] | [.id, .tag_string_copyright] | @tsv' processed.json)"
CHARACTER_TAGS="$(jq -r '.[] | [.id, .tag_string_character] | @tsv' processed.json)"

gawk 'BEGIN {
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
  if (idx < 4) {
    FS="\t";
    tag_cat = file_idx_to_tag_cat[idx];

    # initialize tags_to_ids[tag_cat] as an array by indexing into it
    tags_to_ids[tag_cat][0];
    # remove the empty string that was inserted by our accessing the nested element
    delete tags_to_ids[tag_cat][0];
  } else if (idx == 4) {
    FS=" ";
    tag_cat = -1;
  } else {
    FS="\t";
    tag_cat = -1;
  }
}
idx < 4 && file_idx_to_tag_cat[idx] == 3 {
  split($2, tags, " ");
  fid_copyright[$1] = tags[1];
}
idx < 4 {
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
idx == 4 {
  if ($2) {
    split($1, filename_parts, ".");
    fid = filename_parts[1];
    fid_to_mapped[fid] = $2;
    mapped_to_fid[$2] = fid;
  }
}
idx == 5 && FNR <= 71 {
  match($0, /^([^[]*)/, filename_match);
  filename = substr($0, filename_match[1, "start"], filename_match[1, "length"]);

  # if (filename in mapped_to_fid) {
  #   
  # }
  # 
  # match($0, /\[GENERAL_PICKN:]([^[]*)/, pickn_match);
  # pickn_str = substr($0, pickn_match[1, "start"], pickn_match[1, "length"]);
  # split(pickn_str, pickn_arr, "\t");
  # for(i in pickn_arr) {
  #   picked = pickn_arr[i];
  #   counts[picked]++;
  # }
  #
  # match($0, /\[GENERAL_CRUCIAL:]([^[]*)/, cru_match);
  # cru_str = substr($0, cru_match[1, "start"], cru_match[1, "length"]);
  # split(cru_str, cru_arr, "\t");
  # for(i in cru_arr) {
  #   picked = cru_arr[i];
  #   counts[picked]++;
  # }
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
  # for (fid in fid_to_mapped) {
  #   print "fid", fid, "->", fid_to_mapped[fid];
  # }
  # for (mapped in mapped_to_fid) {
  #   print "mapped", mapped, "->", mapped_to_fid[mapped];
  # }
}' <(echo "$GENERAL_TAGS") <(echo "$ARTIST_TAGS") <(echo "$COPYRIGHT_TAGS") <(echo "$CHARACTER_TAGS") <(cat mappings.txt) <(cat ../out/tags.tsv) #> manual_walfie_booru_tags.sql