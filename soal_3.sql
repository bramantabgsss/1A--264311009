-- SOAL 3: QUERY KOMPLEKS & AGREGASI LAPORAN
SELECT
    p.nama_pelanggan,
    pr.nama_produk,
    SUM(dp.jumlah) AS total_barang,
    SUM(dp.subtotal) AS total_penjualan
FROM PELANGGAN p
JOIN DETAIL_PENJUALAN dp
    ON p.id_pelanggan = dp.id_pelanggan
JOIN PRODUK pr
    ON dp.id_produk = pr.id_produk
WHERE dp.jumlah > 0
GROUP BY
    p.id_pelanggan,
    p.nama_pelanggan,
    pr.id_produk,
    pr.nama_produk;
