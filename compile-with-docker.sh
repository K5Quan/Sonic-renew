#!/usr/bin/env bash
clear
set -euo pipefail

IMAGE=uvk1-uvk5v3

# Initialize default variables
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
    RS232|NOCOM|USB|All)
      PRESET="$1"
      shift
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# If no preset was detected in the arguments, use the default value
PRESET=${PRESET:-USB}

# ---------------------------------------------
# Clean up if the option is enabled
# ---------------------------------------------
if [ "$CLEAN_BUILD" = true ]; then
  echo " 🧹 Cleaning build directory..."
  rm -rf build/
fi

# ---------------------------------------------
# Validate preset name
# ---------------------------------------------
if [[ ! "$PRESET" =~ ^(RS232|NOCOM|USB|All)$ ]]; then
  echo "❌ Unknown preset: '$PRESET'"
  echo "Valid presets are: RS232 NOCOM USB All"
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
  local target
  case "$preset" in
    RS232) target="f4hwn.sonic.rs232.V52b" ;;
    NOCOM) target="f4hwn.sonic.NOCOM.V52b" ;;
    *)     target="f4hwn.sonic.USB.V52b" ;; # Default value
  esac
  echo -e "\n 🚀 Building: ${preset}"
  docker run --rm -u $(id -u):$(id -g) -v "$PWD":/src -w /src "$IMAGE" \
  bash -c "cmake --preset ${preset} ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"} && \
           cmake --build --preset ${preset} -j" \
  2>&1 | sed "s|/src/|C:/Perso/Sonic/|g" \
       | sed -E '/^[[:space:]]+[A-Za-z0-9_]+(:[A-Za-z]+)?=/d; /--( Configuring|Generating) done/d; /-- Build files have been written to/d'

  docker run --rm -v "$PWD":/src -w /src "$IMAGE" \
    arm-none-eabi-size "./build/${preset}/${target}.elf"

  echo "✅ Done: ${preset} : $(date +'%H:%M:%S')"
}

# ---------------------------------------------
# Function to flash one preset
# ---------------------------------------------
flash_preset() {
  local preset="$1"
  local target
  case "$preset" in
    RS232) target="f4hwn.sonic.rs232.V52b" ;;
    NOCOM) target="f4hwn.sonic.NOCOM.V52b" ;;
    *)     target="f4hwn.sonic.USB.V52b" ;; # Default value
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
  PRESETS=(RS232 NOCOM USB)
  for p in "${PRESETS[@]}"; do
    build_preset "$p"
  done
  echo ""
  echo "🎉 All presets built successfully!"
  # If 'All' is compiled, flash only the USB preset
  flash_preset "USB"
else
  build_preset "$PRESET"
  flash_preset "$PRESET"
fi
