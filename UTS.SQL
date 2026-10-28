```sql
-- ---------------------------------------------------------------------
-- A. ALASAN BISNIS
-- ---------------------------------------------------------------------
-- Dalam usaha UMKM, jumlah persediaan produk dapat berubah karena
-- pembelian barang, penjualan, dan penyesuaian hasil pengecekan stok.
-- Sistem perlu mencatat setiap perubahan stok agar riwayat persediaan
-- dapat ditelusuri berdasarkan produk, pengguna, tanggal, dan transaksi.
--
-- Untuk menjaga konsistensi data, database membatasi jenis mutasi,
-- memastikan jumlah mutasi lebih dari nol, dan menggunakan foreign key
-- agar setiap mutasi mengacu pada produk serta pengguna yang valid.
-- Stok keluar juga tidak boleh melebihi stok yang tersedia.


-- ---------------------------------------------------------------------
-- B. ANALISIS NORMALISASI
-- ---------------------------------------------------------------------
-- Tabel awal yang belum dinormalisasi:
-- mutasi_stok(
--     id_mutasi, id_produk, nama_produk, id_pengguna, nama_pengguna,
--     id_transaksi, tanggal_mutasi, jenis_mutasi, jumlah, keterangan
-- )
--
-- 1NF:
-- Semua atribut memiliki nilai atomik dan setiap baris dapat
-- diidentifikasi dengan id_mutasi. TERPENUHI.
--
-- 2NF:
-- Primary key menggunakan satu atribut, yaitu id_mutasi, sehingga
-- tidak terdapat ketergantungan parsial. TERPENUHI.
--
-- 3NF:
-- Nama produk ditentukan oleh id_produk, sedangkan nama pengguna
-- ditentukan oleh id_pengguna. Jika kedua nama disimpan berulang
-- pada tabel mutasi_stok, dapat terjadi redundansi dan anomali update.
--
-- Solusi:
-- mutasi_stok(
--     id_mutasi, id_produk*, id_pengguna*, id_transaksi*,
--     tanggal_mutasi, jenis_mutasi, jumlah, keterangan
-- )
--
-- Informasi produk, pengguna, dan transaksi diperoleh melalui
-- foreign key dan JOIN ke tabel induk.
--
-- Hasil:
-- Struktur mutasi_stok mendukung normalisasi hingga 3NF dengan asumsi
-- setiap atribut non-key bergantung pada primary key secara langsung.
--
-- Relasi:
-- PRODUK (1) -------- (N) MUTASI_STOK
-- PENGGUNA (1) ------ (N) MUTASI_STOK
-- TRANSAKSI (1) ----- (N) MUTASI_STOK
-- Relasi transaksi bersifat opsional karena id_transaksi dapat NULL.


-- ---------------------------------------------------------------------
-- C. DDL
-- ---------------------------------------------------------------------

USE db_umkm;

CREATE TABLE IF NOT EXISTS mutasi_stok (
    id_mutasi INT NOT NULL AUTO_INCREMENT,
    id_produk INT NOT NULL,
    id_pengguna INT NOT NULL,
    id_transaksi INT DEFAULT NULL,
    tanggal_mutasi DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    jenis_mutasi ENUM(
        'MASUK',
        'KELUAR',
        'PENYESUAIAN_TAMBAH',
        'PENYESUAIAN_KURANG'
    ) NOT NULL,

    jumlah INT NOT NULL,
    keterangan VARCHAR(255) DEFAULT NULL,

    CONSTRAINT pk_mutasi_stok
        PRIMARY KEY (id_mutasi),

    CONSTRAINT fk_mutasi_produk
        FOREIGN KEY (id_produk)
        REFERENCES produk (id_produk)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_mutasi_pengguna
        FOREIGN KEY (id_pengguna)
        REFERENCES pengguna (id_pengguna)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_mutasi_transaksi
        FOREIGN KEY (id_transaksi)
        REFERENCES transaksi (id_transaksi)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_mutasi_jumlah
        CHECK (jumlah > 0),

    INDEX idx_mutasi_produk_tanggal
        (id_produk, tanggal_mutasi),

    INDEX idx_mutasi_transaksi
        (id_transaksi)
) ENGINE=InnoDB;


-- Trigger: validasi jumlah dan kecukupan stok sebelum mutasi keluar.
-- Stok dihitung dari riwayat mutasi, bukan dari kolom produk.stok.

DELIMITER $$

CREATE TRIGGER trg_mutasi_stok_bi
BEFORE INSERT ON mutasi_stok
FOR EACH ROW
BEGIN
    DECLARE stok_sekarang BIGINT DEFAULT 0;

    IF NEW.jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Jumlah mutasi harus lebih dari 0';
    END IF;

    SELECT COALESCE(SUM(
        CASE
            WHEN jenis_mutasi IN ('MASUK', 'PENYESUAIAN_TAMBAH')
                THEN jumlah
            WHEN jenis_mutasi IN ('KELUAR', 'PENYESUAIAN_KURANG')
                THEN -jumlah
            ELSE 0
        END
    ), 0)
    INTO stok_sekarang
    FROM mutasi_stok
    WHERE id_produk = NEW.id_produk;

    IF NEW.jenis_mutasi IN ('KELUAR', 'PENYESUAIAN_KURANG')
       AND stok_sekarang < NEW.jumlah THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stok tidak mencukupi';
    END IF;
END$$

DELIMITER ;


-- ---------------------------------------------------------------------
-- D. DATA AWAL DAN BUKTI
-- ---------------------------------------------------------------------
-- Pastikan id_produk dan id_pengguna yang digunakan benar-benar ada.
-- Jalankan SELECT terlebih dahulu untuk memeriksa ID.
--
-- SELECT id_produk, nama_produk FROM produk;
-- SELECT id_pengguna, nama FROM pengguna;
--
-- Contoh berikut mengasumsikan id_produk = 1 dan id_pengguna = 1
-- tersedia di database.

INSERT INTO mutasi_stok
    (id_produk, id_pengguna, id_transaksi,
     tanggal_mutasi, jenis_mutasi, jumlah, keterangan)
VALUES
    (1, 1, NULL, '2026-10-20 08:00:00',
     'MASUK', 20, 'Stok awal barang masuk'),
    (1, 1, NULL, '2026-10-21 09:00:00',
     'PENYESUAIAN_TAMBAH', 5,
     'Penambahan stok hasil pengecekan'),
    (1, 1, NULL, '2026-10-22 10:00:00',
     'MASUK', 10, 'Penambahan persediaan barang');


-- Daftar riwayat mutasi dan saldo stok per produk.

SELECT
    m.id_mutasi,
    p.nama_produk,
    u.nama AS nama_pengguna,
    m.id_transaksi,
    m.tanggal_mutasi,
    m.jenis_mutasi,
    m.jumlah,
    m.keterangan,
    SUM(
        CASE
            WHEN m.jenis_mutasi IN ('MASUK', 'PENYESUAIAN_TAMBAH')
                THEN m.jumlah
            WHEN m.jenis_mutasi IN ('KELUAR', 'PENYESUAIAN_KURANG')
                THEN -m.jumlah
            ELSE 0
        END
    ) OVER (
        PARTITION BY m.id_produk
        ORDER BY m.tanggal_mutasi, m.id_mutasi
    ) AS stok_setelah_mutasi
FROM mutasi_stok m
JOIN produk p
    ON p.id_produk = m.id_produk
JOIN pengguna u
    ON u.id_pengguna = m.id_pengguna
ORDER BY m.tanggal_mutasi, m.id_mutasi;


-- ---------------------------------------------------------------------
-- E. BUKTI CONSTRAINT
-- ---------------------------------------------------------------------
-- Setiap perintah di bawah harus gagal.
-- Pastikan id_produk = 1 dan id_pengguna = 1 tersedia.
-- Pastikan ID 999999 tidak digunakan pada tabel induk.


-- 1. Jumlah nol: ditolak oleh trigger dan/atau CHECK.

INSERT INTO mutasi_stok
    (id_produk, id_pengguna, id_transaksi,
     jenis_mutasi, jumlah, keterangan)
VALUES
    (1, 1, NULL, 'MASUK', 0, 'Uji jumlah nol');


-- 2. Jumlah negatif: ditolak oleh trigger dan/atau CHECK.

INSERT INTO mutasi_stok
    (id_produk, id_pengguna, id_transaksi,
     jenis_mutasi, jumlah, keterangan)
VALUES
    (1, 1, NULL, 'MASUK', -5, 'Uji jumlah negatif');


-- 3. Produk tidak tersedia: ditolak oleh foreign key produk.

INSERT INTO mutasi_stok
    (id_produk, id_pengguna, id_transaksi,
     jenis_mutasi, jumlah, keterangan)
VALUES
    (999999, 1, NULL, 'MASUK', 5, 'Uji produk tidak ada');


-- 4. Pengguna tidak tersedia: ditolak oleh foreign key pengguna.

INSERT INTO mutasi_stok
    (id_produk, id_pengguna, id_transaksi,
     jenis_mutasi, jumlah, keterangan)
VALUES
    (1, 999999, NULL, 'MASUK', 5, 'Uji pengguna tidak ada');


-- 5. Transaksi tidak tersedia: ditolak oleh foreign key transaksi.

INSERT INTO mutasi_stok
    (id_produk, id_pengguna, id_transaksi,
     jenis_mutasi, jumlah, keterangan)
VALUES
    (1, 1, 999999, 'MASUK', 5, 'Uji transaksi tidak ada');


-- 6. Stok keluar melebihi stok yang tersedia: ditolak oleh trigger.
-- Contoh ini mengasumsikan saldo produk 1 kurang dari 999999.

INSERT INTO mutasi_stok
    (id_produk, id_pengguna, id_transaksi,
     jenis_mutasi, jumlah, keterangan)
VALUES
    (1, 1, NULL, 'KELUAR', 999999,
     'Uji stok keluar melebihi saldo');


-- ---------------------------------------------------------------------
-- F. RINGKASAN CONSTRAINT
-- ---------------------------------------------------------------------
-- PRIMARY KEY:
--   id_mutasi menjamin identitas unik setiap mutasi.
--
-- FOREIGN KEY:
--   id_produk, id_pengguna, dan id_transaksi menjaga integritas
--   referensial terhadap tabel induk.
--
-- CHECK:
--   jumlah harus lebih besar dari nol.
--
-- ENUM:
--   jenis_mutasi hanya menerima empat jenis mutasi yang ditentukan.
--
-- NOT NULL:
--   Kolom wajib tidak boleh kosong.
--
-- DEFAULT:
--   tanggal_mutasi menggunakan waktu saat ini jika tidak diberikan.
--
-- AUTO_INCREMENT:
--   id_mutasi dihasilkan secara otomatis.
--
-- INDEX:
--   Mempercepat pencarian berdasarkan produk dan tanggal mutasi.
--
-- TRIGGER:
--   Memvalidasi jumlah dan menolak pengeluaran stok yang melebihi
--   saldo berdasarkan riwayat mutasi.
--
-- ON DELETE RESTRICT:
--   Mencegah penghapusan data induk yang masih digunakan.
--
-- ON UPDATE CASCADE:
--   Memperbarui foreign key saat ID induk berubah.
--
-- Catatan:
--   Trigger ini menghitung saldo berdasarkan riwayat mutasi yang sudah
--   tercatat. Untuk sistem multi-pengguna, pengamanan transaksi dan
--   konkurensi perlu ditambahkan agar dua pengeluaran bersamaan tidak
--   sama-sama lolos pemeriksaan saldo.
```
