# Deploy Mission Control ke Vercel + Supabase

Arsitektur: **Vercel** = frontend statis (file di folder ini). **Supabase** = database.
Data didorong dari server asal (tempat AI agent berjalan) oleh collector tiap 30 detik.
Dashboard di Vercel membaca snapshot terbaru tiap 3 detik — tanpa tunnel.

## Langkah 1 — Buat project Supabase (gratis)

1. Buka https://supabase.com → sign up / login → **New project**.
2. Tunggu project siap (±1 menit).

## Langkah 2 — Buat tabel (sekali saja)

1. Di Supabase Dashboard, buka **SQL Editor** → **New query**.
2. Buka file `supabase-schema.sql` (ada di folder ini), copy **seluruh** isinya,
   paste ke SQL Editor → **Run**.
3. Pastikan tidak ada error merah. Tabel yang dibuat: `state_snapshots`,
   `task_events`, `queue`, `dispatch`, `agent_pause`, `schedules`, `watchdog_log`
   — lengkap dengan RLS policy.

## Langkah 3 — Isi config.js

1. Di Supabase Dashboard → **Project Settings** → **API**, salin:
   - **Project URL** → `SUPABASE_URL`
   - **anon public key** → `SUPABASE_ANON_KEY`
2. Tempel ke file `config.js` di folder ini (ganti nilai `CONTOH...`).
3. ⚠️ Yang dipakai di sini memang **anon key** (dirancang untuk publik, dilindungi RLS).
   Jangan pernah memakai `service_role` key di frontend.

## Langkah 4 — Deploy ke Vercel (pilih salah satu)

**Opsi A — Vercel CLI (1 perintah):**
```bash
cd vercel-frontend
npx vercel
```
Ikuti prompt (login, konfirmasi). Selesai → dapat URL `*.vercel.app`.

**Opsi B — Drag & drop:**
Buka https://vercel.com/new → tab yang mendukung upload folder → drag folder
`vercel-frontend` → Deploy.

**Opsi C — GitHub:**
Push folder ini ke repo GitHub → vercel.com/new → Import repository.

## Langkah 5 — Nyalakan collector di server asal

Di server tempat AI agent berjalan (sudah disiapkan):
1. Buat file `data/supabase.json` berisi:
   ```json
   {"url": "https://xxx.supabase.co", "anon_key": "eyJ..."}
   ```
   (pakai URL + **anon key** yang sama seperti `config.js`.)
2. Restart: `node server.js`.
3. Di log akan muncul `[supabase] sync aktif -> https://xxx.supabase.co`,
   lalu `[supabase] cycle ok` tiap 30 detik.
4. Buka URL Vercel → data muncul maksimal ~60 detik setelah collector jalan.

## Cara kerja (singkat & jujur)

- **Baca**: frontend ambil 1 baris `state_snapshots` (snapshot state penuh) tiap 3 detik.
  Tulisan "data N dtk lalu" di sidebar menunjukkan umur snapshot (normal: 0–40 dtk).
- **Tulis dari Vercel** (tambah antrean, pause/resume, klik robot): langsung ke tabel
  Supabase → collector menggabungkannya ke server asal dalam ≤60 dtk.
- **Tulis dari server asal**: diteruskan ke Supabase seketika (write-through).
- **Konflik** (diubah di dua tempat dalam 30 dtk yang sama): Supabase menang.
- **Keamanan**: anon key + RLS. Siapa pun yang memegang URL+anon key bisa membaca
  semua dan *menulis baris baru* (event/antrean). Untuk dashboard pribadi ini
  risikonya diterima; `service_role` key tetap rahasia dan tidak dipakai di mana pun.

## Nama agent di dashboard

Dashboard menampilkan `muse` sebagai `azul`, `udin` sebagai `sulz`, dan `aris`
sebagai `maley`. ID lama tetap dipakai saat membaca snapshot dan mengirim antrean
atau status pause agar sesuai dengan collector yang berjalan di server asal.
Query skema Supabase di `supabase-schema.sql` tidak menetapkan nama agent; untuk
mengganti ID agent yang sebenarnya, ubah juga konfigurasi/source collector.

Di Virtual Office, agent yang idle berjalan mondar-mandir di area belakang kursi.
Agent yang sedang bekerja tetap menuju meja, sedangkan agent yang di-pause diam.
