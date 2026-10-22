--tabel induk 1 : tabel produk
CREATE TABLE IF NOT EXISTS PRODUK (
    id_produk INT NOT NULL AUTO_INCREMENT,
    nama_produk VARCHAR(100) NOT NULL,
    harga_satuan_baku DECIMAL(15,2) NOT NULL,
    PRIMARY KEY (id_produk)
) ENGINE=InnoDB;

-- tabel induk 2: tabel pelanggan
CREATE TABLE IF NOT EXISTS PELANGGAN (
    id_pelanggan INT NOT NULL AUTO_INCREMENT,
    nama_pelanggan VARCHAR(100) NOT NULL,
    kontak VARCHAR(100),
    PRIMARY KEY (id_pelanggan)
) ENGINE=InnoDB;

-- tabel transaksi/detail:detail penjualan (menghubungkan produk dan pelanggan)
CREATE TABLE IF NOT EXISTS DETAIL_PENJUALAN (
    id_transaksi INT NOT NULL,
    no_item INT NOT NULL,
    id_produk INT NOT NULL,
    id_pelanggan INT NOT NULL,
    jumlah INT NOT NULL,
    harga_satuan_actual DECIMAL(15,2) NOT NULL,
    diskon_item DECIMAL(15,2) NOT NULL,
    subtotal DECIMAL(15,2),
    PRIMARY KEY (id_transaksi, no_item),

    CONSTRAINT fk_detjual_transaksi
        FOREIGN KEY (id_transaksi)
        REFERENCES TRANSAKSI (id_transaksi)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_detjual_produk
        FOREIGN KEY (id_produk)
        REFERENCES PRODUK (id_produk)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_detjual_pelanggan
        FOREIGN KEY (id_pelanggan)
        REFERENCES PELANGGAN (id_pelanggan)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;
