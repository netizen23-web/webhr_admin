import { NextResponse } from "next/server";
import { RowDataPacket } from "mysql2";
import { pool } from "@/lib/db";
import { requireAdminSession } from "@/lib/auth";

export async function POST(request: Request) {
  try {
    await requireAdminSession();

    const body = (await request.json()) as {
      karyawan_id?: number;
      tanggal?: string;
      status_absensi?: string;
      jam_masuk?: string | null;
      jam_pulang?: string | null;
      keterangan?: string | null;
    };

    const { karyawan_id, tanggal, status_absensi, jam_masuk, jam_pulang, keterangan } = body;

    if (!karyawan_id || !tanggal || !status_absensi) {
      return NextResponse.json(
        { message: "karyawan_id, tanggal, dan status_absensi wajib diisi." },
        { status: 400 },
      );
    }

    const validStatuses = ["hadir", "sakit", "izin", "libur", "setengah_hari", "alfa"];
    if (!validStatuses.includes(status_absensi)) {
      return NextResponse.json(
        { message: "Status absensi tidak valid." },
        { status: 400 },
      );
    }

    // Calculate kode_absensi
    let kode_absensi = "O";
    switch (status_absensi) {
      case "hadir":
        kode_absensi = "O";
        break;
      case "sakit":
        kode_absensi = "S";
        break;
      case "izin":
      case "alfa":
      case "libur":
        kode_absensi = "X";
        break;
      case "setengah_hari":
        kode_absensi = "H";
        break;
    }

    // Calculate late minutes from jam_masuk
    let terlambat_menit = 0;
    if (jam_masuk && (status_absensi === "hadir" || status_absensi === "setengah_hari")) {
      const timePart = jam_masuk.includes(" ") ? jam_masuk.split(" ")[1] : jam_masuk;
      const [hourStr, minuteStr] = timePart.split(":");
      const totalMinutes = Number(hourStr) * 60 + Number(minuteStr);
      const expectedMinutes = 8 * 60 + 30; // 08:30
      terlambat_menit = Math.max(totalMinutes - expectedMinutes, 0);
    }

    const setengah_hari = status_absensi === "setengah_hari" ? 1 : 0;

    // Format jam_masuk and jam_pulang as full datetime
    const jamMasukFull = jam_masuk ? `${tanggal} ${jam_masuk.includes(" ") ? jam_masuk.split(" ")[1] : jam_masuk}:00` : null;
    const jamPulangFull = jam_pulang ? `${tanggal} ${jam_pulang.includes(" ") ? jam_pulang.split(" ")[1] : jam_pulang}:00` : null;

    // Upsert: insert or update if exists
    const [existing] = await pool.query<RowDataPacket[]>(
      "SELECT id FROM absensi WHERE karyawan_id = ? AND tanggal = ?",
      [karyawan_id, tanggal],
    );

    if (existing.length > 0) {
      await pool.query(
        `UPDATE absensi SET
          status_absensi = ?,
          kode_absensi = ?,
          jam_masuk = ?,
          jam_pulang = ?,
          terlambat_menit = ?,
          setengah_hari = ?,
          keterangan = ?
        WHERE karyawan_id = ? AND tanggal = ?`,
        [status_absensi, kode_absensi, jamMasukFull, jamPulangFull, terlambat_menit, setengah_hari, keterangan || null, karyawan_id, tanggal],
      );

      return NextResponse.json({ message: "Absensi berhasil diupdate." });
    }

    await pool.query(
      `INSERT INTO absensi (karyawan_id, tanggal, jam_masuk, jam_pulang, status_absensi, kode_absensi, terlambat_menit, setengah_hari, keterangan)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [karyawan_id, tanggal, jamMasukFull, jamPulangFull, status_absensi, kode_absensi, terlambat_menit, setengah_hari, keterangan || null],
    );

    return NextResponse.json({ message: "Absensi berhasil disimpan." });
  } catch (error) {
    console.error("Attendance save error", error);
    return NextResponse.json(
      { message: "Gagal menyimpan absensi." },
      { status: 500 },
    );
  }
}

export async function DELETE(request: Request) {
  try {
    await requireAdminSession();

    const { searchParams } = new URL(request.url);
    const karyawan_id = searchParams.get("karyawan_id");
    const tanggal = searchParams.get("tanggal");

    if (!karyawan_id || !tanggal) {
      return NextResponse.json(
        { message: "karyawan_id dan tanggal wajib diisi." },
        { status: 400 },
      );
    }

    await pool.query(
      "DELETE FROM absensi WHERE karyawan_id = ? AND tanggal = ?",
      [karyawan_id, tanggal],
    );

    return NextResponse.json({ message: "Absensi berhasil dihapus." });
  } catch (error) {
    console.error("Attendance delete error", error);
    return NextResponse.json(
      { message: "Gagal menghapus absensi." },
      { status: 500 },
    );
  }
}
