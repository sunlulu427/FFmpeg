# 录制相关

## 录制帧率30的视频

```sh
ffmpeg -f avfoundation -i 1 -r 30 out.yuv
```

## 使用ffplay播放yuv

```sh
ffplay -video_size 1920x1080 -pixel_format uyvy422 out.yuv
```

## 查询支持的设备列表

```sh
❯ ffmpeg -f avfoundation -list_devices true -i ""
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
[AVFoundation indev @ 0x154905130] AVFoundation video devices:
[AVFoundation indev @ 0x154905130] [0] AUSDOM AW651S
[AVFoundation indev @ 0x154905130] [1] Capture screen 0
[AVFoundation indev @ 0x154905130] [2] Capture screen 1
[AVFoundation indev @ 0x154905130] AVFoundation audio devices:
[AVFoundation indev @ 0x154905130] [0] Realtek USB2.0 MIC
```

## 录制声音

```sh
❯ ffmpeg -f avfoundation -i :0 out.wav
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, avfoundation, from ':0':
  Duration: N/A, start: 2025726.655604, bitrate: 3072 kb/s
  Stream #0:0: Audio: pcm_f32le, 48000 Hz, stereo, flt, 3072 kb/s
Stream mapping:
  Stream #0:0 -> #0:0 (pcm_f32le (native) -> pcm_s16le (native))
Press [q] to stop, [?] for help
Output #0, wav, to 'out.wav':
  Metadata:
    ISFT            : Lavf59.27.100
  Stream #0:0: Audio: pcm_s16le ([1][0][0][0] / 0x0001), 48000 Hz, stereo, s16, 1536 kb/s
    Metadata:
      encoder         : Lavc59.37.100 pcm_s16le
size=     524kB time=00:00:03.14 bitrate=1364.4kbits/s speed=0.999x
video:0kB audio:524kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.014537%
Exiting normally, received signal 2.
```

## 同时录制视频和声音
```sh
❯ ffmpeg -f avfoundation -i "1:0" -t 10 -r 30 out.mp4
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
objc[70723]: class `NSKVONotifying_AVCaptureScreenInput' not linked into application
objc[70723]: class `NSKVONotifying_AVCaptureScreenInput' not linked into application
objc[70723]: class `NSKVONotifying_AVCaptureScreenInput' not linked into application
[AVFoundation indev @ 0x126605a80] Configuration of video device failed, falling back to default.
[avfoundation @ 0x126605810] Selected pixel format (yuv420p) is not supported by the input device.
[avfoundation @ 0x126605810] Supported pixel formats:
[avfoundation @ 0x126605810]   uyvy422
[avfoundation @ 0x126605810]   yuyv422
[avfoundation @ 0x126605810]   nv12
[avfoundation @ 0x126605810]   0rgb
[avfoundation @ 0x126605810]   bgr0
[avfoundation @ 0x126605810] Overriding selected pixel format to use uyvy422 instead.
[avfoundation @ 0x126605810] Stream #0: not enough frames to estimate rate; consider increasing probesize
Input #0, avfoundation, from '1:0':
  Duration: N/A, start: 2044570.683000, bitrate: N/A
  Stream #0:0: Video: rawvideo (UYVY / 0x59565955), uyvy422, 1920x1080, 1000k tbr, 1000k tbn
  Stream #0:1: Audio: pcm_f32le, 48000 Hz, stereo, flt, 3072 kb/s
Stream mapping:
  Stream #0:0 -> #0:0 (rawvideo (native) -> mpeg4 (native))
  Stream #0:1 -> #0:1 (pcm_f32le (native) -> aac (native))
