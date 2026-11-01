# Minimal Linux Setup

Desktop Hyprland berbasis keyboard, tanpa animasi/blur/bayangan, dengan jam dan tanggal saja. Aplikasi utama: Kitty, qutebrowser, Dolphin, mpv, Neovim; audio melalui PipeWire. SSH server dan Tailscale tersedia.

**Instalasi otomatis: Arch Linux dan turunannya yang memakai repositori kompatibel.** Diuji dengan Hyprland 0.56.0 dan qutebrowser 3.7.0. Untuk distro lain, pasang dependensi yang sesuai secara manual lalu gunakan `--config-only`; kompatibilitas paket dan versi tidak dijamin. Ini paket konfigurasi, bukan image OS atau installer distro.

## Instalasi

Salin seluruh folder ini ke laptop tujuan. Jalankan sebagai pengguna desktop biasa, **tanpa `sudo` di depan install.sh**:

```bash
cd minimal-linux-setup
./install.sh --dry-run
./install.sh
```

Installer meminta sudo untuk instalasi paket dan layanan sistem. `pacman -Syu --needed` melakukan pembaruan penuh untuk menghindari ketidakcocokan Qt/PyQt akibat pembaruan parsial. Paket diambil dari repositori laptop tujuan; diperlukan internet. Tidak menggunakan AUR.

Setelah selesai, logout dan pilih sesi **Hyprland** pada login manager yang sudah ada. Jika tidak memakai login manager, login melalui TTY lalu jalankan `Hyprland`. Installer tidak mengganti login manager atau konfigurasi jaringan. Pada instalasi OS baru, jaringan harus disiapkan terlebih dahulu.

Untuk menghubungkan Tailscale pada laptop baru:

```bash
sudo tailscale up
```

Akun dan persetujuan perangkat tetap dilakukan sendiri. Server OpenSSH diaktifkan; setiap laptop menggunakan host key dan otorisasi SSH-nya sendiri. Installer tidak menyalin authorized_keys atau membuka konfigurasi firewall. Jika firewall aktif, akses SSH/Tailscale mungkin perlu diizinkan sesuai jaringanmu.

### Pilihan instalasi

```bash
./install.sh --config-only --no-reload  # Hanya file; tanpa paket, sudo, layanan, atau reload.
./install.sh --no-services             # Paket + konfigurasi; layanan tidak diubah.
./install.sh --trim-services           # Sertakan pemangkasan layanan tambahan.
```

`--dry-run` tidak membuat file atau menjalankan sudo. `--no-reload` menunda konfigurasi compositor sampai login berikutnya. Konfigurasi qutebrowser dibaca saat browser dibuka ulang atau melalui `:config-source`.

`--trim-services` menonaktifkan layanan yang ditemukan:

- Sistem: MariaDB, Ollama, CUPS beserta socket/path-nya.
- Pengguna: Cube Learn frontend, EasyEffects, WhatsApp audio repair, ydotool.

Flag tersebut dapat membuat aplikasi yang bergantung pada layanan itu tidak berfungsi sampai layanan diaktifkan kembali. Default installer **tidak** memangkasnya. Docker, PostgreSQL, container, dan data proyek yang sudah ada tidak diubah; pemangkasan container sebelumnya khusus laptop sumber dan tidak aman untuk diterapkan secara umum.

## Desktop

- Tidak ada panel navigasi, dock, widget, wallpaper bergerak, animasi, blur, atau bayangan.
- Jam/tanggal menggunakan **Waybar clock-only**, menggantikan Quickshell pada laptop sumber. Tidak memerlukan shell desktop lama atau paket Quickshell yang harus dibangun ulang saat Qt berubah.
- Monitor dideteksi otomatis. Pada startup, helper memilih mode sekitar 60 Hz di resolusi saat ini jika monitor menyediakannya; jika tidak, mode awal tetap dipakai. Bukan menyalin nama monitor/resolusi laptop sumber. Untuk HiDPI, skala, rotasi atau tata letak monitor khusus, edit `~/.config/hypr/monitors.conf` dan sesuaikan/nonaktifkan `minimal-monitor-power`.
- Layar dimatikan setelah 10 menit tanpa aktivitas, tetapi laptop tetap menyala. Instalasi normal mengaktifkan inhibitor pengguna serta memblokir sleep, suspend, hibernate, hybrid sleep dan suspend-then-hibernate di sistem. Menutup lid dan idle tidak menyebabkan sleep. Kebijakan lid global berlaku setelah reboot; inhibitor menjaga sesi saat ini. `--config-only`/`--no-services` tidak mengaktifkan kebijakan daya otomatis.
- Hyprlock tersedia untuk kunci layar; listener kecil meneruskan sinyal lock-session sebelum tidur ke Hyprlock. Clock desktop mengikuti timezone laptop tujuan.
- EasyEffects, wallpaper/widget lama, dan proses dari sesi sebelumnya mungkin tetap aktif sampai logout.

| Pintasan | Fungsi |
|---|---|
| Win, lalu Win lagi | Buka/tutup pencarian aplikasi |
| Win+D | Buka/tutup pencarian aplikasi |
| Win+T / Win+Enter | Terminal Kitty |
| Win+B | qutebrowser |
| Win+E | Dolphin |
| Win+N | Neovim di terminal |
| Win+M | mpv; file juga bisa dibuka dari Dolphin |
| Win+H/J/K/L | Fokus kiri/bawah/atas/kanan |
| Win+Shift+H/J/K/L | Pindahkan jendela kiri/bawah/atas/kanan |
| Win+S | Tampilkan/sembunyikan workspace tersembunyi |
| Win+Shift+S / Win+Alt+S | Kirim jendela ke workspace tersembunyi |
| Win+1..9 | Workspace |
| Win+Shift+1..9 | Pindahkan jendela ke workspace |
| Win+Q | Tutup jendela |
| Win+F | Fullscreen |
| Win+Ctrl+L | Kunci layar |
| Win+Shift+E | Keluar sesi |

