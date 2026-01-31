{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        { pkgs, ... }:
        {
          # shortcut: vendored pgzip 1.2.6 panics on `docker cp` (podman#29944), drop once podman vendors pgzip > 1.2.6
          virtualisation.podman.package = pkgs.podman.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./pgzip-roff.patch ];
          });
        }
      )
    ];

  meta.name = "podman-pgzip-fix";
}
