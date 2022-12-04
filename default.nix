{ stdenv, fetchFromGitHub, callPackage }:

let
  csound7Sources = fetchFromGitHub {
    owner = "csound";
    repo = "csound";
    rev = "c9b5c8e939cc47156dc412a11a28d7f0d9632a61";
    sha256 = "sha256-kWUeoXOS7fedYQCIaz/Kcb/vk2rJbCzryApQdHe67Lo=";
  };

  wasi-sdk = callPackage "${csound7Sources}/wasm/src/wasi-sdk.nix" { };
  csound-wasm = callPackage "${csound7Sources}/wasm/src/csound.nix" {};

in stdenv.mkDerivation {
  name = "hypercurve-wasm-plugin";
  buildInputs = [ csound-wasm ];

  src =  ./.;
  dontStrip = true;

  buildPhase = ''

    echo "Compile hypercurve.wasm"
    ${wasi-sdk}/bin/clang  \
      -fPIC -fno-exceptions -fno-rtti \
      --target=wasm32-unknown-emscripten \
      --sysroot=${wasi-sdk}/share/wasi-sysroot \
      -D__wasi__=1 \
      -D__wasm32__=1 \
      -D_WASI_EMULATED_SIGNAL \
      -D_WASI_EMULATED_MMAN \
      -DUSE_DOUBLE=1 \
      -I${csound-wasm}/include \
      -I${wasi-sdk}/share/wasi-sysroot/include \
      -I${wasi-sdk}/share/wasi-sysroot/include/c++/v1 \
      -I./src \
      -x c++ \
      -c  \
      src/hypercurve.h

    ${wasi-sdk}/bin/wasm-ld \
      -z stack-size=128 \
      -pie --no-entry \
      --experimental-pic \
      --import-table \
      --import-memory \
      --export=__wasm_call_ctors \
      --export=csoundModuleInit \
      --export-if-defined=csoundModuleCreate \
      --export-if-defined=csoundModuleDestroy \
      -L${wasi-sdk}/share/wasi-sysroot/lib/wasm32-unknown-emscripten \
      -L${csound-wasm}/lib -lcsound-wasm \
      -lc -lc++ -lc++abi -lrt -lutil -lxnet -lresolv -lc-printscan-long-double \
      -lwasi-emulated-getpid -lwasi-emulated-signal -lwasi-emulated-mman -lwasi-emulated-process-clocks \
      *.o -o hypercurve.wasm

  '';

  installPhase = ''
    mkdir -p $out/lib
    cp ./hypercurve.wasm $out/lib
  '';
}
