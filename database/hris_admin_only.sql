-- =========================================================
-- HRIS Absensi, Payroll, dan Potongan Kontrak
-- Versi ADMIN ONLY - tanpa fitur karyawan login
-- Absensi diinput manual oleh admin (tanpa foto/geolocation)
-- Target: MySQL / MariaDB (XAMPP / phpMyAdmin)
-- Database: hris_admin_only
-- =========================================================

SET NAMES utf8mb4;
SET time_zone = '+07:00';
SET FOREIGN_KEY_CHECKS = 0;

-- =========================================================
-- USERS (admin only)
-- =========================================================

CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama VARCHAR(150) NOT NULL,
  email VARCHAR(190) NOT NULL,
  password VARCHAR(255) NOT NULL,
  role ENUM('admin', 'karyawan') NOT NULL DEFAULT 'admin',
  status_aktif TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_role_status (role, status_aktif)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- KARYAWAN
-- =========================================================

CREATE TABLE karyawan (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  no_karyawan VARCHAR(50) NOT NULL,
  nama VARCHAR(150) NOT NULL,
  unit VARCHAR(100) NULL,
  jabatan VARCHAR(100) NOT NULL,
  departemen VARCHAR(100) NOT NULL,
  divisi VARCHAR(100) NOT NULL,
  sub_divisi VARCHAR(100) NULL,
  penempatan VARCHAR(150) NULL,
  pembagian_rekapan VARCHAR(100) NULL,
  pembebanan VARCHAR(100) NULL,
  bank VARCHAR(50) NULL DEFAULT 'BCA',
  no_rekening VARCHAR(50) NULL,
  jenis_kelamin ENUM('laki-laki', 'perempuan') NULL,
  tempat_lahir VARCHAR(100) NULL,
  tanggal_lahir DATE NULL,
  nik VARCHAR(30) NULL,
  agama VARCHAR(30) NULL,
  alamat_ktp TEXT NULL,
  alamat_rumah_kost TEXT NULL,
  nomor_telepon VARCHAR(30) NULL,
  foto_ktp VARCHAR(255) NULL,
  status_kepegawaian ENUM('tetap', 'kontrak', 'freelance', 'magang', 'resign') NOT NULL DEFAULT 'kontrak',
  status_kerja ENUM('tetap', 'kontrak', 'freelance', 'magang', 'resign') NOT NULL DEFAULT 'kontrak',
  status_data ENUM('aktif', 'nonaktif') NOT NULL DEFAULT 'aktif',
  tanggal_masuk_pertama DATE NULL,
  tanggal_kontrak DATE NULL,
  tanggal_selesai_kontrak DATE NULL,
  kenaikan_tiap_tahun DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_karyawan_user_id (user_id),
  UNIQUE KEY uq_karyawan_no_karyawan (no_karyawan),
  UNIQUE KEY uq_karyawan_nik (nik),
  KEY idx_karyawan_nama (nama),
  KEY idx_karyawan_unit (unit),
  KEY idx_karyawan_departemen (departemen),
  KEY idx_karyawan_divisi (divisi),
  KEY idx_karyawan_status_kepegawaian (status_kepegawaian),
  KEY idx_karyawan_status_kerja (status_kerja),
  KEY idx_karyawan_status_data (status_data),
  CONSTRAINT fk_karyawan_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- ABSENSI (manual input oleh admin, tanpa foto & geolocation)
-- Kode absensi:
-- H = Masuk / Setengah Hari
-- O = Masuk (hadir penuh)
-- X = Ga Masuk (izin/alfa/libur)
-- S = Sakit
-- SX = Setengah Hari (sakit tanpa surat)
-- =========================================================

CREATE TABLE absensi (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  karyawan_id BIGINT UNSIGNED NOT NULL,
  tanggal DATE NOT NULL,
  jam_masuk DATETIME NULL,
  jam_pulang DATETIME NULL,
  status_absensi ENUM('hadir', 'sakit', 'izin', 'libur', 'setengah_hari', 'alfa') NOT NULL DEFAULT 'hadir',
  kode_absensi VARCHAR(10) NULL,
  terlambat_menit INT UNSIGNED NOT NULL DEFAULT 0,
  setengah_hari TINYINT(1) NOT NULL DEFAULT 0,
  lembur_jam DECIMAL(6,2) NOT NULL DEFAULT 0.00,
  keterangan VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_absensi_karyawan_tanggal (karyawan_id, tanggal),
  KEY idx_absensi_tanggal (tanggal),
  KEY idx_absensi_status (status_absensi),
  KEY idx_absensi_kode (kode_absensi),
  CONSTRAINT fk_absensi_karyawan
    FOREIGN KEY (karyawan_id) REFERENCES karyawan (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- LEMBUR
-- =========================================================

CREATE TABLE lembur (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  karyawan_id BIGINT UNSIGNED NOT NULL,
  tanggal DATE NOT NULL,
  jam_mulai DATETIME NOT NULL,
  jam_selesai DATETIME NOT NULL,
  total_jam DECIMAL(6,2) NOT NULL DEFAULT 0.00,
  bukti_lembur VARCHAR(255) NULL,
  status_approval ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
  approved_by BIGINT UNSIGNED NULL,
  catatan_atasan VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_lembur_karyawan_tanggal (karyawan_id, tanggal),
  KEY idx_lembur_status_approval (status_approval),
  KEY idx_lembur_approved_by (approved_by),
  CONSTRAINT fk_lembur_karyawan
    FOREIGN KEY (karyawan_id) REFERENCES karyawan (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_lembur_approved_by
    FOREIGN KEY (approved_by) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- PINJAMAN
-- =========================================================

CREATE TABLE pinjaman (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  karyawan_id BIGINT UNSIGNED NOT NULL,
  jumlah_pinjaman DECIMAL(14,2) NOT NULL,
  jumlah_angsuran INT UNSIGNED NOT NULL DEFAULT 1,
  angsuran_per_bulan DECIMAL(14,2) NOT NULL,
  total_sudah_bayar DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  sisa_pinjaman DECIMAL(14,2) NOT NULL,
  tanggal_pengajuan DATE NOT NULL,
  tanggal_approval DATE NULL,
  approved_by BIGINT UNSIGNED NULL,
  status_pinjaman ENUM('pending', 'approved', 'berjalan', 'lunas', 'rejected', 'cancelled') NOT NULL DEFAULT 'pending',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_pinjaman_karyawan (karyawan_id),
  KEY idx_pinjaman_status (status_pinjaman),
  KEY idx_pinjaman_tanggal (tanggal_pengajuan),
  CONSTRAINT fk_pinjaman_karyawan
    FOREIGN KEY (karyawan_id) REFERENCES karyawan (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- POTONGAN KONTRAK
-- =========================================================

CREATE TABLE potongan_kontrak (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  karyawan_id BIGINT UNSIGNED NOT NULL,
  bulan TINYINT UNSIGNED NOT NULL,
  tahun SMALLINT UNSIGNED NOT NULL,
  nominal_potongan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  keterangan VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_potongan_kontrak_periode (karyawan_id, bulan, tahun),
  KEY idx_potongan_kontrak_periode (tahun, bulan),
  CONSTRAINT fk_potongan_kontrak_karyawan
    FOREIGN KEY (karyawan_id) REFERENCES karyawan (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_potongan_kontrak_bulan CHECK (bulan BETWEEN 1 AND 12)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- PAYROLL
-- =========================================================

CREATE TABLE payroll (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  karyawan_id BIGINT UNSIGNED NOT NULL,
  periode_bulan TINYINT UNSIGNED NOT NULL,
  periode_tahun SMALLINT UNSIGNED NOT NULL,
  hari_kerja INT UNSIGNED NOT NULL DEFAULT 0,
  total_masuk INT UNSIGNED NOT NULL DEFAULT 0,
  total_lembur_jam DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  total_terlambat INT UNSIGNED NOT NULL DEFAULT 0,
  total_setengah_hari INT UNSIGNED NOT NULL DEFAULT 0,
  gaji_pokok DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tunjangan_jabatan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  tunjangan_lain DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  bonus_performa DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  bpjs DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  uang_makan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  transport DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  insentif DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  upah_lembur DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  potongan_keterlambatan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  potongan_setengah_hari DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  potongan_kontrak DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  potongan_pinjaman DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  potongan_kerajinan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  total_potongan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  gaji_bersih DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  status_payroll ENUM('draft', 'processed', 'approved_finance', 'paid') NOT NULL DEFAULT 'draft',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payroll_periode (karyawan_id, periode_bulan, periode_tahun),
  KEY idx_payroll_periode (periode_tahun, periode_bulan),
  KEY idx_payroll_status (status_payroll),
  CONSTRAINT fk_payroll_karyawan
    FOREIGN KEY (karyawan_id) REFERENCES karyawan (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_payroll_bulan CHECK (periode_bulan BETWEEN 1 AND 12)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- SLIP GAJI
-- =========================================================

CREATE TABLE slip_gaji (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payroll_id BIGINT UNSIGNED NOT NULL,
  nomor_slip VARCHAR(50) NOT NULL,
  tanggal_distribusi DATETIME NULL,
  status_distribusi ENUM('draft', 'didistribusikan', 'dibaca') NOT NULL DEFAULT 'draft',
  file_slip VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_slip_gaji_payroll_id (payroll_id),
  UNIQUE KEY uq_slip_gaji_nomor_slip (nomor_slip),
  KEY idx_slip_gaji_status (status_distribusi),
  CONSTRAINT fk_slip_gaji_payroll
    FOREIGN KEY (payroll_id) REFERENCES payroll (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- LOG DISTRIBUSI SLIP
-- =========================================================

CREATE TABLE log_distribusi_slip (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  slip_gaji_id BIGINT UNSIGNED NOT NULL,
  karyawan_id BIGINT UNSIGNED NOT NULL,
  didistribusikan_oleh BIGINT UNSIGNED NOT NULL,
  tanggal_distribusi DATETIME NOT NULL,
  status_baca TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_log_distribusi_slip (slip_gaji_id),
  KEY idx_log_distribusi_karyawan (karyawan_id),
  KEY idx_log_distribusi_admin (didistribusikan_oleh),
  CONSTRAINT fk_log_distribusi_slip
    FOREIGN KEY (slip_gaji_id) REFERENCES slip_gaji (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_log_distribusi_karyawan
    FOREIGN KEY (karyawan_id) REFERENCES karyawan (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_log_distribusi_user
    FOREIGN KEY (didistribusikan_oleh) REFERENCES users (id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- PINJAMAN CICILAN
-- =========================================================

CREATE TABLE pinjaman_cicilan (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  pinjaman_id BIGINT UNSIGNED NOT NULL,
  urutan_cicilan INT UNSIGNED NOT NULL,
  bulan TINYINT UNSIGNED NOT NULL,
  tahun SMALLINT UNSIGNED NOT NULL,
  nominal_potongan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  nominal_terpotong DECIMAL(14,2) NULL DEFAULT NULL,
  payroll_id BIGINT UNSIGNED NULL DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_pinjaman_cicilan_periode (pinjaman_id, bulan, tahun),
  UNIQUE KEY uq_pinjaman_cicilan_urutan (pinjaman_id, urutan_cicilan),
  KEY idx_pinjaman_cicilan_periode (tahun, bulan),
  KEY idx_pinjaman_cicilan_payroll (payroll_id),
  CONSTRAINT fk_pinjaman_cicilan_pinjaman
    FOREIGN KEY (pinjaman_id) REFERENCES pinjaman (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- OMZET BULANAN
-- =========================================================

CREATE TABLE omzet_bulanan (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  periode_bulan TINYINT UNSIGNED NOT NULL,
  periode_tahun SMALLINT UNSIGNED NOT NULL,
  total_omzet DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_omzet_bulanan_periode (periode_bulan, periode_tahun)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- PAYROLL EMPLOYEE INPUT
-- =========================================================

CREATE TABLE payroll_employee_input (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  payroll_id BIGINT UNSIGNED NOT NULL,
  karyawan_id BIGINT UNSIGNED NOT NULL,
  payroll_type ENUM('non_sales', 'sales') NOT NULL DEFAULT 'non_sales',
  gaji_pokok_per_hari DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  uang_makan_per_hari DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  subsidi DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  uang_kerajinan DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  bpjs DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  bonus_performa DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  insentif DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  uang_transport DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  override_masuk INT NULL DEFAULT NULL,
  override_lembur DECIMAL(14,2) NULL DEFAULT NULL,
  override_izin INT NULL DEFAULT NULL,
  override_sakit INT NULL DEFAULT NULL,
  override_sakit_tanpa_surat INT NULL DEFAULT NULL,
  override_setengah_hari INT NULL DEFAULT NULL,
  override_kontrak DECIMAL(14,2) NULL DEFAULT NULL,
  override_pinjaman DECIMAL(14,2) NULL DEFAULT NULL,
  override_pinjaman_pribadi DECIMAL(14,2) NULL DEFAULT NULL,
  override_gaji_pokok DECIMAL(14,2) NULL DEFAULT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_payroll_employee_input_payroll (payroll_id),
  KEY idx_payroll_employee_input_karyawan (karyawan_id),
  CONSTRAINT fk_payroll_employee_input_payroll
    FOREIGN KEY (payroll_id) REFERENCES payroll (id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_payroll_employee_input_karyawan
    FOREIGN KEY (karyawan_id) REFERENCES karyawan (id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- SEED ADMIN USER
-- =========================================================

INSERT INTO users (id, nama, email, password, role, status_aktif) VALUES
  (1, 'Ezra Kristanto', 'ezra.kristanto@ti.ukdw.ac.id', SHA2('ftiukdw2022', 256), 'admin', 1);

-- =========================================================
-- SEED KARYAWAN (tanpa user login, user_id tetap ke admin)
-- Untuk data karyawan, admin membuat via panel admin
-- =========================================================

-- =========================================================
-- CATATAN
-- 1. Admin login:
--    ezra.kristanto@ti.ukdw.ac.id / ftiukdw2022
-- 2. Database ini khusus mode ADMIN ONLY.
--    Karyawan tidak bisa login, absensi diinput manual oleh admin.
-- 3. Kolom foto_masuk, foto_pulang, latitude, longitude
--    dihapus dari tabel absensi karena tidak diperlukan.
-- =========================================================
