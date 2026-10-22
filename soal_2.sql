-- 1. CREATE INSERT Data Dummy
-- CREATE: menambahkan data ke table produk
INSERT INTO PRODUK
    (id_produk, nama_produk, harga_satuan_baku)
VALUES
    (101, 'Buku Tulis', 5000.00),
    (102, 'Pulpen', 3000.00),
    (103, 'Tas Sekolah', 75000.00);

-- CREATE : menambahkan data ke tabel pelanggan
INSERT INTO PELANGGAN
    (id_pelanggan, nama_pelanggan, kontak)
VALUES
    (101, 'Rafiq Imam Zaini', '081234567801'),
    (102, 'Dhafin Hasya Zaki', '081234567802'),
    (103, 'Bramanta Setya Bagaskara', '081234567803');

-- CREATE: menambahkan data ke detail penjualan
INSERT INTO DETAIL_PENJUALAN
    (id_transaksi, no_item, id_produk, id_pelanggan,
     jumlah, harga_satuan_actual, diskon_item, subtotal)
VALUES
    (1, 1, 101, 101, 2, 5000.00, 0.00, 10000.00),
    (2, 1, 102, 102, 5, 3000.00, 0.00, 15000.00),
    (3, 1, 103, 103, 1, 75000.00, 5000.00, 70000.00);

-- 2. READ menampilkan Seluruh Isi Tabel Induk
SELECT *
FROM PRODUK;

-- 3. UPDATE: mengubah jumlah barang
UPDATE DETAIL_PENJUALAN
SET jumlah = 3,
    subtotal = (3 * harga_satuan_actual) - diskon_item
WHERE id_transaksi = 1
  AND no_item = 1;

-- 4. DELETE: menghapus satu detail penjualan
DELETE FROM DETAIL_PENJUALAN
WHERE id_transaksi = 3
  AND no_item = 1;

