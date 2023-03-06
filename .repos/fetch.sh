#!/bin/sh -e

dependencies() {
  # https://github.com/hashicorp/go-getter#url-format
  wait
}

# LOGIC

get() {
  dst=$(basename ${!#//\/\/*})
  ${VERBOSE:-true} && echo "${COLOR:-$YELLOW}go-getter $@${NC}" || true
  go-getter $@ $dst &
}

setup() {
  export MAGENTA='\033[0;95m'
  export YELLOW='\033[1;33m'
  export NC='\033[0m' # No Color'
}

# STAFF AROUND
repo_is_clean() {
  git diff-index --quiet HEAD --
}
pushd() {
  export OLDPW=$PWD
  cd "$@" >/dev/null
}
popd() {
  cd - >/dev/null
}
say() {
  (echo >&2 -e "\n${COLOR:-$MAGENTA}$1${NC}")
  [[ -z ${2:-''} ]] || exit $2
}
ask() {
  local prompt default reply
  while true; do
    if [[ "${2:-}" =~ ^Y ]]; then
      prompt="Y/n"
      default=Y
    elif [[ "${2:-}" =~ ^N ]]; then
      prompt="y/N"
      default=N
    fi
    say "\n$1 [$prompt]"
    read reply
    reply=${reply:-$default}
    case "$reply" in
    Y* | y*) return 0 ;;
    N* | n*) return 1 ;;
    *) return 1 ;;
    esac
  done
}


# MAIN
# continues if not sourced
if [[ "$BASH_SOURCE" == "$0" ]]; then
  set -eu -o pipefail
  setup
  if [[ $# -gt 0 ]]; then
    # exec individual logic
    fn=$1
    shift
    $fn $@
  else
    dependencies
  fi
fi

