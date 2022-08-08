#!/usr/bin/env bash
# need to multiply by gif frames

awk 'BEGIN {
  idx=-1;
  print "INSERT INTO files (BOORU, FID, FILE_NAME, TORR_MD5, ORIG_EXT, ORIG_MD5, FILE_SIZE, IMG_SIZE_TORR, JQ, TORR_PATH, TAGS_COPYR, TAGS_CHAR, TAGS_ARTIST) VALUES";
}
fname != FILENAME {
  fname = FILENAME;
  idx++;
  if (idx == 0) {
    FS=" ";
  } else {
    FS="\t";
  }
}
idx == 0 {
  split($1, filename_parts, ".");
  fid = filename_parts[1];
  mapped_filename = $2 ? $2 : $1;
  fid_to_mapped[fid] = mapped_filename;
  split(mapped_filename, mapped_filename_parts, ".");
  fid_to_extension[fid] = mapped_filename_parts[2];
}
idx == 1 && FNR > 1 { printf ",\n" }
idx == 1 {
  # JQ (JPEG quality) will just be 100 I suppose
  printf "  (\"danbooru_manual_walfie\", %d, \"%s\", \"%s\", \"%s\", \"%s\", %d, \"%dx%d\", 100, \"walfie\", \"hololive+nijisanji\", \"various\", \"walfie\")", $1, fid_to_mapped[$1], $2, fid_to_extension[$1], $2, $3, $4, $5;
}
END { print ";"; }' <(cat mappings.txt) <(jq -r '.[] | [.id, .md5, .file_size, .image_width, .image_height] | @tsv' ./processed.json) # > manual_walfie_booru_files.sql