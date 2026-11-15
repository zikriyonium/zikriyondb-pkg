#!/bin/sh
# ZikriyonDB installer for Linux.
#   curl -fsSL https://zikriyondb.zeaipc.info/install.sh | sudo sh            (database server)
#   curl -fsSL https://zikriyondb.zeaipc.info/install.sh | sudo sh -s -- relay (relay + cloud control plane)
set -eu
BASE="https://zikriyondb.zeaipc.info"
case "${1:-zikriyondb}" in
  zikriyondb) PKG=zikriyondb ;;
  relay|zikriyondb-relay) PKG=zikriyondb-relay ;;
  *) echo "usage: install.sh [zikriyondb|relay]" >&2; exit 2 ;;
esac
[ "$(id -u)" -eq 0 ] || { echo "Please run as root:  curl -fsSL $BASE/install.sh | sudo sh" >&2; exit 1; }
case "$(uname -m)" in x86_64|amd64) A=amd64 ;; aarch64|arm64) A=arm64 ;; *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;; esac

if command -v apt-get >/dev/null 2>&1; then
  echo "Adding the ZikriyonDB package repository (signed)..."
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl gnupg
  install -d -m 0755 /usr/share/keyrings
  curl -fsSL "$BASE/apt/zeaipc.gpg" -o /usr/share/keyrings/zeaipc.gpg
  echo "deb [signed-by=/usr/share/keyrings/zeaipc.gpg] $BASE/apt stable main" > /etc/apt/sources.list.d/zikriyondb.list
  apt-get update -qq
  apt-get install -y "$PKG"
else
  echo "No apt found: installing the static binaries to /usr/local/bin"
  tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
  ver=$(curl -fsSL "$BASE/download/LATEST")
  f="zikriyondb-$ver-linux-$A.tar.gz"
  curl -fsSL "$BASE/download/$f" -o "$tmp/$f"
  curl -fsSL "$BASE/download/SHA256SUMS" -o "$tmp/SHA256SUMS"
  ( cd "$tmp" && grep "  $f\$" SHA256SUMS | sha256sum -c - )
  tar -xzf "$tmp/$f" -C "$tmp"
  install -m 0755 "$tmp/zikriyon" /usr/local/bin/zikriyon
  [ "$PKG" = zikriyondb-relay ] && install -m 0755 "$tmp/zikriyon-relay" /usr/local/bin/zikriyon-relay
  echo "Installed. Try:  zikriyon help"
fi
