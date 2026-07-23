# Per-core EPP boost for the AMD P-State driver.
#
# RFC: https://lore.kernel.org/linux-pm/20260728073150.54964-1-void@manifault.com/
# Phoronix: https://www.phoronix.com/news/AMD-P-State-Better-1p-Lows
#
# When amd_pstate.epp_boost=1 is set, an update-util hook samples each core's
# C0 residency every 10ms. If a core is >=50% busy, EPP is temporarily set to
# performance (0) on that core's MSR, restoring the policy value after 300ms
# of idle. This prevents frequency droop after short sleeps (futex/GPU fence
# waits) common in game render threads.
#
# Only patches 1-3 of 4 are needed — patch 4 is documentation-only.

{ lib, config, ... }:

let
  patches = [
    ./patches/0001-cpufreq-amd-pstate-Document-missing-kernel-doc-members.patch
    ./patches/0002-cpufreq-amd-pstate-Update-cppc_req_cached-before-writing-the-MSR.patch
    ./patches/0003-cpufreq-amd-pstate-Add-per-core-EPP-boost-for-recently-busy-CPUs.patch
  ];
in
{
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      cachyosKernels = prev.cachyosKernels // {
        "linuxPackages-cachyos-${config.icedos.hardware.kernel.variant}" =
          prev.cachyosKernels."linuxPackages-cachyos-${config.icedos.hardware.kernel.variant}".extend
            (
              self: super: {
                kernel = super.kernel.overrideAttrs (old: {
                  patches = (old.patches or [ ]) ++ patches;
                });
              }
            );
      };
    })
  ];

  boot.kernelParams = [ "amd_pstate.epp_boost=1" ];
}
