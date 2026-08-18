{ icedosLib, lib, ... }:

{
  options.icedos.applications.shadps4-guest =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.applications.shadps4-guest)
        userId
        gameDir
        cacheDir
        ;

      inherit (icedosLib) mkNumberOption mkStrOption;
    in
    {
      # Local shadPS4 user id (users.json) pinned via --user-id.
      userId = mkNumberOption { default = userId; };
      gameDir = mkStrOption { default = gameDir; };
      cacheDir = mkStrOption { default = cacheDir; };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          pkgs,
          ...
        }:
        let
          inherit (config.icedos.applications.shadps4-guest)
            userId
            gameDir
            cacheDir
            ;
        in
        {
          environment.systemPackages = [
            (pkgs.writeShellApplication {
              name = "shadnet-guest";

              runtimeInputs = [
                pkgs.coreutils
                pkgs.procps
                pkgs.util-linux
              ];

              text = ''
                # Launch the second (guest) shadPS4 instance: local user with its own
                # shader cache. Auto-starts the shadnet
                # server if it is not running. Runs detached - closing the terminal
                # does not kill it.
                set -u

                GAME_DIR="${gameDir}"
                GUEST_USER_ID="${toString userId}"
                GUEST_CACHE_DIR="$HOME/${cacheDir}"
                LOG="''${XDG_RUNTIME_DIR:-/tmp}/shadps4-guest.log"

                mkdir -p "$GUEST_CACHE_DIR"
                  setsid nohup env SHADPS4_BLOODBORNE_SEAMLESS_COOP=1 \
                  /run/current-system/sw/bin/shadps4 \
                  --user-id "$GUEST_USER_ID" \
                  --cache-dir "$GUEST_CACHE_DIR" \
                  -g "$GAME_DIR" > "$LOG" 2>&1 &
                echo "guest instance launched (pid $!), log: $LOG"
              '';
            })
          ];
        }
      )
    ];
}
