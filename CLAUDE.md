# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System and Commands

### Standard Build Process
```sh
./configure  # Configure build with options (see ./configure --help)
make         # Build FFmpeg (requires GNU Make 3.81+)
make install # Install binaries and libraries
```

### Android Cross-Compilation
```sh
# For ARM64 (default)
./build_android.sh [output_path]

# Using config.sh for different architectures
./config.sh [armv7a|armv8|x86|x86_64]
```

### Testing
```sh
make fate     # Run FATE test suite
make testprogs # Build test programs
```

## Architecture Overview

### Core Libraries (in dependency order)
- **libavutil**: Core utilities, hashers, decompressors, memory management
- **libavcodec**: Codec implementations for audio/video encoding/decoding
- **libavformat**: Container formats, streaming protocols, I/O access
- **libavfilter**: Audio/video filtering through directed graphs
- **libavdevice**: Capture and playback device abstraction
- **libswscale**: Color conversion and scaling routines
- **libswresample**: Audio mixing and resampling

### Directory Structure
- `lib*/`: Core library implementations
- `fftools/`: Command-line tools (ffmpeg, ffplay, ffprobe)
- `ffbuild/`: Build system components and makefiles
- `third-party/`: External dependencies (fdk-aac, lame)
- `tests/`: Test suites and test programs
- `doc/`: Documentation and coding examples
- `usages/`: FFmpeg usage examples and commands

### Build Configuration
- Uses autotools-style `./configure` script for feature detection
- `ffbuild/config.mak` generated during configuration
- Makefile-based build system with modular library compilation
- Cross-compilation support via NDK toolchains for Android

### Third-Party Dependencies
- **fdk-aac**: AAC audio encoder library
- **lame**: MP3 audio encoder library
- Located in `third-party/` directory

### Development Workflow
- Patches submitted via ffmpeg-devel mailing list using `git format-patch`
- GitHub pull requests are not part of review process
- Non-system dependencies disabled by default in configure