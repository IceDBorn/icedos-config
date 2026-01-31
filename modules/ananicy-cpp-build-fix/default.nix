# Build fix for ananicy-cpp 1.2.0 against glibc 2.42 / gcc 15 (nixos-unstable).
#
# Failure (builder exit code 2, clang 21.1.8 + glibc 2.42-67):
#   backtrace.cpp:12: error: no type named 'int32_t' in namespace 'std'
#   argument.cpp:24: error: no member named 'memset' in namespace 'std'
#   singleton_process.cpp: error: no member named 'strerror'/'memset' in namespace 'std'
#
# Root cause: those sources use std::int32_t / std::memset / std::strerror
# without including <cstdint>/<cstring>. With libstdc++ 15 + glibc 2.42 the
# fixed-width typedefs and C string functions are no longer pulled in
# transitively (and spdlog is consumed as a compiled lib, so its header-only
# <cstring> pull-in is gone too). Upstream ananicy-cpp master still has the
# same includes as v1.2.0, so this is patched locally until upstream fixes it.

{ lib, ... }:

let
  patch = ./patches/0001-add-missing-cstdint-cstring-includes.patch;
in
{
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      ananicy-cpp = prev.ananicy-cpp.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ patch ];
      });
    })
  ];
}
