import os
import sys
import subprocess

def check_input(args):
    if len(args) == 0:
        print(f"Usage: {sys.argv[0]} input_file")
        sys.exit(1)

    input_file = args[0]

    if not os.path.isfile(input_file):
        print(f"Error: Input file '{input_file}' not found.")
        sys.exit(1)

    file_size = os.path.getsize(input_file)
    max_size = 500 * 1024 * 1024

    if file_size >= max_size:
        print("Error: Input file size is greater than 500MB.")
        sys.exit(1)

    video_info = subprocess.check_output(
        ['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height', '-of', 'csv=s=x:p=0', input_file]
    ).decode('utf-8').strip()
    input_width, input_height = map(int, video_info.split('x'))

    return input_file, input_width, input_height

def setup_output_directory(input_file):
    output_dir = f"{os.path.splitext(input_file)[0]}_transcoded"
    os.makedirs(output_dir, exist_ok=True)
    return output_dir

def add_resolution(input_height, output_dir, filter_complex, map_args, master_playlist, width, height, bitrate):
    if input_height >= height:
        filter_complex += f"[0:v]scale=w={width}:h={height}[v{height}out]; "
        segment_filename = f"{output_dir}/{height}p_%03d.ts"
        playlist_filename = f"{output_dir}/{height}p.m3u8"
        map_args += f"-map [v{height}out] -c:v libx264 -b:v {bitrate}k -g 48 -sc_threshold 0 -hls_time 6 -hls_playlist_type vod -hls_segment_filename {segment_filename} -f hls {playlist_filename} "
        master_playlist += f"#EXT-X-STREAM-INF:BANDWIDTH={bitrate}000,RESOLUTION={width}x{height}\n{height}p.m3u8\n"

    return filter_complex, map_args, master_playlist

def transcode_video(input_file, output_dir, filter_complex, map_args):
    ffmpeg_cmd = f'ffmpeg -i "{input_file}" -filter_complex "{filter_complex.strip("; ")}" {map_args} -map a:0 -c:a aac -b:a 128k -ac 2 -hls_time 6 -hls_playlist_type vod -f hls -hls_segment_filename "{output_dir}/audio_%03d.ts" "{output_dir}/audio.m3u8"'
    print("Executing command:", ffmpeg_cmd)
    result = subprocess.run(ffmpeg_cmd, shell=True)
    if result.returncode != 0:
        print("Error: ffmpeg transcoding failed.")
        sys.exit(1)

def create_master_playlist(output_dir, master_playlist):
    with open(f"{output_dir}/master.m3u8", "w") as f:
        f.write(master_playlist)
    print(f"Transcoding completed. Output files are stored in: {output_dir}")

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} input_file")
        return

    input_file, input_width, input_height = check_input(sys.argv[1:])
    output_dir = setup_output_directory(input_file)
    filter_complex = ""
    map_args = ""
    master_playlist = "#EXTM3U\n#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"audio\",NAME=\"English\",DEFAULT=YES,AUTOSELECT=YES,URI=\"audio.m3u8\"\n"

    resolutions = [(426, 240, 800), (640, 360, 1200), (854, 480, 2000), (1280, 720, 3000)]
    for width, height, bitrate in resolutions:
        filter_complex, map_args, master_playlist = add_resolution(input_height, output_dir, filter_complex, map_args, master_playlist, width, height, bitrate)

    transcode_video(input_file, output_dir, filter_complex, map_args)
    create_master_playlist(output_dir, master_playlist)

if __name__ == "__main__":
    main()
