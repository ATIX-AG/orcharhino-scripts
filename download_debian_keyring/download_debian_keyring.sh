#!/bin/sh

set -eu

export LANG=C

KEYSERVER="keyserver.ubuntu.com "

TEMPDIR=$(mktemp -d)
SUITE="stable"
if [ -n "$1" ]; then
  SUITE="$1"
fi

BASEURL="http://ftp.debian.org/debian"
if [ -n "$2" ]; then
  BASEURL="$2"
fi

GPG="gpg --homedir $TEMPDIR --quiet"
KEYS=$(\curl -fsS "${BASEURL}/dists/${SUITE}/InRelease" | $GPG --verify 2>&1 | \sed -n '/using RSA key/ s/^.*\s\(\S\)/\1/p')

if [ -z "$KEYS" ]; then
  echo "No Keys found!" >&2
  exit 1
fi

for k in $KEYS; do
  $GPG --keyserver "$KEYSERVER" --recv-key "$k"
done

# shellcheck disable=SC2086
$GPG --armor --export $KEYS

\rm -fr "$TEMPDIR"
