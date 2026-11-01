#!/usr/bin/env python3
"""Test backup/restore and repeat installs without sudo or real user changes."""
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix='minimal-installer-test-') as tmp:
    home = Path(tmp)
    env = os.environ.copy()
    env['HOME'] = tmp
    for key in ('XDG_CONFIG_HOME', 'XDG_STATE_HOME', 'HYPRLAND_INSTANCE_SIGNATURE'):
        env.pop(key, None)
    target = home / '.config/hypr/hyprland.conf'
    target.parent.mkdir(parents=True)
    original = home / 'original.conf'
    original.write_text('# original test config\n')
    target.symlink_to(original)
    def run(script, *args):
        return subprocess.run([str(root / script), *args], env=env,
                              capture_output=True, text=True, check=True)
    run('install.sh', '--config-only', '--dry-run')
    assert not (home / '.local/state').exists(), 'dry run wrote state'
    for i in range(2):
        run('install.sh', '--config-only', '--no-reload')
        assert not target.is_symlink()
        assert 'minimal-monitor-power' in target.read_text()
        assert original.read_text() == '# original test config\n'
        secret_helper = home / '.config/qutebrowser/userscripts/keyring-login'
        assert secret_helper.stat().st_mode & 0o777 == 0o700
        if i == 0:
            first = (home / '.local/state/minimal-linux-setup/latest-backup').read_text().strip()
    run('restore.sh', first)
    assert target.is_symlink() and target.read_text() == '# original test config\n'
    assert not (home / '.config/qutebrowser/config.py').exists()
print('PASS: dry-run, repeat install, private helper permissions, backup, symlink and restore')
