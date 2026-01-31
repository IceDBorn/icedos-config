{ icedosLib, ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        { pkgs, ... }:

        let
          ddevBin = "${pkgs.ddev}/bin/ddev";
        in
        {
          environment.systemPackages = [ pkgs.ddev ];

          # ddev reaches podman through its Docker-compatible socket; users need the podman group.
          virtualisation.podman = {
            enable = true;
            dockerCompat = true;
            dockerSocket.enable = true;
          };

          users.users.ice.extraGroups = [ "podman" ];

          icedos.system.toolset.commands = [
            {
              command = "dtek";
              help = "print dtek related commands";

              commands = [
                {
                  command = "ddev";
                  help = "print ddev related commands";

                  commands = [
                    {
                      command = "start";
                      help = "start development server";
                      script = ''
                        ${ddevBin} poweroff
                        ${ddevBin} start
                        ${ddevBin} mailpit
                      '';
                    }
                    {
                      command = "stop";
                      help = "stop development server";
                      script = "${ddevBin} poweroff";
                    }
                    {
                      command = "delete";
                      help = "delete project from ddev";
                      script = "${ddevBin} delete --omit-snapshot";
                    }
                    {
                      command = "db";
                      help = "database related commands";
                      commands = [
                        {
                          command = "import";
                          help = "import database from file";
                          script = ''${ddevBin} import-db --file="$1"'';
                          completion.files = true;
                        }
                        {
                          command = "info";
                          help = "print database info";
                          script = "${ddevBin} describe | grep --color=never db";
                        }
                      ];
                    }
                  ];
                }

                {
                  command = "xml-image-tester";
                  help = "curl all XML image urls and print HTTP status codes";

                  script = ''
                    if [ "$1" == "" ]; then
                      echo "${icedosLib.bash.redString "error:"} XML feed url missing"
                      exit 1
                    fi

                    # Get image urls
                    curl -s "$1" > /tmp/feed.xml
                    grep -oE 'https?://[^<]+\.(jpg|jpeg|png|gif|webp)' /tmp/feed.xml | sort -u > /tmp/urls.txt
                    wc -l /tmp/urls.txt

                    declare -A counts
                    : > /tmp/probe.log
                    total=$(wc -l < /tmp/urls.txt)
                    i=0

                    while read -r u; do
                      code=$(curl -s -o /dev/null -w '%{http_code}' \
                        -A "''${2:-Skroutz ImageBot v1}" --max-time 20 "$u")
                      echo "$code $u" >> /tmp/probe.log
                      counts[$code]=$((''${counts[$code]:-0} + 1))
                      i=$((i+1))
                      summary=""
                      for k in $(printf '%s\n' "''${!counts[@]}" | sort); do
                        summary+="$k: ''${counts[$k]}, "
                      done
                      printf '\r[%d/%d] %s' "$i" "$total" "''${summary%, }"
                    done < /tmp/urls.txt
                    printf '\n'
                  '';
                }
              ];
            }
          ];
        }
      )
    ];

  meta.name = "ddev";
}
