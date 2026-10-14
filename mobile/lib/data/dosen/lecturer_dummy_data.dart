import '../../models/dosen/attendance_session.dart';
import '../../models/dosen/attendance_status.dart';
import '../../models/dosen/student_attendance.dart';

/// Data sementara. Ganti dengan repository/API saat backend siap.
abstract final class LecturerDummyData {
  static const _kelas = 'TI-3A';

  static final session = AttendanceSession(
    className: _kelas,
    date: DateTime(2024, 5, 15),
    students: const [
      StudentAttendance(nim: '2211001', name: 'Adi Saputra', className: _kelas, status: AttendanceStatus.hadir, checkInTime: '07:58'),
      StudentAttendance(nim: '2211002', name: 'Budi Santoso', className: _kelas, status: AttendanceStatus.hadir, checkInTime: '08:02'),
      StudentAttendance(
        nim: '2211003', name: 'Citra Lestari', className: _kelas, status: AttendanceStatus.izin,
        note: 'Ada keperluan keluarga.',
        document: SupportingDocument(fileName: 'Surat_Izin_Citra.jpg', sizeLabel: '245 KB'),
      ),
      StudentAttendance(nim: '2211004', name: 'Dina Rahma', className: _kelas, status: AttendanceStatus.hadir, checkInTime: '08:10'),
      StudentAttendance(
        nim: '2211005', name: 'Eko Prasetyo', className: _kelas, status: AttendanceStatus.sakit,
        note: 'Demam, istirahat sesuai anjuran dokter.',
        document: SupportingDocument(fileName: 'Surat_Dokter_Eko.jpg', sizeLabel: '312 KB'),
      ),
      StudentAttendance(nim: '2211006', name: 'Fitri Ananda', className: _kelas, status: AttendanceStatus.hadir, checkInTime: '08:05'),
      StudentAttendance(nim: '2211007', name: 'Galih Pratama', className: _kelas, status: AttendanceStatus.alfa),
      StudentAttendance(nim: '2211008', name: 'Gita Maharani', className: _kelas, status: AttendanceStatus.hadir, checkInTime: '08:01'),
      StudentAttendance(nim: '2211009', name: 'Hendra Wijaya', className: _kelas, status: AttendanceStatus.hadir, checkInTime: '08:07'),
      StudentAttendance(nim: '2211010', name: 'Indah Permata', className: _kelas, status: AttendanceStatus.hadir, checkInTime: '07:55'),
    ],
  );
}