Press [q] to stop, [?] for help
Output #0, mp4, to 'out.mp4':
  Metadata:
    encoder         : Lavf59.27.100
  Stream #0:0: Video: mpeg4 (mp4v / 0x7634706D), yuv420p(tv, progressive), 1920x1080, q=2-31, 200 kb/s, 30 fps, 15360 tbn
    Metadata:
      encoder         : Lavc59.37.100 mpeg4
    Side data:
      cpb: bitrate max/min/avg: 0/0/200000 buffer size: 0 vbv_delay: N/A
  Stream #0:1: Audio: aac (LC) (mp4a / 0x6134706D), 48000 Hz, stereo, fltp, 128 kb/s
    Metadata:
      encoder         : Lavc59.37.100 aac
frame=  300 fps= 30 q=31.0 Lsize=    2816kB time=00:00:10.02 bitrate=2300.7kbits/s speed=   1x
video:2684kB audio:123kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.328879%
```

# 分解与复用
## 多媒体格式转换
```sh
❯ ffmpeg -i song.flv -vcodec copy -acodec copy song.mp4
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, flv, from 'song.flv':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Duration: 00:01:07.50, start: 0.000000, bitrate: 594 kb/s
  Stream #0:0: Video: h264 (High), yuv420p(tv, bt709, progressive), 540x960, 540 kb/s, 30 fps, 30 tbr, 1k tbn
  Stream #0:1: Audio: aac (HE-AAC), 44100 Hz, stereo, fltp, 48 kb/s
Output #0, mp4, to 'song.mp4':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Stream #0:0: Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt709, progressive), 540x960, q=2-31, 540 kb/s, 30 fps, 30 tbr, 16k tbn
  Stream #0:1: Audio: aac (HE-AAC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 48 kb/s
Stream mapping:
  Stream #0:0 -> #0:0 (copy)
  Stream #0:1 -> #0:1 (copy)
Press [q] to stop, [?] for help
frame= 2020 fps=0.0 q=-1.0 Lsize=    4904kB time=00:01:07.52 bitrate= 594.9kbits/s speed=9.66e+03x
video:4442kB audio:396kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 1.352640%
```
## 从媒体文件抽取视频流
```sh
❯ ffmpeg -i song.flv -an -vcodec copy song.h264
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, flv, from 'song.flv':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Duration: 00:01:07.50, start: 0.000000, bitrate: 594 kb/s
  Stream #0:0: Video: h264 (High), yuv420p(tv, bt709, progressive), 540x960, 540 kb/s, 30 fps, 30 tbr, 1k tbn
  Stream #0:1: Audio: aac (HE-AAC), 44100 Hz, stereo, fltp, 48 kb/s
Output #0, h264, to 'song.h264':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Stream #0:0: Video: h264 (High), yuv420p(tv, bt709, progressive), 540x960, q=2-31, 540 kb/s, 30 fps, 30 tbr, 30 tbn
Stream mapping:
  Stream #0:0 -> #0:0 (copy)
Press [q] to stop, [?] for help
frame= 2020 fps=0.0 q=-1.0 Lsize=    4442kB time=00:01:07.36 bitrate= 540.2kbits/s speed=1.25e+04x
video:4442kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: unknow
```
## 从媒体文件中抽取音频
```sh
❯ ffmpeg -i song.flv -vn -acodec copy out.aac
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, flv, from 'song.flv':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Duration: 00:01:07.50, start: 0.000000, bitrate: 594 kb/s
  Stream #0:0: Video: h264 (High), yuv420p(tv, bt709, progressive), 540x960, 540 kb/s, 30 fps, 30 tbr, 1k tbn
  Stream #0:1: Audio: aac (HE-AAC), 44100 Hz, stereo, fltp, 48 kb/s
Output #0, adts, to 'out.aac':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Stream #0:0: Audio: aac (HE-AAC), 44100 Hz, stereo, fltp, 48 kb/s
Stream mapping:
  Stream #0:1 -> #0:0 (copy)
