#!/usr/bin/env bash
clear
set -euo pipefail

IMAGE=uvk1-uvk5v3

# Initialisation des variables par défaut
CLEAN_BUILD=false
EXTRA_ARGS=()
PRESET=""

# Boucle pour analyser TOUS les arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--clean)
      CLEAN_BUILD=true
      shift
      ;;
    NOCOM|CHIRP|All)
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
PRESET=${PRESET:-CHIRP}

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
if [[ ! "$PRESET" =~ ^(NOCOM|CHIRP|All)$ ]]; then
  echo "❌ Unknown preset: '$PRESET'"
  echo "Valid presets are: NOCOM CHIRP All"
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
  local target="f4hwn.sonic.chirp.v50"
  if [[ "$preset" == "NOCOM" ]]; then
    target="f4hwn.sonic.nocom.v50"
  fi
  echo -e "\n 🚀 Building: ${preset}"
  docker run --rm -u $(id -u):$(id -g) -v "$PWD":/src -w /src "$IMAGE" \
  bash -c "cmake --preset ${preset} ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} && \
           cmake --build --preset ${preset} -j" \
  2>&1 | sed "s|/src/|C:/Perso/Sonic/|g" \
       | sed -E '/^[[:space:]]+[A-Za-z0-9_]+(:[A-Za-z]+)?=/d; /--( Configuring|Generating) done/d; /-- Build files have been written to/d'

  docker run --rm -v "$PWD":/src -w /src "$IMAGE" \
    arm-none-eabi-size "./build/${preset}/${target}.elf"

  echo "✅ Done: ${preset}"
}

# ---------------------------------------------
# Function to flash one preset
# ---------------------------------------------
flash_preset() {
  local preset="$1"
  local target
  case "$preset" in
    RS232) target="f4hwn.sonic.rs232.v50" ;;
    NOCOM) target="f4hwn.sonic.nocom.v50" ;;
    *)     target="f4hwn.sonic.chirp.v50" ;; # Valeur par défaut
  esac
  local ifile="./build/${preset}/${target}.bin"

  echo -e "\n⚡ Flashing ${preset} firmware on COM14..."

  if [[ -f "$ifile" ]]; then
      python flash.py "$ifile" -p COM14
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
  PRESETS=(NOCOM CHIRP)
  for p in "${PRESETS[@]}"; do
    build_preset "$p"
  done
  echo ""
  echo "🎉 All presets built successfully!"

  # Si 'All' est compilé, on flashe uniquement le preset CHIRP
  flash_preset "CHIRP"
else
  build_preset "$PRESET"
  flash_preset "$PRESET"
fi
