#!/bin/bash

ffprobe -v error -select_streams v:0 -show_entries \
stream=codec_name,codec_long_name,codec_type:stream_tags=ENCODER \
-of default=noprint_wrappers=1:nokey=1 SampleVideo_1280x720_10mb_transcoded_libopenh264/240p_000.ts
ffprobe -v error -select_streams v:0 -show_entries \
stream=codec_name,codec_long_name,codec_type:stream_tags=ENCODER \
-of default=noprint_wrappers=1:nokey=1 SampleVideo_1280x720_10mb_transcoded_libopenh264/360p_000.ts
ffprobe -v error -select_streams v:0 -show_entries \
stream=codec_name,codec_long_name,codec_type:stream_tags=ENCODER \
-of default=noprint_wrappers=1:nokey=1 SampleVideo_1280x720_10mb_transcoded_libopenh264/480p_000.ts
ffprobe -v error -select_streams v:0 -show_entries \
stream=codec_name,codec_long_name,codec_type:stream_tags=ENCODER \
-of default=noprint_wrappers=1:nokey=1 SampleVideo_1280x720_10mb_transcoded_libopenh264/720p_000.ts
