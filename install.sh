#!/usr/bin/env bash
set -euo pipefail
umask 077
SETUP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_only=0; dry_run=0; trim_services=0; no_services=0; no_reload=0
usage() {
    cat <<'EOF'
Usage: ./install.sh [options]
  --dry-run        Show planned changes; do not modify anything or invoke sudo.
  --config-only    Copy configuration only; skip packages and all services.
  --trim-services Disable MariaDB, Ollama, CUPS and old user desktop/project services.
                  Does NOT touch Docker, PostgreSQL, containers or data.
  --no-services   Install packages/configs without changing services.
  --no-reload     Apply on next login instead of reloading a running Hyprland.
  -h, --help      Show help.
Run as the desktop user, without sudo. Arch package installation uses sudo internally.
EOF
}
for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=1;;
        --config-only) config_only=1;;
        --trim-services) trim_services=1;;
        --no-services) no_services=1;;
        --no-reload) no_reload=1;;
        -h|--help) usage; exit 0;;
        *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2;;
    esac
done
if (( EUID == 0 )); then echo 'Run as your desktop user, not root/sudo.' >&2; exit 1; fi
if [[ ${XDG_CONFIG_HOME:-$HOME/.config} != "$HOME/.config" ]]; then
    echo 'This bundle currently uses ~/.config; custom XDG_CONFIG_HOME is unsupported.' >&2; exit 1
fi
if ((config_only && trim_services)); then
    echo '--config-only cannot be combined with --trim-services.' >&2; exit 2
fi
if ((no_services && trim_services)); then
    echo '--no-services cannot be combined with --trim-services.' >&2; exit 2
fi
mapfile -t packages < <(sed '/^[[:space:]]*#/d; /^[[:space:]]*$/d' "$SETUP_DIR/packages.arch.txt")
if ((!config_only)); then
    if ! command -v pacman >/dev/null; then
        echo 'Automatic installation supports Arch Linux and derivatives. Use --config-only elsewhere.' >&2
        exit 1
    fi
fi
printf 'Target home: %s\n' "$HOME"
printf 'Configuration files: %s\n' "$(find "$SETUP_DIR/files" -type f | wc -l)"
if ((!config_only)); then
    printf 'Packages (full upgrade to keep Qt dependencies consistent):\n'
    printf '  %s\n' "${packages[@]}"
fi
if ((!config_only && !no_services)); then
    echo 'Enable SSH, Tailscale, audio and keep-awake; block system sleep/hibernate.'
    ((trim_services)) && echo 'Disable optional services listed in README.md.'
fi
if ((dry_run)); then echo 'Dry run finished. Nothing changed.'; exit 0; fi

# Finish package installation before replacing the desktop configuration.
if ((!config_only)); then sudo pacman -Syu --needed -- "${packages[@]}"; fi
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/minimal-linux-setup"
mkdir -p -- "$state_dir/backups"
backup=$(mktemp -d "$state_dir/backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")
mkdir -p -- "$backup/files"
: > "$backup/files.tsv"; : > "$backup/services.tsv"
printf '%s\n' "$backup" > "$state_dir/latest-backup"
# Keep a copy of restore.sh with each backup so recovery survives deleting this bundle.
cp -- "$SETUP_DIR/restore.sh" "$backup/restore.sh"
trap 'echo "Installation failed. Backup: $backup. Restore with: bash \"$backup/restore.sh\" \"$backup\"" >&2' ERR
while IFS= read -r -d '' source; do
    rel=${source#"$SETUP_DIR/files/"}
    dest="$HOME/$rel"
    if [[ -e "$dest" || -L "$dest" ]]; then
        mkdir -p -- "$backup/files/$(dirname -- "$rel")"
        cp -a -- "$dest" "$backup/files/$rel"
        printf 'existing\t%s\n' "$rel" >> "$backup/files.tsv"
    else
        printf 'new\t%s\n' "$rel" >> "$backup/files.tsv"
    fi
    mkdir -p -- "$(dirname -- "$dest")"
    # Replace a symlink instead of following it into a dotfiles checkout.
    cp --remove-destination -- "$source" "$dest"
    case "$rel" in
        .local/bin/*|.config/qutebrowser/userscripts/*) chmod 700 -- "$dest";;
        *) chmod 600 -- "$dest";;
    esac
done < <(find "$SETUP_DIR/files" -type f -print0 | sort -z)

record_service() {
    local scope=$1 unit=$2 enabled active
    local -a command=(systemctl)
    [[ $scope == user ]] && command+=(--user)
    enabled=$("${command[@]}" is-enabled "$unit" 2>/dev/null || true)
    active=$("${command[@]}" is-active "$unit" 2>/dev/null || true)
    printf '%s\t%s\t%s\t%s\n' "$scope" "$unit" "${enabled:-not-found}" "${active:-inactive}" >> "$backup/services.tsv"
}
if ((!config_only && !no_services)); then
    systemctl --user daemon-reload
    for unit in sshd.service tailscaled.service; do
        record_service system "$unit"
        sudo systemctl enable --now "$unit"
    done
    for unit in pipewire.socket pipewire-pulse.socket wireplumber.service keep-awake.service; do
        record_service user "$unit"
        systemctl --user enable --now "$unit"
    done
    sudo bash "$SETUP_DIR/power.sh" apply
    if ((trim_services)); then
        for unit in mariadb.service ollama.service cups.service cups.socket cups.path; do
            if systemctl cat "$unit" >/dev/null 2>&1; then
                record_service system "$unit"
                sudo systemctl disable --now "$unit"
            fi
        done
        for unit in cube-learn.service easyeffects.service whatsapp-audio-repair.service ydotool.service; do
            if systemctl --user cat "$unit" >/dev/null 2>&1; then
                record_service user "$unit"
                systemctl --user disable --now "$unit"
            fi
        done
    fi
fi
if ((!no_reload)) && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null; then
    hyprctl reload
    errors=$(hyprctl configerrors)
    if [[ -n ${errors//[[:space:]]/} ]]; then
        printf 'Hyprland configuration errors:\n%s\nRestore: bash "%s/restore.sh" "%s"\n' "$errors" "$backup" "$backup" >&2
        exit 1
    fi
fi
printf '\nInstalled. Backup: %s\n' "$backup"
echo 'Log out and choose Hyprland, or run Hyprland from a TTY.'
echo 'Existing panels/background processes stop on logout; the new clock starts on login.'
echo 'Tailscale account setup on a new laptop: sudo tailscale up'
echo 'Network configuration and display/login manager have been left as configured on this laptop.'
