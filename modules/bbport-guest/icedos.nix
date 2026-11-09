{ icedosLib, lib, ... }:

{
  options.icedos.applications.bbport-guest =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.applications.bbport-guest)
        app0
        configDir
        dataDir
        gttMiB
        ;

      inherit (icedosLib) mkNumberOption mkStrOption;
    in
    {
      app0 = mkStrOption { default = app0; };
      configDir = mkStrOption { default = configDir; };
      dataDir = mkStrOption { default = dataDir; };
      gttMiB = mkNumberOption { default = gttMiB; };
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
          inherit (config.icedos.applications.bbport-guest)
            app0
            configDir
            dataDir
            gttMiB
            ;
        in
        {
          # Each instance maps about 6 GiB of game memory into GTT; the default limit (half of RAM) fits only one.
          boot.kernelParams = [ "ttm.pages_limit=${toString (gttMiB * 256)}" ];

          environment.systemPackages = [
            (pkgs.writeShellApplication {
              name = "bbport-guest";

              runtimeInputs = [
                pkgs.coreutils
                pkgs.jq
                pkgs.util-linux
              ];

              text = ''
                # Launch a second bbport game with its own launcher settings (account) and data
                # (saves, bbport.ini, caches). Runs detached, so closing the terminal does not kill it.
                # --settings opens the guest's launcher window instead; close the main one first,
                # since a second launcher only raises the window that is already open.
                set -u

                # MangoHud looks under XDG_CONFIG_HOME, so pin it to the host config before overriding.
                export MANGOHUD_CONFIGFILE="''${MANGOHUD_CONFIGFILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud/MangoHud.conf}"
                export XDG_CONFIG_HOME="$HOME/${configDir}"
                export BB_DATA_DIR="$HOME/${dataDir}"
                SETTINGS="$XDG_CONFIG_HOME/bbport-launcher/settings.json"
                LOG="''${XDG_RUNTIME_DIR:-/tmp}/bbport-guest.log"

                mkdir -p "''${SETTINGS%/*}" "$BB_DATA_DIR"
                if [ ! -e "$SETTINGS" ]; then
                  (umask 077; jq -n --arg dir "${app0}" '{game_dir: $dir}' > "$SETTINGS")
                fi

                if [ "''${1:-}" = --settings ]; then
                  exec ${lib.getExe pkgs.bbport}
                fi

                setsid nohup ${lib.getExe pkgs.bbport} "$@" > "$LOG" 2>&1 &
                echo "guest instance launched (pid $!), log: $LOG"
              '';
            })
          ];
        }
      )
    ];
}
