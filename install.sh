#!/bin/sh
# Sondr installer, by Aspida Security.
#
#   curl -fsSL https://github.com/aspida-security/sondr-releases/releases/latest/download/install.sh | sh
#
# Safer: download it, read it, then run it:
#   curl -fsSLO https://github.com/aspida-security/sondr-releases/releases/latest/download/install.sh
#   less install.sh
#   sh install.sh
#
# It downloads only from https://github.com/aspida-security/sondr-releases, checks the SHA-256
# checksum before installing anything, and refuses to continue on a mismatch.
# It sends no information anywhere else.
#
# Options:
#   --version vX.Y.Z   install that release instead of the latest
#   --prefix DIR       install the binary to DIR/bin (tarball install, no sudo needed)
#   --dry-run          show what would happen; install nothing
#   --help             this text

set -eu

REPO="aspida-security/sondr-releases"
HOST="https://github.com/$REPO"

version=""
prefix=""
dry_run=0

say() { printf '%s\n' "$*"; }
die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Sondr installer, by Aspida Security.

Usage: sh install.sh [--version vX.Y.Z] [--prefix DIR] [--dry-run]

  --version vX.Y.Z   install that release instead of the latest
  --prefix DIR       install the program to DIR/bin (no sudo needed)
  --dry-run          show what would happen; install nothing

It downloads only from https://github.com/aspida-security/sondr-releases, checks the
SHA-256 checksum before installing anything, and stops if it does not match.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      [ $# -ge 2 ] || die "--version needs a value, for example --version v0.1.0"
      version="$2"
      shift 2
      ;;
    --version=*)
      version="${1#--version=}"
      shift
      ;;
    --prefix)
      [ $# -ge 2 ] || die "--prefix needs a folder, for example --prefix \$HOME/.local"
      prefix="$2"
      shift 2
      ;;
    --prefix=*)
      prefix="${1#--prefix=}"
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) die "unknown option '$1' (try --help)" ;;
  esac
done

case "$version" in
  "" | v[0-9]*) ;;
  [0-9]*) version="v$version" ;;
  *) die "--version should look like v0.1.0" ;;
esac
case "$version" in
  *[!A-Za-z0-9.+_-]*) die "--version contains characters that cannot be part of a release name" ;;
esac

# ---- what machine is this? -------------------------------------------------------------------
[ "$(uname -s)" = "Linux" ] || die "Sondr runs on Linux only (this is $(uname -s))."
case "$(uname -m)" in
  x86_64 | amd64)
    deb_arch="amd64"
    tar_arch="x86_64"
    ;;
  aarch64 | arm64)
    deb_arch="arm64"
    tar_arch="aarch64"
    ;;
  *) die "this computer is $(uname -m); Sondr has builds for x86_64 and arm64 only." ;;
esac

if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL --retry 2 -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -q -O "$2" "$1"; }
else
  die "I need curl or wget to download Sondr. Install one (for example: sudo apt install curl) and run this again."
fi

if command -v sha256sum >/dev/null 2>&1; then
  sha256_of() { sha256sum "$1" | cut -d ' ' -f 1; }
elif command -v shasum >/dev/null 2>&1; then
  sha256_of() { shasum -a 256 "$1" | cut -d ' ' -f 1; }
else
  die "I need sha256sum (or shasum) to check the download. It ships with coreutils."
fi

if [ -n "$version" ]; then
  base="$HOST/releases/download/$version"
else
  base="$HOST/releases/latest/download"
fi

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t sondr-install)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

say "Sondr installer (by Aspida Security)"
say "Looking up the release at $HOST ..."
fetch "$base/SHA256SUMS" "$tmp/SHA256SUMS" ||
  die "could not download the checksum list from $base/SHA256SUMS. Check your internet connection, and that the version exists."

# ---- Debian family with apt and root/sudo? use the .deb; otherwise the tarball ---------------
is_debian_family() {
  [ -r /etc/os-release ] || return 1
  # shellcheck disable=SC1091
  (. /etc/os-release; case " ${ID:-} ${ID_LIKE:-} " in *" debian "* | *" ubuntu "* | *" kali "*) exit 0 ;; *) exit 1 ;; esac)
}

