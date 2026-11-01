#!/usr/bin/env bash
# Persistent system power policy, separate from user-session inhibitors.
set -euo pipefail
umask 077
if ((EUID != 0)); then echo 'Run: sudo ./power.sh apply (or restore)' >&2; exit 1; fi
state=/var/lib/minimal-linux-setup/power
files=(etc/systemd/logind.conf.d/90-minimal-always-on.conf etc/systemd/sleep.conf.d/90-minimal-always-on.conf)
targets=(sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target)
for unit in "${targets[@]}"; do files+=("etc/systemd/system/$unit"); done
case ${1:-apply} in
 apply)
    mkdir -p "$state/backups"
    backup=$(mktemp -d "$state/backups/$(date +%Y%m%d-%H%M%S)-XXXXXX")
    mkdir -p "$backup/files"
    for rel in "${files[@]}"; do
        if [[ -e /$rel || -L /$rel ]]; then
            [[ ! -d /$rel ]] || { echo "Unexpected directory: /$rel" >&2; exit 1; }
            mkdir -p "$backup/files/$(dirname "$rel")"
            cp -a -- "/$rel" "$backup/files/$rel"
        fi
    done
    printf '%s\n' "$backup" > "$state/latest-backup"
    mkdir -p /etc/systemd/logind.conf.d /etc/systemd/sleep.conf.d
    cat > /etc/systemd/logind.conf.d/90-minimal-always-on.conf <<'EOF'
[Login]
IdleAction=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
EOF
    cat > /etc/systemd/sleep.conf.d/90-minimal-always-on.conf <<'EOF'
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowHybridSleep=no
AllowSuspendThenHibernate=no
EOF
    chmod 644 /etc/systemd/{logind,sleep}.conf.d/90-minimal-always-on.conf
    systemctl mask "${targets[@]}"
    systemctl daemon-reload
    echo "System sleep/hibernate disabled. Backup: $backup"
    echo 'Sleep targets are blocked now. Lid/idle policy loads at next reboot; the user inhibitor covers the current session.'
    ;;
 restore)
    [[ -f $state/latest-backup ]] || { echo 'No power backup found.' >&2; exit 1; }
    backup=$(cat "$state/latest-backup")
    [[ -d $backup/files ]] || exit 1
    for rel in "${files[@]}"; do
        rm -f -- "/$rel"
        if [[ -e $backup/files/$rel || -L $backup/files/$rel ]]; then
            mkdir -p "/$(dirname "$rel")"
            cp -a -- "$backup/files/$rel" "/$rel"
        fi
    done
    systemctl daemon-reload
    echo 'Previous power files and masks restored. Reboot to reload lid/idle policy.'
    ;;
 *) echo 'Usage: sudo ./power.sh {apply|restore}' >&2; exit 2;;
esac
