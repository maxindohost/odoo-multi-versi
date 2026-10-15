# Odoo Multi-Version Dev Environment

Docker + VS Code + Makefile + wkhtmltopdf (patched Qt) untuk Ubuntu 24.04.
Satu Dockerfile, satu `compose.yml`, banyak versi Odoo berjalan berdampingan.

## Prasyarat

```bash
./scripts/setup-ubuntu.sh         # git, make, Docker Engine + Compose (lalu logout/login)
sudo snap install code --classic  # VS Code (opsional)
```

## Mulai cepat

```bash
make up V=17      # clone source, build image, jalankan Odoo 17
make init V=17    # buat database "dev" + install base
# buka http://localhost:8017  (admin / admin, master password: admin)
```

Versi lain tinggal ganti `V`:

```bash
make up V=18 && make init V=18
make up V=16
make status       # lihat semua versi yang berjalan
```

## Port per versi (otomatis)

| Versi | Web  | PostgreSQL | debugpy |
|-------|------|-----------:|--------:|
| 16.0  | 8016 | 5416 | 5616 |
| 17.0  | 8017 | 5417 | 5617 |
| 18.0  | 8018 | 5418 | 5618 |
| 19.0  | 8019 | 5419 | 5619 |

Semua port hanya terbuka di `127.0.0.1`. Tiap versi punya database & filestore sendiri (volume terpisah).

## Struktur

```
.
├── Makefile               # semua perintah (make help)
├── compose.yml            # db + odoo, diparameterisasi per versi
├── docker/                # Dockerfile (+wkhtmltopdf) & entrypoint (+debugpy)
├── config/odoo.conf       # konfigurasi Odoo bersama
├── addons/<versi>/        # addon custom Anda per versi (mis. addons/17.0/)
├── src/<versi>/odoo       # source Odoo (di-clone otomatis, dibaca VS Code)
├── src/<versi>/enterprise # opsional: taruh source Enterprise di sini
└── .vscode/               # settings, tasks, launch (debug) siap pakai
```

## Perintah harian

| Perintah | Fungsi |
|---|---|
| `make up / down / restart / logs` | siklus hidup container (`V=..`) |
| `make scaffold NAME=my_module` | kerangka modul baru di `addons/17.0/` |
| `make install MODULE=my_module` | install modul |
| `make update MODULE=my_module` | update modul (`MODULE=all` untuk semua) |
| `make test MODULE=my_module` | unit test di DB `dev_test` |
| `make odoo-shell` | shell ORM interaktif |
| `make psql` / `make shell` | psql / bash |
| `make dropdb DB=dev` | hapus database |
| `make wkhtml` | cek versi wkhtmltopdf |
| `make clean` | hapus data versi tersebut (dengan konfirmasi) |

Tambahkan `DB=nama` untuk database lain, `DEMO=0` pada `init` untuk tanpa data demo.

## Debug di VS Code

1. `make up V=17 DEBUG=1` (tambah `DEBUG_WAIT=1` bila Odoo harus menunggu debugger).
2. Run and Debug -> **"Odoo 17.0: attach"** (F5).
3. Pasang breakpoint di `src/17.0/odoo/...` atau `addons/17.0/...`.

Saat `DEBUG=1`, auto-reload Python dimatikan (reload me-restart proses dan memutus debugger); gunakan `make restart`.
Tanpa debug, `dev_mode = reload,qweb,xml` aktif: perubahan Python/XML langsung termuat.

Agar autocomplete `import odoo` berfungsi, sesuaikan `python.analysis.extraPaths` di `.vscode/settings.json` ke versi yang sedang dikerjakan.

## Odoo Enterprise

Clone repo enterprise ke `src/17.0/enterprise`, lalu `make restart V=17` (path sudah ada di `addons_path`).

## wkhtmltopdf

Terpasang `0.12.6.1-3` (patched Qt) dari rilis resmi, plus font dasar (DejaVu, Liberation, Noto).
Bila PDF tidak menampilkan CSS/gambar, set system parameter `report.url` ke `http://localhost:8069`.
Butuh font CJK? Tambahkan `fonts-noto-cjk` di `docker/Dockerfile`.
Untuk Ubuntu 24.04 (Odoo 19+) dipakai build `jammy` karena belum ada build `noble`.

## Catatan versi

- 16/17/18 -> Ubuntu 22.04 (Python 3.10); 19+ -> Ubuntu 24.04 (Python 3.12); 14/15 -> Ubuntu 20.04 (Python 3.8, best-effort).
- Versi baru (mis. 20): cukup `make up V=20`.
- Versi PostgreSQL & wkhtmltopdf bisa diubah lewat `.env` (lihat `.env.example`).

## Troubleshooting

- `permission denied ... docker.sock` -> belum logout/login setelah `setup-ubuntu.sh`.
- Port bentrok -> `make down V=..` untuk versi lain, atau ubah rumus port di Makefile.
- Dependensi Python gagal build -> `make build V=..` dan baca error; biasanya kurang library `-dev` di Dockerfile.
