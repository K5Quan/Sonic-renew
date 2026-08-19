#!/usr/bin/env bash
clear
set -euo pipefail

source load_settings.sh

# Initialisation des variables par défaut
CLEAN_BUILD=false
EXTRA_ARGS=()
PRESET=""
FLASH=true

# Boucle pour analyser TOUS les arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-auto-flash)
      FLASH=false
      shift
      ;;
    -c|--clean)
      CLEAN_BUILD=true
      shift
      ;;
    NOCOM|USB|RS232|All)
      PRESET="$1"
      shift
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# Si aucun preset n'a été détecté dans les arguments, on met la valeur par défaut
PRESET=${PRESET:-USB}

# ---------------------------------------------
# Nettoyage si l'option est activée
# ---------------------------------------------
if [ "$CLEAN_BUILD" = true ]; then
  echo " 🧹 Cleaning build directory..."
  rm -rf build/
fi

# ---------------------------------------------
# Validate preset name
# ---------------------------------------------
if [[ ! "$PRESET" =~ ^(NOCOM|USB|RS232|All)$ ]]; then
  echo "❌ Unknown preset: '$PRESET'"
  echo "Valid presets are: NOCOM USB RS232 All"
  exit 1
fi

# ---------------------------------------------
# Build the Docker image (only needed once)
# ---------------------------------------------
if [[ "$(docker images -q $IMAGE)" == "" ]]; then
  echo "Building Docker image..."
  docker build -t "$IMAGE" .
fi

export MSYS_NO_PATHCONV=1

# ---------------------------------------------
# Function to build one preset
# ---------------------------------------------
build_preset() {
  local preset="$1"
  echo -e "\n 🚀 Building: ${preset}"
  docker run \
    --rm \
    -u $(id -u):$(id -g) \
    -v "$PWD":/src \
    -w /src \
    -e VERSION_STRING_2=${VERSION_NO} \
    "$IMAGE" \
    bash -c "cmake --preset ${preset} -DTARGET=SONIC.${preset}.${VERSION_NO} -DVERSION_STRING_1=${VERSION_NO} -DVERSION_STRING_2=${VERSION_NO} ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} && \
             cmake --build --preset ${preset} -j" \
  2>&1 | sed "s|/src/|C:/Perso/Sonic/|g" \
       | sed -E '/^[[:space:]]+[A-Za-z0-9_]+(:[A-Za-z]+)?=/d; /--( Configuring|Generating) done/d; /-- Build files have been written to/d'

  docker run --rm -v "$PWD":/src -w /src "$IMAGE" \
    arm-none-eabi-size ./build/${preset}/SONIC.${preset}.${VERSION_NO}.elf

  echo "✅ Done: ${preset}"
}

# ---------------------------------------------
# Function to flash one preset
# ---------------------------------------------
flash_preset() {
  local preset="$1"
  local ifile="./build/${preset}/SONIC.${preset}.${VERSION_NO}.bin"

  echo -e "\n⚡ Flashing ${preset} firmware on ${UPLOAD_PORT}..."

  if [[ -f "$ifile" ]]; then
      python flash.py "$ifile" -p ${UPLOAD_PORT}
      echo "✅ Flash ${preset} terminé avec succès !"
  else
      echo "❌ Erreur : Le fichier binaire est introuvable : $ifile"
      exit 1
  fi
}

# ---------------------------------------------
# Handle Build & Flash
# ---------------------------------------------
if [[ "$PRESET" == "All" ]]; then
  PRESETS=(NOCOM USB RS232)
  for p in "${PRESETS[@]}"; do
    build_preset "$p"
  done
  echo ""
  echo "🎉 All presets built successfully!"

  # Si 'All' est compilé, on flashe uniquement le preset USB
  if [ "$FLASH" = true ]; then
    flash_preset "USB"
  fi;
else
  build_preset "$PRESET"
  if [ "$FLASH" = true ]; then
    flash_preset "$PRESET"
  fi;
fi
