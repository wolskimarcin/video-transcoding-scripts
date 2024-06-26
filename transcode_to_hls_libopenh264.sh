#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 input_file"
    exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

OUTPUT_DIR="${INPUT_FILE%.*}_transcoded_libopenh264"

mkdir -p "$OUTPUT_DIR"

# Transcoding to HLS with different resolutions
ffmpeg -i $INPUT_FILE \
  -filter_complex " \
  [0:v]split=4[v240][v360][v480][v720]; \
  [v240]scale=w=426:h=240[v240out]; \
  [v360]scale=w=640:h=360[v360out]; \
  [v480]scale=w=854:h=480[v480out]; \
  [v720]scale=w=1280:h=720[v720out]" \
  -map "[v240out]" -c:v libopenh264 -metadata:s:v encoder="libopenh264" -b:v 800k -g 48 -sc_threshold 0 -hls_time 6 -hls_segment_filename "$OUTPUT_DIR/240p_%03d.ts" -hls_playlist_type vod "$OUTPUT_DIR/240p.m3u8" \
  -map "[v360out]" -c:v libopenh264 -metadata:s:v encoder="libopenh264" -b:v 1200k -g 48 -sc_threshold 0 -hls_time 6 -hls_segment_filename "$OUTPUT_DIR/360p_%03d.ts" -hls_playlist_type vod "$OUTPUT_DIR/360p.m3u8" \
  -map "[v480out]" -c:v libopenh264 -metadata:s:v encoder="libopenh264" -b:v 2000k -g 48 -sc_threshold 0 -hls_time 6 -hls_segment_filename "$OUTPUT_DIR/480p_%03d.ts" -hls_playlist_type vod "$OUTPUT_DIR/480p.m3u8" \
  -map "[v720out]" -c:v libopenh264 -metadata:s:v encoder="libopenh264" -b:v 3000k -g 48 -sc_threshold 0 -hls_time 6 -hls_segment_filename "$OUTPUT_DIR/720p_%03d.ts" -hls_playlist_type vod "$OUTPUT_DIR/720p.m3u8" \
  -map a:0 -c:a aac -b:a 128k -ac 2 -hls_time 6 -hls_segment_filename "$OUTPUT_DIR/audio_%03d.ts" -hls_playlist_type vod "$OUTPUT_DIR/audio.m3u8"

if [ $? -ne 0 ]; then
    echo "Error: ffmpeg transcoding failed."
    exit 1
fi

# Create the master playlist
echo "#EXTM3U" > $OUTPUT_DIR/master.m3u8
echo "#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"audio\",NAME=\"English\",DEFAULT=YES,AUTOSELECT=YES,URI=\"audio.m3u8\"" >> $OUTPUT_DIR/master.m3u8
echo "#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=426x240" >> $OUTPUT_DIR/master.m3u8
echo "240p.m3u8" >> $OUTPUT_DIR/master.m3u8
echo "#EXT-X-STREAM-INF:BANDWIDTH=1200000,RESOLUTION=640x360" >> $OUTPUT_DIR/master.m3u8
echo "360p.m3u8" >> $OUTPUT_DIR/master.m3u8
echo "#EXT-X-STREAM-INF:BANDWIDTH=2000000,RESOLUTION=854x480" >> $OUTPUT_DIR/master.m3u8
echo "480p.m3u8" >> $OUTPUT_DIR/master.m3u8
echo "#EXT-X-STREAM-INF:BANDWIDTH=3000000,RESOLUTION=1280x720" >> $OUTPUT_DIR/master.m3u8
echo "720p.m3u8" >> $OUTPUT_DIR/master.m3u8

echo "Transcoding completed. Output files are stored in: $OUTPUT_DIR"