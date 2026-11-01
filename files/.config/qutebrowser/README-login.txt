Tema: Catppuccin Mocha (https://github.com/catppuccin/qutebrowser)
Search default: Google. Tekan o, ketik kata pencarian, Enter.

Login tersimpan menggunakan GNOME Keyring yang sudah tersedia.
Tidak perlu memasang password manager tambahan.

1. Buka situs login (HTTPS, atau localhost untuk aplikasi lokal).
2. Tekan Esc agar masuk normal mode, lalu tekan p kemudian s.
3. Masukkan username/email dan password di dialog lokal.
4. Saat ada formulir password, tekan Esc lalu p kemudian f untuk mengisinya.
   Dalam insert mode, gunakan Ctrl+Shift+P.
5. Klik/tekan tombol login sendiri. Tidak ada submit otomatis.

Satu akun per origin (skema + hostname + port). Simpan ulang untuk memperbarui.
Password tersimpan di keyring desktop; cookie disimpan oleh qutebrowser.
Website tetap dapat meminta login ulang jika sesi kedaluwarsa.
Keyring harus terbuka; jika terkunci, sistem bisa meminta password keyring.
Tidak ada impor otomatis password Firefox, dan tidak ada popup simpan otomatis.

Pengisian mendukung formulir umum di halaman utama; iframe dan beberapa
formulir khusus bisa memerlukan pengisian manual. Kredensial hanya diberikan
pada origin yang sama. Tidak memakai clipboard, argumen proses, atau FIFO
berisi password. Payload sementara memakai file privat di XDG_RUNTIME_DIR
(RAM), lalu dihapus sesudah 5 detik. Jangan aktifkan debug log cookie/data
sensitif ketika membagikan laporan browser.
