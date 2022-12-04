#!/usr/bin/env bash

nix-build -E "let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./default.nix {}" \
  && cp result/lib/hypercurve.wasm . && chown `whoami` hypercurve.wasm