use_deb=0
sudo_cmd=""
if [ -z "$prefix" ] && is_debian_family && command -v apt-get >/dev/null 2>&1; then
  if [ "$(id -u)" = "0" ]; then
    use_deb=1
  elif command -v sudo >/dev/null 2>&1; then
    use_deb=1
    sudo_cmd="sudo"
  fi
fi

if [ "$use_deb" = 1 ]; then
  asset="$(awk -v a="_${deb_arch}.deb" '{ n = length($2); if (substr($2, n - length(a) + 1) == a) { print $2; exit } }' "$tmp/SHA256SUMS")"
else
  asset="$(awk -v a="linux-${tar_arch}.tar.gz" '{ n = length($2); if (substr($2, n - length(a) + 1) == a) { print $2; exit } }' "$tmp/SHA256SUMS")"
fi
[ -n "$asset" ] || die "this release has no build for your computer ($(uname -m)). See $HOST/releases"
case "$asset" in
  */* | .*) die "the checksum list has an unexpected file name; stopping." ;;
esac
expected="$(awk -v f="$asset" '$2 == f { print $1; exit }' "$tmp/SHA256SUMS")"
[ -n "$expected" ] || die "the checksum list has no entry for $asset; stopping."

if [ "$use_deb" = 1 ]; then
  say "Plan: download $asset, check its checksum, then run: ${sudo_cmd:+$sudo_cmd }apt install ./$asset"
else
  dest="${prefix:-$HOME/.local}"
  say "Plan: download $asset, check its checksum, then put the program in $dest/bin"
fi

if [ "$dry_run" = 1 ]; then
  say "Dry run: nothing was downloaded beyond the checksum list, and nothing was installed."
  exit 0
fi

say "Downloading $asset ..."
fetch "$base/$asset" "$tmp/$asset" || die "could not download $base/$asset"
actual="$(sha256_of "$tmp/$asset")"
if [ "$actual" != "$expected" ]; then
  die "the checksum does not match (expected $expected, got $actual). The download may be damaged or tampered with, so nothing was installed."
fi
say "Checksum OK."

if [ "$use_deb" = 1 ]; then
  # apt runs as its own user and must be able to read the file; the folder holds only this download.
  chmod 755 "$tmp"
  chmod 644 "$tmp/$asset"
  # a path with a slash makes apt install the file rather than look up a package name
  $sudo_cmd apt-get install -y "$tmp/$asset" || die "apt could not install the package. The message above says why."
else
  command -v tar >/dev/null 2>&1 || die "I need tar to unpack the download."
  mkdir -p "$tmp/x" "$dest/bin"
  tar -xzf "$tmp/$asset" -C "$tmp/x"
  bin="$(find "$tmp/x" -type f -name sondr | head -n 1)"
  [ -n "$bin" ] || die "the download did not contain the sondr program."
  cp "$bin" "$dest/bin/sondr.new"
  chmod 755 "$dest/bin/sondr.new"
  mv "$dest/bin/sondr.new" "$dest/bin/sondr"
  man="$(find "$tmp/x" -type f -name sondr.1 | head -n 1)"
  if [ -n "$man" ]; then
    mkdir -p "$dest/share/man/man1" && cp "$man" "$dest/share/man/man1/sondr.1" || true
  fi
  say "Installed $dest/bin/sondr"
  case ":${PATH:-}:" in
    *":$dest/bin:"*) ;;
    *)
      say ""
      say "Note: $dest/bin is not in your PATH, so your terminal will not find 'sondr' yet."
      say "Add it by putting this line in your shell's startup file (~/.bashrc, ~/.zshrc):"
      say "    export PATH=\"$dest/bin:\$PATH\""
      ;;
  esac
fi

say ""
say "Done. Now run:"
say ""
say "    sondr"
say ""
say "It walks you through the rest. To remove it later: sondr uninstall, then sudo apt remove sondr"
