#!/usr/bin/env bash
set -euo pipefail
if ((EUID == 0)); then echo 'Run as the original desktop user, without sudo.' >&2; exit 1; fi
backup=${1:-}
restore_services=0
[[ ${2:-} == --services ]] && restore_services=1
if [[ -z $backup ]]; then
    latest="${XDG_STATE_HOME:-$HOME/.local/state}/minimal-linux-setup/latest-backup"
    [[ -f $latest ]] || { echo 'No backup found. Usage: ./restore.sh /path/to/backup [--services]' >&2; exit 1; }
    backup=$(cat -- "$latest")
fi
[[ -f $backup/files.tsv ]] || { echo 'Invalid backup.' >&2; exit 1; }
if ((restore_services)) && [[ -f $backup/services.tsv ]]; then
    while IFS=$'\t' read -r scope unit enabled active; do
        [[ $enabled == not-found ]] && continue
        command=(systemctl)
        case "$scope" in user) command+=(--user);; system) command=(sudo systemctl);; *) exit 1;; esac
        case "$enabled" in enabled) "${command[@]}" enable "$unit";; disabled) "${command[@]}" disable "$unit";; esac
        case "$active" in active) "${command[@]}" start "$unit";; inactive|failed) "${command[@]}" stop "$unit";; esac
    done < "$backup/services.tsv"
fi
while IFS=$'\t' read -r status rel; do
    # Restrict recovery to paths owned by this bundle.
    case "$rel" in .config/*|.local/bin/*) ;; *) echo 'Invalid manifest path.' >&2; exit 1;; esac
    [[ $rel != *'/../'* && $rel != */.. ]] || exit 1
    dest="$HOME/$rel"
    if [[ $status == existing ]]; then
        [[ -e $backup/files/$rel || -L $backup/files/$rel ]] || { echo "Missing backup: $rel" >&2; exit 1; }
        rm -f -- "$dest"
        mkdir -p -- "$(dirname -- "$dest")"
        cp -a -- "$backup/files/$rel" "$dest"
    elif [[ $status == new ]]; then
        rm -f -- "$dest"
    else
        echo 'Invalid manifest entry.' >&2; exit 1
    fi
done < "$backup/files.tsv"
systemctl --user daemon-reload 2>/dev/null || true

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null; then hyprctl reload; fi
echo 'Configuration restored. Log out/in to restore session processes.'
echo 'Installed packages were retained. Service states restore only with --services.'
