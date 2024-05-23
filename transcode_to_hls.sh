#!/bin/bash

check_input() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 input_file"
        exit 1
    fi

    INPUT_FILE="$1"

    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: Input file '$INPUT_FILE' not found."
        exit 1
    fi

    FILE_SIZE=$(stat -c%s "$INPUT_FILE")
    MAX_SIZE=$((500 * 1024 * 1024))

    if [ "$FILE_SIZE" -ge "$MAX_SIZE" ]; then
        echo "Error: Input file size is greater than 500MB."
        exit 1
    fi

    VIDEO_INFO=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$INPUT_FILE")
    INPUT_WIDTH=$(echo $VIDEO_INFO | cut -d'x' -f1)
    INPUT_HEIGHT=$(echo $VIDEO_INFO | cut -d'x' -f2)
}

setup_output_directory() {
    OUTPUT_DIR="${INPUT_FILE%.*}_transcoded"
    mkdir -p "$OUTPUT_DIR"
}

add_resolution() {
    local width=$1
    local height=$2
    local bitrate=$3

    if [ "$INPUT_HEIGHT" -ge "$height" ]; then
        FILTER_COMPLEX+="[0:v]scale=w=$width:h=$height[v${height}out]; "
        MAP_ARGS+="-map [v${height}out] -c:v libx264 -b:v ${bitrate}k -g 48 -sc_threshold 0 -hls_time 6 -hls_playlist_type vod -hls_segment_filename $OUTPUT_DIR/${height}p_%03d.ts -f hls $OUTPUT_DIR/${height}p.m3u8 "
        MASTER_PLAYLIST+="#EXT-X-STREAM-INF:BANDWIDTH=${bitrate}000,RESOLUTION=${width}x${height}\n${height}p.m3u8\n"
    fi
}

transcode_video() {
    FFMPEG_CMD="ffmpeg -i \"$INPUT_FILE\" -filter_complex \""
    if [ "$INPUT_HEIGHT" -ge 720 ]; then
        FFMPEG_CMD+="[0:v]split=4[v240][v360][v480][v720]; [v240]scale=w=426:h=240[v240out]; [v360]scale=w=640:h=360[v360out]; [v480]scale=w=854:h=480[v480out]; [v720]scale=w=1280:h=720[v720out]\" "
    elif [ "$INPUT_HEIGHT" -ge 480 ]; then
        FFMPEG_CMD+="[0:v]split=3[v240][v360][v480]; [v240]scale=w=426:h=240[v240out]; [v360]scale=w=640:h=360[v360out]; [v480]scale=w=854:h=480[v480out]\" "
    elif [ "$INPUT_HEIGHT" -ge 360 ]; then
        FFMPEG_CMD+="[0:v]split=2[v240][v360]; [v240]scale=w=426:h=240[v240out]; [v360]scale=w=640:h=360[v360out]\" "
    elif [ "$INPUT_HEIGHT" -ge 240 ]; then
        FFMPEG_CMD+="[0:v]split=1[v240]; [v240]scale=w=426:h=240[v240out]\" "
    fi

    FFMPEG_CMD+="$MAP_ARGS -map a:0 -c:a aac -b:a 128k -ac 2 -hls_time 6 -hls_playlist_type vod -f hls -hls_segment_filename \"$OUTPUT_DIR/audio_%03d.ts\" \"$OUTPUT_DIR/audio.m3u8\""
    echo "Executing command: $FFMPEG_CMD"
    eval $FFMPEG_CMD

    if [ $? -ne 0 ]; then
        echo "Error: ffmpeg transcoding failed."
        exit 1
    fi
}

create_master_playlist() {
    echo -e "$MASTER_PLAYLIST" > "$OUTPUT_DIR/master.m3u8"
    echo "Transcoding completed. Output files are stored in: $OUTPUT_DIR"
}

main() {
    check_input "$@"
    setup_output_directory

    FILTER_COMPLEX=""
    MAP_ARGS=""
    MASTER_PLAYLIST="#EXTM3U\n#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"audio\",NAME=\"English\",DEFAULT=YES,AUTOSELECT=YES,URI=\"audio.m3u8\"\n"

    add_resolution 426 240 800
    add_resolution 640 360 1200
    add_resolution 854 480 2000
    add_resolution 1280 720 3000

    transcode_video
    create_master_playlist
}

main "$@"
