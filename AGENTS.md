# Repository Guidelines

This guide captures the conventions used when extending FFmpeg in this repository. Refer back here before adding code, updating build logic, or preparing contributions for review.

## Project Structure & Module Organization
- Core libraries live under `libavcodec`, `libavformat`, `libavfilter`, `libavdevice`, `libavutil`, `libswscale`, and `libswresample`; keep new codecs, demuxers, or filters with their peers.
- Command-line frontends (`ffmpeg`, `ffplay`, `ffprobe`) reside in `fftools`; shared build logic is in `ffbuild`, and integration assets (presets, docs) live in `presets` and `doc` respectively.
- Tests are organized under `tests` and `test_build`; standalone utilities and scripts go in `tools` or `third-party` when vendoring external sources.

## Build, Test, and Development Commands
- `./configure --enable-gpl --enable-nonfree`: prepare a local build; add feature flags explicitly and document non-default options in your PR.
- `make -j$(nproc)`: compile the tree; prefer out-of-tree builds by setting `--prefix` or `--bindir` during configuration when packaging.
- `make fate` / `make fate-lavf`: run the FATE regression suites globally or scoped to formats; required before every submission.
- `make install DESTDIR=out`: stage binaries for packaging; confirm `ffmpeg -version` reports the expected configuration line.

## Coding Style & Naming Conventions
- Use four-space indentation, no hard tabs, and keep braces on the same line as conditionals (`if (...) {`).
- Public APIs use the `av_` prefix; internal helpers should stay `static` and follow lower_snake_case, while macros remain UPPER_SNAKE_CASE.
- Run `./tools/patcheck` and `make checkheaders` before review to catch style or header regressions; avoid trailing whitespace and ensure files end with a newline.

## Testing Guidelines
- Place new regression data under `tests/ref` and register cases via `tests/fate/*.mak`; mirror existing section naming such as `fate-lavf-<feature>`.
- Use `tests/checkasm` for SIMD validation and note required CPU flags in commit messages.
- Document any new dataset requirements in `doc/fate.texi` and keep artifacts under 1 MB; larger samples belong in the shared media server, not the repo.

## Commit & Pull Request Guidelines
- Follow the existing log style: lowercase type prefixes (`feat:`, `fix:`, `update:`) followed by a concise summary; include affected subsystem tags when helpful (e.g., `feat(lavc): add codec`).
- Rebase on `master`, ensure `make fate` is green, and attach the configuration line from the build.
- Pull requests should describe motivation, list new options or ABI changes, link related issues, and include screenshots or sample commands when they clarify behavior.

## Configuration Notes
- Generated files like `config.h` and `config_components.h` should never be committed; rely on `configure` to regenerate them per build target.
- For cross-compilation, document required toolchains and pass `--enable-cross-compile` with `--arch`/`--target-os`; store reproducible command snippets in `doc/building.texi`.

## Android Cross-Build Script
- `build_android.sh` auto-detects the Android NDK (env vars, common SDK paths) and guides installation if none is found; it validates selected toolchains against the host tag (`darwin-x86_64`/`linux-x86_64`).
- Interactive runs require no arguments: use ↑/↓ and Enter to pick NDK, target ABI (`arm64`, `armv7a`, `x86`, `x86_64`, or `all`), library type (`shared`, `static`, `both`), API level (21–34 or custom), and output directory; confirmations reopen the wizard or cancel cleanly.
- Non-interactive syntax: `./build_android.sh <arch> [output_dir] [api] [library_type]`; defaults are `arm64`, `./build/android-<arch>`, API 21, and `shared`. Set `ANDROID_NDK_ROOT` when skipping the interactive picker.
- The script prepares LLVM toolchains under `toolchains/llvm/prebuilt/<host>`, configures FFmpeg with JNI/MediaCodec decoders, and toggles `--enable-{shared,static}` based on the selected library mode before building and installing artefacts per architecture.
