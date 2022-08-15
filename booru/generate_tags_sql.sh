#!/usr/bin/env bash
# ./generate_tags_sql.sh > walfie.sql
GENERAL_TAGS="$(jq -r '.[] | [.id, .tag_string_general] | @tsv' processed.json)"
ARTIST_TAGS="$(jq -r '.[] | [.id, .tag_string_artist] | @tsv' processed.json)"
COPYRIGHT_TAGS="$(jq -r '.[] | [.id, .tag_string_copyright] | @tsv' processed.json)"
CHARACTER_TAGS="$(jq -r '.[] | [.id, .tag_string_character] | @tsv' processed.json)"

gawk -F'\t' 'BEGIN {
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

  generic_booru_fr[0] = "GENERAL";
  generic_booru_fr[1] = "ARTIST";

  boorus["danbooru_manual_walfie"] = "";
  boorus["nobooru_manual_walfie"] = "";
  tag_cats[0] = "";
  tag_cats[1] = "";
  tag_cats[3] = "";
  tag_cats[4] = "";
  for (booru in boorus) {
    for (cat in tag_cats) {
      # initialize booru_tags_to_ids[booru][tag_cat] as an array by indexing into it
      booru_tags_to_ids[booru][cat][0];
      # remove the empty string that was inserted by our accessing the nested element
      delete booru_tags_to_ids[booru][cat][0];
    }
  }
}
fname != FILENAME {
  fname = FILENAME;
  idx++;
  if (idx < 4) {
    tag_cat = file_idx_to_tag_cat[idx];
  } else if (idx == 4) {
    tag_cat = -1;
  } else {
    tag_cat = -1;
  }
}
idx < 4 && file_idx_to_tag_cat[idx] == 3 {
  split($2, tags, " ");
  booru_fid_copyright["danbooru_manual_walfie"][$1] = tags[1];
}
function register_tag(tag, booru, fid, cat) {
  # Danbooru .mp4s have tags like aqua_background
  # but we mapped all .mp4s to transparent gifs
  # so we need to strip any mention of a coloured background
  is_background_tag = match(tag, /^(.+)_background$/, bgd_match);
  if (is_background_tag) {
    switch (bgd_match[1]) {
      case "simple":
      case "transparent":
        break;
      default:
        return;
    }
  }
  if (tag in booru_tags_to_ids[booru][cat]) {
    tag_id = booru_tags_to_ids[booru][cat][tag];
  } else {
    tag_id = booru_tag_id[booru]++;
    booru_tags_to_ids[booru][cat][tag] = tag_id;
    booru_tag_ids_to_tags[booru][tag_id] = tag;
  }
  booru_fid_tag_ids[booru][fid][cat][tag_id] = 1;
}
idx < 4 {
  split($2, tags, " ");
  for(i in tags) {
    tag = tags[i];
    register_tag(tag, "danbooru_manual_walfie", $1, tag_cat);
  }
}
idx == 4 {
  split($1, filename_parts, ".");
  fid = filename_parts[1];
  if ($2) {
    booru_fid_to_mapped["danbooru_manual_walfie"][fid] = $2;
    mapped_to_fid[$2] = fid;
    split($2, mapped_filename_parts, ".");
    preferred_extension = mapped_filename_parts[2];
    preferred_filename = $2;
  } else {
    preferred_filename = $1;
    preferred_extension = filename_parts[2];
  }
  booru_fid_to_preferred_filename["danbooru_manual_walfie"][fid] = preferred_filename;
  booru_fid_to_preferred_extension["danbooru_manual_walfie"][fid] = preferred_extension;
}
idx == 5 && FNR <= 71 {
  match($0, /^([^[]*)/, filename_match);
  filename = substr($0, filename_match[1, "start"], filename_match[1, "length"]);

  if (filename in mapped_to_fid) {
    booru = "danbooru_manual_walfie";
    fid = mapped_to_fid[filename];
  } else {
    booru = "nobooru_manual_walfie";
    fid = nobooru_fid++;
    nobooru_filename_to_fid[filename] = fid;
    split(filename, filename_parts, ".");
    extension = filename_parts[2];
    booru_fid_copyright["nobooru_manual_walfie"][fid] = "hololive+nijisanji";
    booru_fid_to_preferred_filename["nobooru_manual_walfie"][fid] = filename;
    booru_fid_to_preferred_extension["nobooru_manual_walfie"][fid] = extension;
  }
  
  tag_cat = 0;

  match($0, /\[GENERAL_PICKN:]([^[]*)/, pickn_match);
  pickn_str = substr($0, pickn_match[1, "start"], pickn_match[1, "length"]);
  split(pickn_str, pickn_arr, "\t");
  for(i in pickn_arr) {
    tag = pickn_arr[i];
    register_tag(tag, booru, fid, tag_cat);
  }
  
  match($0, /\[GENERAL_CRUCIAL:]([^[]*)/, cru_match);
  cru_str = substr($0, cru_match[1, "start"], cru_match[1, "length"]);
  split(cru_str, cru_arr, "\t");
  for(i in cru_arr) {
    tag = cru_arr[i];
    register_tag(tag, booru, fid, tag_cat);
  }

  tag_cat = 4;

  match($0, /\[PROPER_NOUNS:]([^[]*)/, pnoun_match);
  pnoun_str = substr($0, pnoun_match[1, "start"], pnoun_match[1, "length"]);
  split(pnoun_str, pnoun_arr, "\t");
  for(i in pnoun_arr) {
    tag = pnoun_arr[i];
    if (tag == "walfie_(style)") continue;
    register_tag(tag, booru, fid, tag_cat);
  }

  tag_cat = 1;
  register_tag("walfie", booru, fid, tag_cat);
}
function max(x, y) {
  return x > y ? x : y;
}
idx == 6 {
  if ($1 in mapped_to_fid) {
    booru = "danbooru_manual_walfie";
    fid = mapped_to_fid[$1];
  } else if ($1 in nobooru_filename_to_fid) {
    booru = "nobooru_manual_walfie";
    fid = nobooru_filename_to_fid[$1];
  } else {
    next
  }
  booru_fid_frame_count[booru][fid] = $2;
  max_frame_count = max(max_frame_count, $2);
  booru_fid_width[booru][fid] = $3;
  booru_fid_height[booru][fid] = $4;
  booru_fid_filesize[booru][fid] = $5;
  booru_fid_md5[booru][fid] = $6;
}
idx == 7 {
  fid = $1;
  booru = "danbooru_manual_walfie";
  if (!($1 in mapped_to_fid)) {
    booru_fid_md5[booru][fid] = $2;
    booru_fid_filesize[booru][fid] = $3;
    booru_fid_width[booru][fid] = $4;
    booru_fid_height[booru][fid] = $5;
  }
}
END {
  for(booru in booru_fid_tag_ids) {
    print "insert into files (booru, fid, shard, file_name, torr_md5, orig_ext, orig_md5, file_size, width, height, jq, torr_path, tags_copyr, tags_char, tags_artist) values";
    first_file = 1;
    for(fid in booru_fid_tag_ids[booru]) {
      if (!first_file) {
        printf ",\n"
      }
      first_file = 0;
      filename = booru_fid_to_preferred_filename[booru][fid];
      extension = booru_fid_to_preferred_extension[booru][fid];
      md5 = booru_fid_md5[booru][fid];
      file_size = booru_fid_filesize[booru][fid];
      width = booru_fid_width[booru][fid];
      height = booru_fid_height[booru][fid];
      printf "  (\"%s\", %d, \"manual_walfie_0\", \"%s\", \"%s\", \"%s\", \"%s\", %d, %d, %d, 100, \"walfie\", \"hololive+nijisanji\", \"various\", \"walfie\")", booru, fid, filename, md5, extension, md5, file_size, width, height;
    }
    print ";";
    for(fid in booru_fid_tag_ids[booru]) {
      print "insert into tags (booru, fid, tag, tag_id, tag_cat, danb_fr) values";
      is_first = 1;
      for(cat in booru_fid_tag_ids[booru][fid]) {
        for(tag_id in booru_fid_tag_ids[booru][fid][cat]) {
          if (!is_first) {
            printf ",\n"
          }
          is_first = 0;
          tag = booru_tag_ids_to_tags[booru][tag_id];
          danbooru_fr = (cat == 0 || cat == 1) ? generic_booru_fr[cat] : booru_fid_copyright[booru][fid];
          printf "  (\"%s\", %d, \"%s\", %d, %d, \"%s\")", booru, fid, tag, tag_id, cat, danbooru_fr;
        }
      }
      print ";";
    }
  }
  printf "create temp table cnt as with recursive\n\
  cnt_cte(x) as (\n\
     select 0\n\
     union all\n\
     select x+1 from cnt_cte\n\
      limit %d\n\
  )\n\
select x from cnt_cte;\n\
create temp table frame_counts (\n\
  booru text not null,\n\
  fid integer not null,\n\
  frames integer not null,\n\
  primary key(booru, fid)\n\
);\n", max_frame_count;
  for(booru in booru_fid_tag_ids) {
    print "insert into frame_counts (booru, fid, frames) values";
    first_file = 1;
    for(fid in booru_fid_tag_ids[booru]) {
      frame_count = booru_fid_frame_count[booru][fid];
      if (frame_count == 0) {
        continue;
      }
      if (!first_file) {
        printf ",\n"
      }
      first_file = 0;
      printf "  (\"%s\", %d, %d)", booru, fid, frame_count;
    }
    print ";";
  }
  print "create table frames (\n\
  booru text not null,\n\
  fid integer not null,\n\
  frame integer not null,\n\
  primary key(booru, fid, frame)\n\
);\n\
insert into frames (booru, fid, frame)\n\
select f.booru, f.fid, c.x as frame\n\
from frame_counts f\n\
inner join cnt c\n\
  on c.x < f.frames;"
}' <(echo "$GENERAL_TAGS") <(echo "$ARTIST_TAGS") <(echo "$COPYRIGHT_TAGS") <(echo "$CHARACTER_TAGS") <(cat mappings.txt) <(cat ../out/tags.tsv) <(cat ../out/gif_stats.tsv) <(jq -r '.[] | [.id, .md5, .file_size, .image_width, .image_height] | @tsv' ./processed.json) #> manual_walfie_booru_tags.sql