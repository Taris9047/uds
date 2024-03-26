#!/bin/bash -e

RB_VER='3.2.3'
if [ ! -z "$1" ]; then
  printf 'Selecting ruby version as %s\n' "$1"
  RB_VER="$1"
else
  printf 'Selecting %s\n' "$RB_VER"
fi

die() {
  printf '%s\n' "$1"
  exit 1
}

GEMS=(
  "rsence"
  "rails"
  "rake"
  "bundler"
  "open3"
  "json"
  "hjson"
  "ruby-progressbar"
  "tty-spinner"
)

COMPILE_OPTS=(
  "--enable-shared"
)

C_FLAGS="-O3 -fomit-frame-pointer -fno-semantic-interposition -march=native -pipe"

COMP_OPTS_STR=$(
  IFS=' '
  echo "${COMPILE_OPTS[*]}"
)

# Checking out their git repository to my own rbenv dir...
#
# Their suggestion was ~/.rbenv
#
RBENV_DIR="$HOME/.rbenv"
[ -d "$RBENV_DIR" ] && rm -rf "$RBENV_DIR"
[ ! -x "$(command -v git)" ] && die 'git not found!! Exiting!!'
[ ! -x "$(command -v curl)" ] && die 'curl not found!! Exiting!!'

# Finally installing it!
if [ ! -d "$RBENV_DIR" ]; then
  printf 'Cloning rbenv into %s ...\n' "$RBENV_DIR"
  git clone 'https://github.com/rbenv/rbenv.git' "$RBENV_DIR" || die "Failed to clone rbenv!! Exiting!!"
fi

# Let's install some default ruby installations!!
export RBENV_ROOT="$RBENV_DIR"
export PATH="$RBENV_DIR/bin:$PATH"
eval "$(rbenv init -)"
INSTALL_SUCCESS='true'
if [ ! -f "$RBENV_ROOT/shims/ruby" ]; then
  git clone 'https://github.com/rbenv/ruby-build.git' "$RBENV_ROOT/plugins/ruby-build" || die "ruby-build cloning failed!!"
  env RUBY_CONFIGURE_OPTS="$COMP_OPTS_STR" RUBY_CFLAGS="$C_FLAGS" rbenv install "$RB_VER" || INSTALL_SUCCESS='false'
  # Select recently installed ruby as main.
  [ "$INSTALL_SUCCESS" = 'true' ] && rbenv global "$RB_VER"
fi
RB_RBENV="$RBENV_DIR/shims/ruby"
GEM="$RBENV_DIR/shims/gem"
if [ "$INSTALL_SUCCESS" = 'true' ]; then
  for gem_i in "${GEMS[@]}"; do
    "$GEM" install "$gem_i" || true
  done
fi

append_string() {
	if ! grep -Fxq "${2}" "${1}"; then
		# printf 'Appending %s with %s\n' "${2}" "${1}"
		printf "\n\n%s\n" "${2}" >>"${1}"
	fi
}
append_source() {
	append_string "${1}" "${2}"
}

# Appending .bashrc with rbenv stuffs...
append_source "${HOME}/.bashrc" "export RBENV_ROOT=${RBENV_DIR}"
append_source "${HOME}/.bashrc" "export PATH=${RBENV_DIR}/s:${PATH}"
append_source "${HOME}/.bashrc" "eval $(rbenv init - bash)"