Press [q] to stop, [?] for help
size=     406kB time=00:01:07.52 bitrate=  49.2kbits/s speed=3.31e+04x
video:0kB audio:396kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 2.510910%
```
# 处理原始数据
## 提取YUV数据
```sh
❯ ffmpeg -i song.flv -an -c:v rawvideo -pixel_format yuv420p out.yuv
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, flv, from 'song.flv':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Duration: 00:01:07.50, start: 0.000000, bitrate: 594 kb/s
  Stream #0:0: Video: h264 (High), yuv420p(tv, bt709, progressive), 540x960, 540 kb/s, 30 fps, 30 tbr, 1k tbn
  Stream #0:1: Audio: aac (HE-AAC), 44100 Hz, stereo, fltp, 48 kb/s
Stream mapping:
  Stream #0:0 -> #0:0 (h264 (native) -> rawvideo (native))
Press [q] to stop, [?] for help
Output #0, rawvideo, to 'out.yuv':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Stream #0:0: Video: rawvideo (I420 / 0x30323449), yuv420p(tv, bt709, progressive), 540x960, q=2-31, 186624 kb/s, 30 fps, 30 tbn
    Metadata:
      encoder         : Lavc59.37.100 rawvideo
frame= 2023 fps=0.0 q=-0.0 Lsize= 1536216kB time=00:01:07.43 bitrate=186624.0kbits/s dup=3 drop=0 speed=81.2x
video:1536216kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.000000%
```
## 提取PCM数据
```sh
❯ ffmpeg -i song.flv -vn -ar 44100 -ac 2 -f s16le out.pcm
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, flv, from 'song.flv':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Duration: 00:01:07.50, start: 0.000000, bitrate: 594 kb/s
  Stream #0:0: Video: h264 (High), yuv420p(tv, bt709, progressive), 540x960, 540 kb/s, 30 fps, 30 tbr, 1k tbn
  Stream #0:1: Audio: aac (HE-AAC), 44100 Hz, stereo, fltp, 48 kb/s
Stream mapping:
  Stream #0:1 -> #0:0 (aac (native) -> pcm_s16le (native))
Press [q] to stop, [?] for help
Output #0, s16le, to 'out.pcm':
  Metadata:
    minor_version   : 512
    major_brand     : isom
    compatible_brands: isomiso2mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    moov_ahead      : 1
    is_open_gop     : 0
    encoder         : Lavf59.27.100
  Stream #0:0: Audio: pcm_s16le, 44100 Hz, stereo, s16, 1411 kb/s
    Metadata:
      encoder         : Lavc59.37.100 pcm_s16le
size=   11632kB time=00:01:07.52 bitrate=1411.2kbits/s speed= 930x
video:0kB audio:11632kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.000000%
```
## 播放PCM数据
```sh
❯ ffplay out.pcm -ar 44100 -ac 2 -f s16le
ffplay version 5.1.4 Copyright (c) 2003-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
[s16le @ 0x15517fef0] Estimating duration from bitrate, this may be inaccurate
Input #0, s16le, from 'out.pcm':
  Duration: 00:01:07.52, bitrate: 1411 kb/s
  Stream #0:0: Audio: pcm_s16le, 44100 Hz, 2 channels, s16, 1411 kb/s
   4.85 M-A:  0.000 fd=   0 aq=  175KB vq=    0KB sq=    0B f=0/0
```

# 滤镜命令
## 视频裁剪
```sh
❯ ffmpeg -i in.mp4 -vf crop=in_w-200:in_h-400 -c:v h264 -c:a copy out2.mp4
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'in.mp4':
  Metadata:
    major_brand     : isom
    minor_version   : 512
    compatible_brands: isomiso2avc1mp41
    encoder         : Lavf59.27.100
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
  Duration: 00:01:07.52, start: 0.000000, bitrate: 594 kb/s
  Stream #0:0[0x1](und): Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt709, progressive), 540x960, 540 kb/s, 30 fps, 30 tbr, 16k tbn (default)
    Metadata:
      handler_name    : VideoHandler
      vendor_id       : [0][0][0][0]
  Stream #0:1[0x2](und): Audio: aac (HE-AAC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 48 kb/s (default)
    Metadata:
      handler_name    : SoundHandler
      vendor_id       : [0][0][0][0]
