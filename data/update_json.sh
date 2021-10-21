#!/bin/sh

die() {
	printf 'Error: %s\n' "$1"
	exit 1
}

[ ! -x "$(command -v hjson)" ] && die "Oh crap! we need hjson command! Install Node.JS to get one..."

DIR=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

[ -z "$1" ] && SOURCE_HJSON="$DIR/urls.hjson" || SOURCE_HJSON="$DIR/$1"
[ ! -f "$SOURCE_HJSON" ] && die "Cannot find $SOURCE_HJSON ..."
DEST_JSON="$DIR/urls.json"

hjson -j "$SOURCE_HJSON" >"$DEST_JSON" && printf '%s\n' "urls.hjson export completed!!"
