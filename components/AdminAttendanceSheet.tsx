"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import type { AttendanceDayDetail } from "@/lib/hris";

type Row = {
  employeeId: number;
  name: string;
  nip: string;
  role: string;
  division: string;
  department: string;
  email: string;
  passwordLabel: string;
  daily: Record<number, AttendanceDayDetail>;
};

type Props = {
  days: number[];
  rows: Row[];
  month: number;
  year: number;
};

type SelectedCell = {
  employeeId: number;
  employeeName: string;
  day: number;
  detail: AttendanceDayDetail | null;
} | null;

const STATUS_OPTIONS = [
  { value: "hadir", label: "Hadir (O)", code: "O" },
  { value: "sakit", label: "Sakit (S)", code: "S" },
  { value: "izin", label: "Izin (X)", code: "X" },
  { value: "libur", label: "Libur (X)", code: "X" },
  { value: "setengah_hari", label: "Setengah Hari (H)", code: "H" },
  { value: "alfa", label: "Alfa (X)", code: "X" },
];

function AttendanceInputModal({
  selected,
  month,
  year,
  onClose,
  onSaved,
}: {
  selected: SelectedCell;
  month: number;
  year: number;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [status, setStatus] = useState(selected?.detail?.status || "hadir");
  const [jamMasuk, setJamMasuk] = useState(selected?.detail?.timeIn || "");
  const [jamPulang, setJamPulang] = useState(selected?.detail?.timeOut || "");
  const [keterangan, setKeterangan] = useState(selected?.detail?.note || "");
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState("");

  if (!selected) return null;

  const tanggal = `${year}-${String(month).padStart(2, "0")}-${String(selected.day).padStart(2, "0")}`;
  const isEdit = !!selected.detail;

  async function handleSave() {
    setSaving(true);
    setError("");

    try {
      const response = await fetch("/api/admin/attendance", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          karyawan_id: selected!.employeeId,
          tanggal,
          status_absensi: status,
          jam_masuk: jamMasuk || null,
          jam_pulang: jamPulang || null,
          keterangan: keterangan || null,
        }),
      });

      if (!response.ok) {
        const result = await response.json();
        throw new Error(result.message || "Gagal menyimpan.");
      }

      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Terjadi kesalahan.");
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!confirm("Hapus data absensi ini?")) return;
    setDeleting(true);
    setError("");

    try {
      const response = await fetch(
        `/api/admin/attendance?karyawan_id=${selected!.employeeId}&tanggal=${tanggal}`,
        { method: "DELETE" },
      );

      if (!response.ok) {
        const result = await response.json();
        throw new Error(result.message || "Gagal menghapus.");
      }

      onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Terjadi kesalahan.");
    } finally {
      setDeleting(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4">
      <div className="w-full max-w-md rounded-[28px] bg-white shadow-[0_30px_80px_rgba(15,23,42,0.22)]">
        <div className="flex items-start justify-between gap-4 border-b border-[#e9dfda] px-6 py-5">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.24em] text-[#a16f63]">
              {isEdit ? "Edit Absensi" : "Input Absensi"}
            </p>
            <h3 className="mt-2 text-xl font-semibold text-[#241716]">
              {selected.employeeName}
            </h3>
            <p className="mt-1 text-sm text-[#7a6059]">Tanggal: {tanggal}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-2xl border border-[#e8d5cc] bg-white px-4 py-2 text-sm font-semibold text-[#3c2824]"
          >
            Tutup
          </button>
        </div>

        <div className="space-y-4 px-6 py-5">
          <div>
            <label className="mb-1.5 block text-sm font-semibold text-[#3c2824]">
              Status Absensi
            </label>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value)}
              className="h-11 w-full rounded-xl border border-[#e4d6cf] bg-[#fff8f4] px-3 text-sm text-[#241716] outline-none focus:border-[#c8736d]"
            >
              {STATUS_OPTIONS.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>

          {(status === "hadir" || status === "setengah_hari") && (
            <>
              <div>
                <label className="mb-1.5 block text-sm font-semibold text-[#3c2824]">
                  Jam Masuk
                </label>
                <input
                  type="time"
                  value={jamMasuk}
                  onChange={(e) => setJamMasuk(e.target.value)}
                  className="h-11 w-full rounded-xl border border-[#e4d6cf] bg-[#fff8f4] px-3 text-sm text-[#241716] outline-none focus:border-[#c8736d]"
                />
              </div>
              <div>
                <label className="mb-1.5 block text-sm font-semibold text-[#3c2824]">
                  Jam Pulang
                </label>
                <input
                  type="time"
                  value={jamPulang}
                  onChange={(e) => setJamPulang(e.target.value)}
                  className="h-11 w-full rounded-xl border border-[#e4d6cf] bg-[#fff8f4] px-3 text-sm text-[#241716] outline-none focus:border-[#c8736d]"
                />
              </div>
            </>
          )}

          <div>
            <label className="mb-1.5 block text-sm font-semibold text-[#3c2824]">
              Keterangan
            </label>
            <textarea
              value={keterangan}
              onChange={(e) => setKeterangan(e.target.value)}
              rows={2}
              className="w-full rounded-xl border border-[#e4d6cf] bg-[#fff8f4] px-3 py-2.5 text-sm text-[#241716] outline-none focus:border-[#c8736d]"
              placeholder="Opsional..."
            />
          </div>

          {error && (
            <p className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
              {error}
            </p>
          )}

          <div className="flex items-center gap-3 pt-1">
            <button
              type="button"
              onClick={handleSave}
              disabled={saving}
              className="flex-1 rounded-xl bg-[#8f1d22] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#7a181c] disabled:opacity-50"
            >
              {saving ? "Menyimpan..." : isEdit ? "Update" : "Simpan"}
            </button>
            {isEdit && (
              <button
                type="button"
                onClick={handleDelete}
                disabled={deleting}
                className="rounded-xl border border-red-200 bg-white px-4 py-2.5 text-sm font-semibold text-red-600 transition hover:bg-red-50 disabled:opacity-50"
              >
                {deleting ? "Menghapus..." : "Hapus"}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default function AdminAttendanceSheet({ days, rows, month, year }: Props) {
  const router = useRouter();
  const [selected, setSelected] = useState<SelectedCell>(null);

  const handleCellClick = useCallback(
    (employeeId: number, employeeName: string, day: number, detail: AttendanceDayDetail | undefined) => {
      setSelected({
        employeeId,
        employeeName,
        day,
        detail: detail || null,
      });
    },
    [],
  );

  const handleSaved = useCallback(() => {
    setSelected(null);
    router.refresh();
  }, [router]);

  return (
    <>
      <div className="overflow-x-auto">
        <table className="min-w-[1800px] border-collapse text-left text-sm">
          <thead>
            <tr className="border-b border-[#efe0d8] bg-[#fff8f4] text-xs uppercase tracking-[0.18em] text-[#9e7467]">
              <th className="px-4 py-4">Nama</th>
              <th className="px-4 py-4">NIP</th>
              <th className="px-4 py-4">Jabatan</th>
              <th className="px-4 py-4">Divisi</th>
              <th className="px-4 py-4">Departemen</th>
              <th className="px-4 py-4">Email</th>
              {days.map((day) => (
                <th key={day} className="px-3 py-4 text-center">
                  {day}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.employeeId} className="border-b border-[#f1e5de] text-[#513d39]">
                <td className="px-4 py-4 font-semibold text-[#241716]">{row.name}</td>
                <td className="px-4 py-4">{row.nip}</td>
                <td className="px-4 py-4">{row.role}</td>
                <td className="px-4 py-4">{row.division}</td>
                <td className="px-4 py-4">{row.department}</td>
                <td className="px-4 py-4">{row.email}</td>
                {days.map((day) => {
                  const detail = row.daily[day];

                  return (
                    <td key={day} className="px-3 py-4 text-center font-medium">
                      <button
                        type="button"
                        onClick={() => handleCellClick(row.employeeId, row.name, day, detail)}
                        className="inline-flex min-w-8 items-center justify-center rounded-lg bg-[#fff4ee] px-2 py-1 text-xs transition hover:bg-[#f5ddd2] hover:text-[#8f1d22] cursor-pointer"
                        title={detail ? `${detail.status} - Klik untuk edit` : "Klik untuk input absensi"}
                      >
                        {detail ? detail.code || "-" : "-"}
                      </button>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <AttendanceInputModal
        selected={selected}
        month={month}
        year={year}
        onClose={() => setSelected(null)}
        onSaved={handleSaved}
      />
    </>
  );
}
