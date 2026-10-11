#!/usr/bin/env bash
# Exporta el APK firmado de Android a build/android/LadrillosCombinatorios.apk.
#
# Requisitos (ver README): Godot 4.7 con las plantillas de exportación,
# Android SDK con build-tools en ~/Android/Sdk, Java, y la llave de firma en
# ~/.local/share/ladrillos-combinatorios/ (release.keystore y release.keystore.txt).
#
# Uso:  ./exportar_apk.sh [ruta/al/ejecutable/de/godot]
set -euo pipefail

GODOT="${1:-${GODOT:-godot}}"
LLAVES="${LLAVES:-$HOME/.local/share/ladrillos-combinatorios}"
cd "$(dirname "$0")"

if [[ ! -f "$LLAVES/release.keystore" || ! -f "$LLAVES/release.keystore.txt" ]]; then
	echo "No encuentro la llave de firma en $LLAVES." >&2
	echo "Créala con keytool (ver README, sección «Versión Android»)." >&2
	exit 1
fi

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$LLAVES/release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$(grep '^alias=' "$LLAVES/release.keystore.txt" | cut -d= -f2-)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(grep '^password=' "$LLAVES/release.keystore.txt" | cut -d= -f2-)"

mkdir -p build/android
"$GODOT" --headless --path . --export-release "Android" build/android/LadrillosCombinatorios.apk
ls -lh build/android/LadrillosCombinatorios.apk
