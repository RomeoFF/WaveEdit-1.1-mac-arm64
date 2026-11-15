# WaveEdit-2

WaveEdit from Synthesis Technology made compatible with Apple Silicon.

## Synthesis Technology WaveEdit

The wavetable and bank editor for the Synthesis Technology [E370](http://synthtech.com/eurorack/E370/) and [E352](http://synthtech.com/eurorack/E352/) Eurorack synthesizer modules.

## macOS (Apple Silicon) fork

This fork updates WaveEdit 1.1 (no longer maintained upstream: https://github.com/AndrewBelt/WaveEdit) so it builds and runs natively on current macOS with Apple Silicon (arm64). Intel Macs build the same way.

Changes from upstream:
- Native arm64 build: removed the x86-only `-march=nocona` flag; dependencies (SDL2, libsndfile, libsamplerate) now come from Homebrew instead of the dead mega-nerd.com tarballs.
- Retina / HiDPI: the UI font is rasterized at the display's pixel density (rebuilt automatically when the window moves to a display with a different scale), and the GL viewport uses physical pixels.
- `autosave.dat` and `ui.dat` are stored in `~/Library/Application Support/WaveEdit/` instead of inside the app bundle, which must stay read-only (code signature, App Translocation, /Applications permissions).
- `make dist` bundles every Homebrew dylib (including SDL3, loaded at runtime by Homebrew's `sdl2-compat`) into the .app, rewrites their install names and ad-hoc signs the bundle, as required on Apple Silicon.
- `-ffast-math` kept, with `-fno-finite-math-only` so the code's uses of `INFINITY` stay well defined.

### Building on macOS

	brew install sdl2 libsndfile libsamplerate
	git submodule update --init --recursive
	make -j8
	./WaveEdit

Self-contained app (in `dist/WaveEdit/WaveEdit.app`, plus a zip):

	make dist

The bundle is ad-hoc signed, not notarized. On another Mac, the first launch needs right-click > Open (or `xattr -dr com.apple.quarantine WaveEdit.app`). The minimum macOS version is that of the bundled Homebrew libraries (i.e. the macOS of the build machine); set `MACOS_MIN` for the compiler target. If the repository lives in an iCloud-synced folder (e.g. ~/Documents), `codesign --verify` on `dist/WaveEdit/WaveEdit.app` may complain about extended attributes iCloud adds back; the zip is unaffected.

### Building (original instructions, Linux/Windows)

Make dependencies with

	cd dep
	make

Clone the in-source dependencies.

	cd ..
	git submodule update --init --recursive

Compile the program. The Makefile will automatically detect your operating system.

	make

Launch the program.

	./WaveEdit

You can even try your luck with building the polished distributable. Although this method is unsupported, it may work with some tweaks to the Makefile.

	make dist
