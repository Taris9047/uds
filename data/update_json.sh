#!/bin/sh

die() {
	printf 'Error: %s\n' "$1"
	exit 1
}

[ ! -x "$(command -v hjson)" ] && die "Oh crap! we need hjson command!"

DIR="$(cd "$(dirname "$0")" && pwd)"

hjson -j "$DIR/urls.hjson" >"$DIR/urls.json" && printf '%s\n' "urls.hjson export completed!!"