File 'out2.mp4' already exists. Overwrite? [y/N] y
Stream mapping:
  Stream #0:0 -> #0:0 (h264 (native) -> h264 (h264_videotoolbox))
  Stream #0:1 -> #0:1 (copy)
Press [q] to stop, [?] for help
Output #0, mp4, to 'out2.mp4':
  Metadata:
    major_brand     : isom
    minor_version   : 512
    compatible_brands: isomiso2avc1mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    encoder         : Lavf59.27.100
  Stream #0:0(und): Video: h264 (avc1 / 0x31637661), yuv420p(tv, bt709, progressive), 340x560, q=2-31, 200 kb/s, 30 fps, 15360 tbn (default)
    Metadata:
      handler_name    : VideoHandler
      vendor_id       : [0][0][0][0]
      encoder         : Lavc59.37.100 h264_videotoolbox
  Stream #0:1(und): Audio: aac (HE-AAC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 48 kb/s (default)
    Metadata:
      handler_name    : SoundHandler
      vendor_id       : [0][0][0][0]
frame= 2023 fps=1162 q=-0.0 Lsize=    2116kB time=00:01:07.52 bitrate= 256.8kbits/s dup=3 drop=0 speed=38.8x
video:1680kB audio:396kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 1.947398%
```

# 裁剪与合并
## 视频裁剪
```sh
❯ ffmpeg -i in.mp4 -ss 00:00:00 -t 10 out.ts
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'in.mp4':
  Metadata:
    major_brand     : isom
    minor_version   : 512
    compatible_brands: isomiso2avc1mp41
    encoder         : Lavf59.27.100
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
  Duration: 00:01:07.52, start: 0.000000, bitrate: 594 kb/s
  Stream #0:0[0x1](und): Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt709, progressive), 540x960, 540 kb/s, 30 fps, 30 tbr, 16k tbn (default)
    Metadata:
      handler_name    : VideoHandler
      vendor_id       : [0][0][0][0]
  Stream #0:1[0x2](und): Audio: aac (HE-AAC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 48 kb/s (default)
    Metadata:
      handler_name    : SoundHandler
      vendor_id       : [0][0][0][0]
Stream mapping:
  Stream #0:0 -> #0:0 (h264 (native) -> mpeg2video (native))
  Stream #0:1 -> #0:1 (aac (native) -> mp2 (native))
Press [q] to stop, [?] for help
Output #0, mpegts, to 'out.ts':
  Metadata:
    major_brand     : isom
    minor_version   : 512
    compatible_brands: isomiso2avc1mp41
    comment         : mid:NTA4NTg2MzM3NDQyMjA0NQ==
    encoder         : Lavf59.27.100
  Stream #0:0(und): Video: mpeg2video (Main), yuv420p(tv, bt709, progressive), 540x960, q=2-31, 200 kb/s, 30 fps, 90k tbn (default)
    Metadata:
      handler_name    : VideoHandler
      vendor_id       : [0][0][0][0]
      encoder         : Lavc59.37.100 mpeg2video
    Side data:
      cpb: bitrate max/min/avg: 0/0/200000 buffer size: 0 vbv_delay: N/A
  Stream #0:1(und): Audio: mp2, 44100 Hz, stereo, s16, 384 kb/s (default)
    Metadata:
      handler_name    : SoundHandler
      vendor_id       : [0][0][0][0]
      encoder         : Lavc59.37.100 mp2
