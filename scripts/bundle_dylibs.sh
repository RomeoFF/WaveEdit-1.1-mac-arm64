#!/bin/bash
# Copies every non-system dylib an executable depends on (recursively) next to it,
# rewrites install names to @executable_path, then ad-hoc signs the app bundle.
# Usage: scripts/bundle_dylibs.sh path/to/App.app/Contents/MacOS/Executable
set -euo pipefail

EXE="$1"
DEST="$(dirname "$EXE")"

is_external() {
	case "$1" in
		/usr/lib/*|/System/*|@executable_path/*|@loader_path/*) return 1 ;;
		*) return 0 ;;
	esac
}

# Resolve @rpath references using the LC_RPATH entries of the referencing binary
resolve() {
	local ref="$1" from="$2"
	if [[ "$ref" == @rpath/* ]]; then
		local name="${ref#@rpath/}"
		for rp in $(otool -l "$from" | awk '/LC_RPATH/{getline; getline; print $2}'); do
			rp="${rp/@loader_path/$(dirname "$from")}"
			if [ -f "$rp/$name" ]; then echo "$rp/$name"; return; fi
		done
		echo "$(dirname "$from")/$name"
	else
		echo "$ref"
	fi
}

fix_binary() {
	local bin="$1" origin="${2:-$1}"
	otool -L "$bin" | tail -n +2 | awk '{print $1}' | while read -r ref; do
		is_external "$ref" || continue
		local src; src="$(resolve "$ref" "$origin")"
		local name; name="$(basename "$ref")"
		if [ ! -f "$DEST/$name" ]; then
			echo "  bundling $name"
			cp -L "$src" "$DEST/$name"
			chmod u+w "$DEST/$name"
			install_name_tool -id "@executable_path/$name" "$DEST/$name" 2>/dev/null
			fix_binary "$DEST/$name" "$(realpath "$src")"
		fi
		install_name_tool -change "$ref" "@executable_path/$name" "$bin" 2>/dev/null
	done
}

fix_binary "$EXE"

# Homebrew's SDL2 is sdl2-compat, which dlopen()s SDL3 at runtime (not visible to otool -L).
# It searches @loader_path/libSDL3.dylib first, so ship SDL3 alongside it.
if strings "$DEST/libSDL2-2.0.0.dylib" 2>/dev/null | grep -q 'libSDL3.dylib'; then
	SDL3="$(brew --prefix sdl3)/lib/libSDL3.0.dylib"
	echo "  bundling libSDL3.dylib (runtime dependency of sdl2-compat)"
	cp -L "$SDL3" "$DEST/libSDL3.dylib"
	chmod u+w "$DEST/libSDL3.dylib"
	install_name_tool -id "@executable_path/libSDL3.dylib" "$DEST/libSDL3.dylib" 2>/dev/null
	fix_binary "$DEST/libSDL3.dylib" "$(realpath "$SDL3")"
fi

# Signatures are invalidated by install_name_tool; arm64 refuses to run unsigned code.
# codesign rejects extended attributes (Finder info, resource forks) that iCloud-synced folders
# such as ~/Documents keep re-adding, so sign a clean copy in a temp dir and copy it back.
APP="$(cd "$DEST/../.." && pwd)"
STAGE="$(mktemp -d)"
ditto --noextattr --norsrc "$APP" "$STAGE/$(basename "$APP")"
for f in "$STAGE/$(basename "$APP")/Contents/MacOS/"*.dylib; do codesign --force --sign - "$f"; done
codesign --force --sign - "$STAGE/$(basename "$APP")"
rm -rf "$APP"
ditto --noextattr --norsrc "$STAGE/$(basename "$APP")" "$APP"
rm -rf "$STAGE"
codesign --verify --deep --strict "$APP" && echo "Signature OK: $APP"
otool -L "$EXE"
