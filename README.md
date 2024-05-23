# HLS Transcoding Scripts

Those scripts takes an input video file and transcodes it into HTTP Live Streaming (HLS) format with different resolutions.

## Prerequisites

- [ffmpeg](https://ffmpeg.org/) must be installed on your system.

## Usage

- `input_file`: Path to the input video file (fe. SampleVideo_1280x720_10mb.mp4).

```bash
./transcode_to_hls.sh input_file
```

Or (if you prefer to use python)

```bash
python transcode_to_hls.py input_file
```

## Output

The script will create a directory with the following structure:

```
input_file_transcoded/
│
├── 240p.m3u8
├── 360p.m3u8
├── 480p.m3u8
├── 720p.m3u8
├── audio.m3u8
├── audio_001.ts
├── audio_002.ts
├── ...
├── master.m3u8
├── 240p_001.ts
├── 240p_002.ts
├── ...
├── 360p_001.ts
├── 360p_002.ts
├── ...
├── 480p_001.ts
├── 480p_002.ts
├── ...
└── 720p_001.ts
└── 720p_002.ts
└── ...
```

- Four variants of the video with resolutions 240p, 360p, 480p, and 720p.
- Audio stream in AAC format.
- Master playlist (`master.m3u8`) linking to the variant playlists and audio stream.

