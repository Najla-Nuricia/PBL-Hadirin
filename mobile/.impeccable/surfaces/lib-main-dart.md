---
version: 1
slug: "lib-main-dart"
primary_target: "lib/main.dart"
related_targets: []
---

# Surface brief: HADIR.IN mobile redesign

- **Visitor mode:** operate
- **Scope:** seluruh antarmuka aplikasi Flutter (onboarding, mahasiswa, dosen, sekretaris jurusan). Frontend saja; routing, Riverpod, kontrak API, dan aturan presensi tetap.
- **Audience and job:** mahasiswa JTI Polinema mencatat kehadiran dalam hitungan detik di ruang kelas; dosen memeriksa kehadiran dan memutuskan pengajuan; sekretaris jurusan mengelola data akademik dan jadwal.
- **Content and proof:** data nyata dari API atau data contoh yang sudah ada di aplikasi. Tidak ada klaim, angka, atau testimoni baru.
- **Constraints:** Material 3, area sentuh 48 dp, teks minimal 12 sp, status selalu ikon + teks + warna, Bahasa Indonesia singkat dan ramah, tahan teks sistem 1.3x.
- **Memorable moment:** bingkai oval scan wajah yang berubah warna dan terisi sesuai kondisi, lalu berakhir sebagai bukti presensi.
- **Unresolved:** mode gelap, lupa kata sandi, penyimpanan foto profil.

## Direction contract

- **THESIS:** Presensi diperlakukan seperti transaksi terverifikasi di aplikasi kampus generasi baru, dibuka oleh ilustrasi wisudawan di atas awan (referensi pengguna, `assets/images/landing_hero.jpg`). Setiap layar melanjutkan dunia itu: langit di kepala layar, tepi awan, isi di kanvas terang.
- **OWN-WORLD:** Langit `#0FA1FD → #7BCAFD` di app bar dan kepala layar, ditutup tepi awan krem `#FEEEDC` lalu kanvas `#F1F4FB`. Tinta navy toga `#1B2B45` untuk judul di atas langit (kontras 5:1); putih tidak dipakai di atas langit. Gradien aksi biru `#1A8CF0 → #1257E7 → #1442C4`; gradien gelap navy-ke-biru-buku `#13213A → #0A64A2` untuk kartu sesi dan profil; aksen pita oranye `#FE8614` dan coral `#FD3E50`. Ikon seluruhnya Phosphor: Regular untuk diam, Fill untuk tab terpilih. Kaca hanya untuk dock navigasi; tab Absensi berupa bulatan bergradien di tengah dock.
- **STORY:** Mahasiswa membuka aplikasi, langsung tahu kelas mana yang presensinya dibuka, menekan satu tombol, dipandu bingkai oval sampai wajah terverifikasi, lalu menerima bukti presensi. Saat gagal, layar menyebut penyebabnya (wajah tidak dikenali, koneksi terputus, di luar radius) dan satu langkah perbaikan. Dosen memilih kelas, membaca ringkasan, lalu memutuskan pengajuan. Sekretaris jurusan menemukan data master dan jadwal tanpa menebak.
- **FIRST VIEWPORT:** Scan wajah, layar penuh. Pratinjau kamera memenuhi layar dengan tirai gelap `#0B1220` 72% di luar bingkai oval tegak (lebar 68% layar, rasio 3:4) yang berada sedikit di atas tengah. Di atas oval: judul keadaan 20 sp tebal dan satu baris petunjuk 14 sp, putih. Garis oval 4 dp: putih berdenyut saat mencari wajah, kuning saat posisi atau cahaya perlu diperbaiki, biru terisi searah jarum jam saat menahan dan saat kedipan diminta, hijau penuh dengan centang saat terverifikasi, merah saat gagal. Kiri atas tombol kembali bundar, kanan atas ganti kamera. Di bawah oval: keping lokasi dan mata kuliah. Paling bawah: aksi cadangan "Ambil foto manual" yang muncul bila deteksi tidak tersedia. Beranda mahasiswa: sapaan besar dan NIM, lalu kartu sesi bergradien gelap radius 24 berisi status, nama mata kuliah, jam dan ruang, dan tombol putih selebar kartu "Mulai presensi".
- **FORM:** Standar kategori HRIS/fintech, dijalankan apa adanya. `seed: none (pinned)`. Arahan terbaru pengguna mengunci "modern dan seperti aplikasi terbaru": gradien, kaca fungsional, tipografi besar. Pertahankan biru Hadir.in sebagai warna utama, latar putih kebiruan, teks gelap yang mudah dibaca.
- **FINISH:** unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