Tombol volume/kecerahan laptop tetap tersedia. Mouse tetap bisa dipakai. Konfigurasi Kitty dan Neovim pribadi tidak disalin atau diganti; aplikasi baru memakai default jika belum memiliki konfigurasi.

## qutebrowser

- Catppuccin **Mocha**, dari https://github.com/catppuccin/qutebrowser, commit `808adc3d7d5be6fc573d6be6e9c888cb96b5d6e6`. Kode tema dan lisensi upstream disertakan, sehingga instalasi tema tidak perlu mengunduh ulang.
- Google sebagai mesin pencari, halaman awal, dan tab baru.
- **Shift+D** menutup tab. Tombol `d` tidak lagi menutup tab. `u` tetap dapat membuka kembali tab yang baru ditutup.
- Cookie disimpan. Google/reCAPTCHA dikecualikan dari pemblokir konten. Pengecualian ini tidak menjamin CAPTCHA hilang atau Google menerima login.
- Password menggunakan **GNOME Keyring**, bukan file teks biasa. Pada laptop baru, keyring mungkin perlu dibuat/dibuka dahulu lewat dialog sistem.

Pada halaman login HTTPS (atau HTTP localhost), tekan Esc lalu `ps` untuk memasukkan dan menyimpan username/password melalui dialog lokal. Tekan `pf` untuk mengisi formulir; dalam insert mode gunakan Ctrl+Shift+P. Satu akun disimpan per origin (skema, host, port). Menyimpan lagi memperbarui akun pada origin yang sama. Login tidak dikirim otomatis.

Tidak ada popup simpan otomatis atau impor password Firefox. Formulir khusus/iframe mungkin memerlukan pengisian manual. Password tidak masuk clipboard, argumen proses, atau perintah FIFO. Pengisian memakai file privat di runtime RAM selama sekitar lima detik, lalu menghapusnya. Cookie/sesi dapat berakhir sesuai kebijakan situs.

## Backup dan pemulihan

Sebelum setiap file diganti, installer menyimpan versi sebelumnya termasuk symlink ke:

```text
~/.local/state/minimal-linux-setup/backups/<timestamp>-<acak>/
```

Instalasi ulang membuat backup baru. Pulihkan konfigurasi terakhir:

```bash
./restore.sh
```

Atau pilih backup tertentu; tambahkan `--services` untuk memulihkan status layanan yang dicatat (meminta sudo untuk layanan sistem):

```bash
./restore.sh /path/ke/backup --services
```

Setiap backup juga berisi salinan restore.sh. Setelah pemulihan, logout/login untuk mengganti proses sesi. Pemulihan tidak menghapus paket yang telah dipasang, tidak membatalkan pembaruan OS, dan tidak mengembalikan login/keyring browser.

## Batas cakupan dan data pribadi

Buku Kas tidak disertakan, termasuk source code, container, konfigurasi database, URL Tailscale, maupun kredensialnya. Paket ini juga tidak membawa password, cookie/history, database keyring, SSH key, akun Tailscale, atau konfigurasi monitor/jaringan laptop sumber. Layanan/aplikasi lain yang sudah terpasang tidak dihapus otomatis.

## Pemeriksaan

```bash
bash -n install.sh restore.sh
python3 tests/test_installer.py
```

Tes menggunakan HOME sementara dan tidak memasang paket atau mengubah layanan sistem. Pemeriksaan Hyprland dan startup qutebrowser dilakukan di laptop sumber; instalasi paket/layanan melalui sudo dan mesin fisik lain belum diuji.

## Selalu menyala (tanpa sleep/hibernate)

Instalasi normal menjalankan `sudo bash ./power.sh apply`. Untuk menerapkan kebijakan ini saja pada laptop yang sudah dikonfigurasi:

```bash
sudo bash ./power.sh apply
```

Layanan user `keep-awake.service` menjaga laptop selama sesi user berjalan, termasuk mengabaikan lid. Mask target systemd dan konfigurasi sleep mempertahankan larangan suspend/hibernate di luar sesi user. Tidak mengubah tombol power, emergency shutdown, atau perlindungan baterai habis. Laptop tetap dapat dimatikan/reboot secara manual dan dapat mati saat baterai habis. Layar boleh mati tanpa menghentikan proses. Jangan menyimpan laptop yang masih menyala di tas tertutup.

File daya sebelumnya dan mask systemd dicadangkan di `/var/lib/minimal-linux-setup/power/backups`. Pemulihan kebijakan daya dilakukan **terpisah** dari `restore.sh`:

```bash
systemctl --user disable --now keep-awake.service
sudo bash ./power.sh restore
```

Reboot setelah pemulihan agar kebijakan lid/idle lama dimuat kembali. `power.sh restore` memulihkan backup daya terakhir; jalankan satu kali untuk membatalkan penerapan terakhir. Skrip daya membutuhkan sudo dan belum dijalankan di laptop sumber karena sudo meminta password pengguna.
