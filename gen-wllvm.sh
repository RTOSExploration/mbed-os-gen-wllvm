#!/usr/bin/env bash
# Build wllvm for mbed projects

compile() {
  DB="$RTOSExploration/bitcode-db/mbed-os/$1"
  [ -f "$DB/DONE" ] && echo "Skip $DB" && return
  mkdir -p "$DB"

  cd "$1"
  mbed-tools compile -m K64F -t GCC_ARM --clean # --clean forces a rebuild

  for elf in $(find . -name "*.elf"); do
    echo "ELF $elf"
    extract-bc "$elf" && "$LLVM_COMPILER_PATH/llvm-dis" "$elf.bc" && \
      cp --backup=numbered "$elf.bc" "$elf.ll" "$DB"
  done

  rm -rf cmake_build/
  touch "$DB/DONE"
  cd -
}

. .venv/bin/activate
#export PATH="$(realpath ../gcc-arm-none-eabi-9-2019-q4-major/bin/):$PATH"
#export CCACHE_DISABLE=1 # disabled in ~/.ccache/ccache.conf
export PATH="$RTOSExploration/bin-wrapper:$PATH"
export WLLVM_OUTPUT_LEVEL=INFO \
       LLVM_COMPILER=hybrid \
       LLVM_COMPILER_PATH=/usr/lib/llvm-14/bin \
       GCC_PATH="$RTOSExploration/toolchain/gcc-arm-none-eabi-9-2019-q4-major/bin/" \
       GCC_CROSS_COMPILE_PREFIX=arm-none-eabi- \
       LLVM_BITCODE_GENERATION_FLAGS="-Wno-c++11-narrowing"
for SRC_DIR in $(find . -type d -exec test -f '{}'/CMakeLists.txt \; -print -prune); do
  echo $SRC_DIR
  compile $SRC_DIR
done