frame=  297 fps=0.0 q=31.0 Lsize=    1422kB time=00:00:09.99 bitrate=1165.8kbits/s speed=52.9x
video:838kB audio:469kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 8.844723%
```
## 音视频合并
```sh
❯ ffmpeg -f concat -i inputs.txt concat_out.flv
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, concat, from 'inputs.txt':
  Duration: N/A, start: 0.000000, bitrate: N/A
  Stream #0:0: Video: mpeg2video (Main) ([2][0][0][0] / 0x0002), yuv420p(tv, bt709, progressive), 540x960 [SAR 1:1 DAR 9:16], 30 fps, 30 tbr, 90k tbn
    Side data:
      cpb: bitrate max/min/avg: 0/0/0 buffer size: 49152 vbv_delay: N/A
  Stream #0:1(und): Audio: mp2 ([3][0][0][0] / 0x0003), 44100 Hz, stereo, s16p, 384 kb/s
Stream mapping:
  Stream #0:0 -> #0:0 (mpeg2video (native) -> flv1 (flv))
  Stream #0:1 -> #0:1 (mp2 (native) -> adpcm_swf (native))
Press [q] to stop, [?] for help
Output #0, flv, to 'concat_out.flv':
  Metadata:
    encoder         : Lavf59.27.100
  Stream #0:0: Video: flv1 ([2][0][0][0] / 0x0002), yuv420p(tv, bt709, progressive), 540x960 [SAR 1:1 DAR 9:16], q=2-31, 200 kb/s, 30 fps, 1k tbn
    Metadata:
      encoder         : Lavc59.37.100 flv
    Side data:
      cpb: bitrate max/min/avg: 0/0/200000 buffer size: 0 vbv_delay: N/A
  Stream #0:1(und): Audio: adpcm_swf ([1][0][0][0] / 0x0001), 44100 Hz, stereo, s16, 352 kb/s
    Metadata:
      encoder         : Lavc59.37.100 adpcm_swf
frame=   90 fps=0.0 q=31.0 Lsize=     514kB time=00:00:03.06 bitrate=1375.0kbits/s speed=23.5x
video:380kB audio:132kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.436400
```
其中inputs.txt文件中记录了所有想要合并的文件，格式为: 'file filename'格式
```txt
❯ cat inputs.txt
file 1.ts
file 2.ts
```

# 图片/视频互转
## 视频转图片
```sh
❯ ffmpeg -i 2.ts -r 2 -f image2 image-%3d.jpeg
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, mpegts, from '2.ts':
  Duration: 00:00:02.01, start: 1.422422, bitrate: 1698 kb/s
  Program 1
    Metadata:
      service_name    : Service01
      service_provider: FFmpeg
  Stream #0:0[0x100]: Video: mpeg2video (Main) ([2][0][0][0] / 0x0002), yuv420p(tv, bt709, progressive), 540x960 [SAR 1:1 DAR 9:16], 30 fps, 30 tbr, 90k tbn
    Side data:
      cpb: bitrate max/min/avg: 0/0/0 buffer size: 49152 vbv_delay: N/A
  Stream #0:1[0x101](und): Audio: mp2 ([3][0][0][0] / 0x0003), 44100 Hz, stereo, fltp, 384 kb/s
Stream mapping:
  Stream #0:0 -> #0:0 (mpeg2video (native) -> mjpeg (native))
Press [q] to stop, [?] for help
[swscaler @ 0x1300f0000] [swscaler @ 0x110018000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x110380000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x110390000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x1103a0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x1103b0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x1103c0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x1103d0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x1103e0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1300f0000] [swscaler @ 0x1103f0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x1103f0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x110018000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x110380000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x110390000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x1103a0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x1103b0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x1103c0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x1103d0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120088000] [swscaler @ 0x1103e0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118008000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118018000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118028000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118038000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118048000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118058000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118068000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118078000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x118088000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x110018000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x1103f0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x110380000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x110390000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x1103a0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x1103b0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x1103c0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x1103d0000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x1103e0000] [swscaler @ 0x110400000] deprecated pixel format used, make sure you did set range correctly
Output #0, image2, to 'image-%3d.jpeg':
  Metadata:
    encoder         : Lavf59.27.100
  Stream #0:0: Video: mjpeg, yuvj420p(pc, bt709, progressive), 540x960 [SAR 1:1 DAR 9:16], q=2-31, 200 kb/s, 2 fps, 2 tbn
    Metadata:
      encoder         : Lavc59.37.100 mjpeg
    Side data:
      cpb: bitrate max/min/avg: 0/0/200000 buffer size: 0 vbv_delay: N/A
