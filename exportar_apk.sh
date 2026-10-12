#!/usr/bin/env bash
# Exporta el APK firmado de Android a build/android/LadrillosCombinatorios.apk
# y arma build/LadrillosCombinatorios.zip (APK + LEEME.md) para entregar.
#
# Requisitos: Godot 4.7 con las plantillas de exportación,
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
	echo "Créala con:" >&2
	echo "  keytool -genkeypair -keystore $LLAVES/release.keystore -alias ladrillos -keyalg RSA -keysize 2048 -validity 10000" >&2
	echo "y guarda en release.keystore.txt las líneas «alias=ladrillos» y «password=…»." >&2
	exit 1
fi

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$LLAVES/release.keystore"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$(grep '^alias=' "$LLAVES/release.keystore.txt" | cut -d= -f2-)"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(grep '^password=' "$LLAVES/release.keystore.txt" | cut -d= -f2-)"

mkdir -p build/android
"$GODOT" --headless --path . --export-release "Android" build/android/LadrillosCombinatorios.apk
ls -lh build/android/LadrillosCombinatorios.apk

# Paquete de entrega: el APK con un LEEME.md que apunta al repositorio.
ENTREGA="build/entrega"
rm -rf "$ENTREGA" build/LadrillosCombinatorios.zip
mkdir -p "$ENTREGA"
cp build/android/LadrillosCombinatorios.apk "$ENTREGA/"
cat > "$ENTREGA/LEEME.md" <<'FIN'
# Ladrillos Combinatorios

Juego de combinatoria (Unidad III) hecho en Godot.

Repositorio con el código y la explicación:
https://github.com/arstbltech/teoria-combinatoria

## Instalar

1. Pasar `LadrillosCombinatorios.apk` al celular.
2. Abrirlo desde el administrador de archivos.
3. Si Android lo pide, permitir instalar apps de fuentes desconocidas.

Necesita Android 7 o superior con procesador de 64 bits.
FIN
(cd "$ENTREGA" && python3 -m zipfile -c ../LadrillosCombinatorios.zip LadrillosCombinatorios.apk LEEME.md)
ls -lh build/LadrillosCombinatorios.zip
