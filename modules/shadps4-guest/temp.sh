                set -u

                GAME_DIR="/home/ice/games/bloodborne/CUSA03173"
                GUEST_USER_ID="1001"
                GUEST_CACHE_DIR="$HOME/.cache/shadps4-joanna"
                LOG="${XDG_RUNTIME_DIR:-/tmp}/shadps4-guest.log"

                mkdir -p "$GUEST_CACHE_DIR"
                setsid nohup env SHADPS4_BLOODBORNE_SEAMLESS_COOP=1 \
                  /run/current-system/sw/bin/shadps4 \
                  --user-id "$GUEST_USER_ID" \
                  --cache-dir "$GUEST_CACHE_DIR" \
                  -g "$GAME_DIR" > "$LOG" 2>&1 &
                echo "guest instance launched (pid $!), log: $LOG"