frame=    6 fps=0.0 q=2.1 Lsize=N/A time=00:00:03.00 bitrate=N/A dup=0 drop=54 speed=78.2x
video:261kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: unknown
❯ ls
1.ts           image-001.jpeg image-004.jpeg in.mp4         out.pcm        out.yuv        song.h264
2.ts           image-002.jpeg image-005.jpeg inputs.txt     out.ts         out2.mp4       song.mp4
concat_out.flv image-003.jpeg image-006.jpeg out.aac        out.wav        song.flv
```

## 图片转视频
```sh
❯ ffmpeg -i image-%3d.jpeg image2video.mp4
ffmpeg version 5.1.4 Copyright (c) 2000-2023 the FFmpeg developers
  built with Apple clang version 14.0.0 (clang-1400.0.29.202)
  configuration:
  libavutil      57. 28.100 / 57. 28.100
  libavcodec     59. 37.100 / 59. 37.100
  libavformat    59. 27.100 / 59. 27.100
  libavdevice    59.  7.100 / 59.  7.100
  libavfilter     8. 44.100 /  8. 44.100
  libswscale      6.  7.100 /  6.  7.100
  libswresample   4.  7.100 /  4.  7.100
Input #0, image2, from 'image-%3d.jpeg':
  Duration: 00:00:00.24, start: 0.000000, bitrate: N/A
  Stream #0:0: Video: mjpeg (Baseline), yuvj420p(pc, bt470bg/unknown/unknown), 540x960 [SAR 1:1 DAR 9:16], 25 fps, 25 tbr, 25 tbn
Stream mapping:
  Stream #0:0 -> #0:0 (mjpeg (native) -> mpeg4 (native))
Press [q] to stop, [?] for help
[swscaler @ 0x110008000] [swscaler @ 0x108008000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108018000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108028000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108038000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108048000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108058000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108068000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108078000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x110008000] [swscaler @ 0x108088000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x120188000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x120198000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x1201a8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x1201b8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x1201c8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x1201d8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x1201e8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x1201f8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x120178000] [swscaler @ 0x120208000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x120178000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x120188000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x120198000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x1201a8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x1201b8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x1201c8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x1201d8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x1201e8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x128008000] [swscaler @ 0x1201f8000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108008000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108018000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108028000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108038000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108048000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108058000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108068000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108078000] deprecated pixel format used, make sure you did set range correctly
[swscaler @ 0x108088000] [swscaler @ 0x108098000] deprecated pixel format used, make sure you did set range correctly
Output #0, mp4, to 'image2video.mp4':
  Metadata:
    encoder         : Lavf59.27.100
  Stream #0:0: Video: mpeg4 (mp4v / 0x7634706D), yuv420p(tv, bt470bg/unknown/unknown, progressive), 540x960 [SAR 1:1 DAR 9:16], q=2-31, 200 kb/s, 25 fps, 12800 tbn
    Metadata:
      encoder         : Lavc59.37.100 mpeg4
    Side data:
      cpb: bitrate max/min/avg: 0/0/200000 buffer size: 0 vbv_delay: N/A
frame=    6 fps=0.0 q=7.0 Lsize=     219kB time=00:00:00.20 bitrate=8967.1kbits/s speed=8.05x
video:218kB audio:0kB subtitle:0kB other streams:0kB global headers:0kB muxing overhead: 0.412368%
```
# 直播相关命令
## 直播推流
```sh
ffmpeg -re -i out.mp4 -c copy -f flv rtmp://server/live/streamName
```
## 直播拉流
```sh
ffmpeg -i rtmp://server/live/streamName -c copy dump.flv
```