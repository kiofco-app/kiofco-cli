#!/bin/sh
# Download this installer, inspect it, then run it; do not pipe network code to sh.
set -eu
umask 077

case "$(uname -s)" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) echo 'Unsupported OS; use cli-install.ps1 on Windows.' >&2; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) echo 'Unsupported CPU architecture.' >&2; exit 1 ;;
esac

version=${KIOFCO_VERSION:-latest}
base=https://github.com/kiofco-app/kiofco-cli/releases
if [ "$version" = latest ]; then
  base=$base/latest/download
else
  if ! printf '%s\n' "$version" | grep -Eq '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; then
    echo 'KIOFCO_VERSION must be vMAJOR.MINOR.PATCH.' >&2; exit 1
  fi
  base=$base/download/$version
fi

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT HUP INT TERM
fetch() {
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    --tlsv1.2 --max-time 120 "$1" --output "$2"
}
fetch "$base/SHA256SUMS" "$staging/SHA256SUMS"
# Select the filename from the producer's checksum manifest; never evaluate it.
entry=$(awk -v os="$os" -v arch="$arch" '
  $1 ~ /^[a-f0-9]+$/ && length($1) == 64 &&
  $2 ~ ("^kiofco_v[0-9]+\\.[0-9]+\\.[0-9]+_" os "_" arch "\\.tar\\.gz$") {
    count++; line=$0
  }
  END { if (count != 1) exit 1; print line }
' "$staging/SHA256SUMS") || { echo 'Missing or ambiguous release target.' >&2; exit 1; }
expected=$(printf '%s\n' "$entry" | awk '{print $1}')
archive=$(printf '%s\n' "$entry" | awk '{print $2}')
if [ "$version" != latest ] && [ "$archive" != "kiofco_${version}_${os}_${arch}.tar.gz" ]; then
  echo 'Release manifest does not match the requested version.' >&2; exit 1
fi
fetch "$base/$archive" "$staging/$archive"
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$staging/$archive" | awk '{print $1}')
else
  actual=$(shasum -a 256 "$staging/$archive" | awk '{print $1}')
fi
[ "$actual" = "$expected" ] || { echo 'Checksum verification failed.' >&2; exit 1; }
members=$(tar -tzf "$staging/$archive")
[ "$members" = "$(printf 'kiofco\nREADME.md')" ] || { echo 'Unexpected archive members.' >&2; exit 1; }
tar -tvzf "$staging/$archive" | awk 'substr($1,1,1) != "-" { exit 1 }' || {
  echo 'Archive entries must be regular files.' >&2; exit 1
}
tar -xzf "$staging/$archive" -C "$staging" kiofco
destination=${KIOFCO_INSTALL_DIR:-$HOME/.local/bin}
mkdir -p "$destination"
if [ -e "$destination/kiofco" ] && [ "${KIOFCO_REPLACE:-0}" != 1 ]; then
  echo 'kiofco already exists. Set KIOFCO_REPLACE=1 to upgrade explicitly.' >&2; exit 1
fi
# Copy to a new file in the destination filesystem before an atomic replacement.
temporary=$(mktemp "$destination/.kiofco.XXXXXXXX")
trap 'rm -rf "$staging"; rm -f "${temporary:-}"' EXIT HUP INT TERM
cp "$staging/kiofco" "$temporary"
chmod 755 "$temporary"
mv -f "$temporary" "$destination/kiofco"
printf 'Installed %s. Add %s to PATH if needed.\n' "$destination/kiofco" "$destination"
