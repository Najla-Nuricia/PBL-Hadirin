import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api_config.dart';
import 'admin_auth_repository.dart';
import 'jadwal.dart';
import 'kelas.dart';
import 'tahun_ajaran.dart';

/// Hasil create dosen. `initialPassword` hanya dikirim backend sekali pada
/// response 201 dan wajib ditampilkan ke admin sebelum dialog ditutup.
class DosenCreateResult {
  const DosenCreateResult({required this.dosen, this.initialPassword});

  factory DosenCreateResult.fromAdminApiJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi data dosen.',
      );
    }
    return DosenCreateResult(
      dosen: Dosen.fromAdminApiJson(data),
      initialPassword: _optionalString(json['initial_password']),
    );
  }

  factory DosenCreateResult.fromJson(Map<String, dynamic> json) =>
      DosenCreateResult.fromAdminApiJson(json);

  final Dosen dosen;
  final String? initialPassword;

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }
}

/// Client API untuk CRUD master data admin.
///
/// Endpoint backend memakai satu sumber data untuk halaman admin dan modul
/// lain yang membaca tahun ajaran/mata kuliah.
class AdminMasterDataService {
  AdminMasterDataService({
    http.Client? httpClient,
    String? Function()? tokenProvider,
  }) : _client = httpClient ?? http.Client(),
       _tokenProvider =
           tokenProvider ?? (() => adminAuthRepository.currentAccessToken);

  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final String? Function() _tokenProvider;

  Future<List<TahunAjaran>> listTahunAjaran({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _send(
      () => _client.get(
        _uri('/admin/tahun-ajaran', query),
        headers: _authHeaders(),
      ),
    );
    final data = _listData(response);
    return data.map(_tahunFromJson).toList(growable: false);
  }

  Future<TahunAjaran> createTahunAjaran({
    required String tahun,
    required TahunAjaranStatus status,
    required bool semesterGanjil,
    required bool semesterGenap,
    required DateTime? tanggalMulai,
    required DateTime? tanggalSelesai,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/tahun-ajaran'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'tahun': tahun.trim(),
          'status': _statusValue(status),
          'semester_ganjil': semesterGanjil,
          'semester_genap': semesterGenap,
          'tanggal_mulai': _dateValue(tanggalMulai),
          'tanggal_selesai': _dateValue(tanggalSelesai),
        }),
      ),
      expectedStatus: 201,
    );
    return _tahunFromJson(_objectData(response));
  }

  Future<TahunAjaran> updateTahunAjaran({
    required String id,
    required String tahun,
    required TahunAjaranStatus status,
    required bool semesterGanjil,
    required bool semesterGenap,
    required DateTime? tanggalMulai,
    required DateTime? tanggalSelesai,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/tahun-ajaran/${Uri.encodeComponent(id)}'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'tahun': tahun.trim(),
          'status': _statusValue(status),
          'semester_ganjil': semesterGanjil,
          'semester_genap': semesterGenap,
          'tanggal_mulai': _dateValue(tanggalMulai),
          'tanggal_selesai': _dateValue(tanggalSelesai),
        }),
      ),
    );
    return _tahunFromJson(_objectData(response));
  }

  Future<void> deleteTahunAjaran(String id) async {
    await _send(
      () => _client.delete(
        _uri('/admin/tahun-ajaran/${Uri.encodeComponent(id)}'),
        headers: _authHeaders(),
      ),
    );
  }

  Future<List<MataKuliah>> listMataKuliah({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _send(
      () => _client.get(
        _uri('/admin/mata-kuliah', query),
        headers: _authHeaders(),
      ),
    );
    final data = _listData(response);
    return data.map(_mataKuliahFromJson).toList(growable: false);
  }

  Future<MataKuliah> createMataKuliah({
    required String kode,
    required String nama,
    required int semester,
    required int sks,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/mata-kuliah'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'kode': kode.trim(),
          'nama': nama.trim(),
          'semester': semester,
          'sks': sks,
        }),
      ),
      expectedStatus: 201,
    );
    return _mataKuliahFromJson(_objectData(response));
  }

  Future<MataKuliah> updateMataKuliah({
    required String originalKode,
    required String kode,
    required String nama,
    required int semester,
    required int sks,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/mata-kuliah/${Uri.encodeComponent(originalKode)}'),
        headers: _jsonHeaders(),
        body: jsonEncode({
          'kode': kode.trim(),
          'nama': nama.trim(),
          'semester': semester,
          'sks': sks,
        }),
      ),
    );
    return _mataKuliahFromJson(_objectData(response));
  }

  Future<void> deleteMataKuliah(String kode) async {
    await _send(
      () => _client.delete(
        _uri('/admin/mata-kuliah/${Uri.encodeComponent(kode)}'),
        headers: _authHeaders(),
      ),
    );
  }

  /// Daftar dosen. Dipakai baik oleh master data admin maupun pilihan dosen
  /// pada form jadwal.
  Future<List<Dosen>> listDosen({String? search}) async {
    final response = await _send(
      () => _client.get(
        _uri('/admin/dosen', _searchQuery(search)),
        headers: _authHeaders(),
      ),
    );
    return _listData(response)
        .map(Dosen.fromAdminApiJson)
        .toList(growable: false);
  }

  Future<Dosen> getDosen(String nip) async {
    final response = await _send(
      () => _client.get(
        _uri('/admin/dosen/${Uri.encodeComponent(nip)}'),
        headers: _authHeaders(),
      ),
    );
    return Dosen.fromAdminApiJson(_directObject(response));
  }

  /// Optional fields dikirim hanya bila terisi, agar tidak lolos validasi
  /// email backend (string kosong dianggap email invalid).
  Future<DosenCreateResult> createDosen({
    required String nip,
    required String nama,
    String? email,
    String? noHp,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/dosen'),
        headers: _jsonHeaders(),
        body: jsonEncode(_dosenPayload(
          nip: nip,
          nama: nama,
          email: email,
          noHp: noHp,
        )),
      ),
      expectedStatus: 201,
    );
    return DosenCreateResult.fromAdminApiJson(_decodedMap(response));
  }

  Future<Dosen> updateDosen({
    required String nip,
    required String nama,
    String? email,
    String? noHp,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/dosen/${Uri.encodeComponent(nip)}'),
        headers: _jsonHeaders(),
        body: jsonEncode(_dosenPayload(
          nip: nip,
          nama: nama,
          email: email,
          noHp: noHp,
        )),
      ),
    );
    return Dosen.fromAdminApiJson(_objectData(response));
  }

  Future<String> deleteDosen(String nip) async {
    final response = await _send(
      () => _client.delete(
        _uri('/admin/dosen/${Uri.encodeComponent(nip)}'),
        headers: _authHeaders(),
      ),
    );
    return _message(response, 'Dosen berhasil dihapus.');
  }

  Map<String, dynamic> _dosenPayload({
    required String nip,
    required String nama,
    String? email,
    String? noHp,
  }) {
    final cleanEmail = email?.trim() ?? '';
    final cleanNoHp = noHp?.trim() ?? '';
    return {
      'nip': nip.trim(),
      'nama': nama.trim(),
      if (cleanEmail.isNotEmpty) 'email': cleanEmail,
      if (cleanNoHp.isNotEmpty) 'no_hp': cleanNoHp,
    };
  }

  /// Pilihan program studi untuk form jadwal.
  Future<List<ProgramStudi>> listProgramStudi() async {
    final response = await _send(
      () => _client.get(_uri('/admin/program-studi'), headers: _authHeaders()),
    );
    return _listData(response)
        .map(
          (json) => ProgramStudi(
            kode: _string(json['kode']),
            nama: _string(json['nama']),
          ),
        )
        .toList(growable: false);
  }

  /// Daftar ruangan, dengan pencarian opsional lewat query `?search=`.
  Future<List<Ruangan>> listRuangan({String? search}) async {
    final response = await _send(
      () => _client.get(
        _uri('/admin/ruangan', _searchQuery(search)),
        headers: _authHeaders(),
      ),
    );
    return _listData(response)
        .map(Ruangan.fromAdminApiJson)
        .toList(growable: false);
  }

  Future<Ruangan> getRuangan(String kode) async {
    final response = await _send(
      () => _client.get(
        _uri('/admin/ruangan/${Uri.encodeComponent(kode)}'),
        headers: _authHeaders(),
      ),
    );
    return Ruangan.fromAdminApiJson(_directObject(response));
  }

  Future<Ruangan> createRuangan({
    required String kode,
    required String nama,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/ruangan'),
        headers: _jsonHeaders(),
        body: jsonEncode(Ruangan(kode: kode, nama: nama).toAdminApiJson()),
      ),
      expectedStatus: 201,
    );
    return Ruangan.fromAdminApiJson(_objectData(response));
  }

  /// [kodeLama] dipakai pada path; `kode` di body boleh berbeda (rename).
  Future<Ruangan> updateRuangan({
    required String kodeLama,
    required String kode,
    required String nama,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/ruangan/${Uri.encodeComponent(kodeLama)}'),
        headers: _jsonHeaders(),
        body: jsonEncode(Ruangan(kode: kode, nama: nama).toAdminApiJson()),
      ),
    );
    return Ruangan.fromAdminApiJson(_objectData(response));
  }

  Future<String> deleteRuangan(String kode) async {
    final response = await _send(
      () => _client.delete(
        _uri('/admin/ruangan/${Uri.encodeComponent(kode)}'),
        headers: _authHeaders(),
      ),
    );
    return _message(response, 'Ruangan berhasil dihapus.');
  }

  /// Pilihan sesi kuliah untuk form jadwal.
  Future<List<SesiKuliah>> listSesiKuliah() async {
    final response = await _send(
      () => _client.get(_uri('/admin/sesi-kuliah'), headers: _authHeaders()),
    );
    return _listData(response)
        .map(
          (json) => SesiKuliah(
            nomor: _integer(json['nomor']),
            jamMulai: _string(json['jam_mulai']),
            jamSelesai: _string(json['jam_selesai']),
          ),
        )
        .toList(growable: false);
  }

  /// Pilihan kelas untuk form jadwal, dibatasi pada tahun ajaran aktif.
  Future<List<KelasKuliah>> listKelas({String? tahunAjaran}) async {
    final query = <String, String>{};
    if (tahunAjaran != null && tahunAjaran.trim().isNotEmpty) {
      query['tahun_ajaran'] = tahunAjaran.trim();
    }
    final response = await _send(
      () => _client.get(_uri('/kelas', query), headers: _authHeaders()),
    );
    return _listData(response)
        .map(
          (json) => KelasKuliah(
            nama: _string(json['nama']),
            tingkat: _integer(json['tingkat']),
            programStudiKode: _string(json['program_studi_kode']),
          ),
        )
        .toList(growable: false);
  }

  /// Daftar kelas untuk master data admin (endpoint `/admin/kelas`) dengan
  /// filter opsional search, program studi, tahun ajaran, dan status.
  Future<List<Kelas>> listKelasMaster({
    String? search,
    String? programStudiKode,
    String? tahunAjaranId,
    KelasStatus? status,
  }) async {
    final query = _searchQuery(search);
    if (programStudiKode != null && programStudiKode.trim().isNotEmpty) {
      query['program_studi_kode'] = programStudiKode.trim();
    }
    if (tahunAjaranId != null && tahunAjaranId.trim().isNotEmpty) {
      query['tahun_ajaran_id'] = tahunAjaranId.trim();
    }
    if (status != null) query['status'] = status.apiValue;
    final response = await _send(
      () => _client.get(
        _uri('/admin/kelas', query),
        headers: _authHeaders(),
      ),
    );
    return _listData(response)
        .map(Kelas.fromAdminApiJson)
        .toList(growable: false);
  }

  Future<Kelas> getKelas(String id) async {
    final response = await _send(
      () => _client.get(
        _uri('/admin/kelas/${Uri.encodeComponent(id)}'),
        headers: _authHeaders(),
      ),
    );
    return Kelas.fromAdminApiJson(_directObject(response));
  }

  Future<Kelas> createKelas({
    required String nama,
    required int tingkat,
    required String programStudiKode,
    required String tahunAjaranId,
    int kapasitas = 30,
    KelasStatus status = KelasStatus.aktif,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri('/admin/kelas'),
        headers: _jsonHeaders(),
        body: jsonEncode(_kelasPayload(
          nama: nama,
          tingkat: tingkat,
          programStudiKode: programStudiKode,
          tahunAjaranId: tahunAjaranId,
          kapasitas: kapasitas,
          status: status,
        )),
      ),
      expectedStatus: 201,
    );
    return Kelas.fromAdminApiJson(_objectData(response));
  }

  Future<Kelas> updateKelas({
    required String id,
    required String nama,
    required int tingkat,
    required String programStudiKode,
    required String tahunAjaranId,
    int kapasitas = 30,
    KelasStatus status = KelasStatus.aktif,
  }) async {
    final response = await _send(
      () => _client.put(
        _uri('/admin/kelas/${Uri.encodeComponent(id)}'),
        headers: _jsonHeaders(),
        body: jsonEncode(_kelasPayload(
          nama: nama,
          tingkat: tingkat,
          programStudiKode: programStudiKode,
          tahunAjaranId: tahunAjaranId,
          kapasitas: kapasitas,
          status: status,
        )),
      ),
    );
    return Kelas.fromAdminApiJson(_objectData(response));
  }

  Future<String> deleteKelas(String id) async {
    final response = await _send(
      () => _client.delete(
        _uri('/admin/kelas/${Uri.encodeComponent(id)}'),
        headers: _authHeaders(),
      ),
    );
    return _message(response, 'Kelas berhasil dihapus.');
  }

  Map<String, dynamic> _kelasPayload({
    required String nama,
    required int tingkat,
    required String programStudiKode,
    required String tahunAjaranId,
    required int kapasitas,
    required KelasStatus status,
  }) => Kelas(
    id: '',
    nama: nama,
    tingkat: tingkat,
    programStudiKode: programStudiKode,
    tahunAjaranId: tahunAjaranId,
    kapasitas: kapasitas,
    status: status,
  ).toAdminApiJson();

  Map<String, String> _searchQuery(String? search) =>
      search != null && search.trim().isNotEmpty
      ? {'search': search.trim()}
      : const <String, String>{};

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Map<String, String> _authHeaders() {
    final token = _requireToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Map<String, String> _jsonHeaders() => {
    ..._authHeaders(),
    'Content-Type': 'application/json',
  };

  String _requireToken() {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const AdminRemoteApiException(
        'Sesi admin tidak ditemukan. Silakan masuk ulang.',
        statusCode: 401,
      );
    }
    return token;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    int expectedStatus = 200,
  }) async {
    try {
      final response = await request().timeout(_timeout);
      if (response.statusCode == expectedStatus) return response;
      throw _errorFrom(response);
    } on AdminRemoteApiException {
      rethrow;
    } catch (_) {
      throw AdminRemoteApiException(
        'Gagal terhubung ke server backend di ${ApiConfig.baseUrl}. '
        'Pastikan server backend sedang aktif.',
      );
    }
  }

  AdminRemoteApiException _errorFrom(http.Response response) {
    // 401/403 juga dapat membawa `detail` spesifik dari backend.
    final detail = _extractDetail(response, 'Operasi master data gagal.');
    if (response.statusCode == 401 || response.statusCode == 403) {
      return AdminRemoteApiException(
        detail == 'Operasi master data gagal.'
            ? 'Sesi login berakhir. Silakan masuk ulang.'
            : detail,
        statusCode: response.statusCode,
      );
    }
    return AdminRemoteApiException(
      detail,
      statusCode: response.statusCode,
    );
  }

  String _extractDetail(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        return decoded['detail'] as String;
      }
    } catch (_) {}
    return fallback;
  }

  List<Map<String, dynamic>> _listData(http.Response response) {
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi daftar master data.',
      );
    }
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Map<String, dynamic> _objectData(http.Response response) {
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi data master.',
      );
    }
    return data;
  }

  /// Endpoint detail mengembalikan objek item langsung (tanpa wrapper `data`).
  Map<String, dynamic> _directObject(http.Response response) {
    final decoded = _decodedMap(response);
    if (decoded['data'] is Map<String, dynamic>) {
      return decoded['data'] as Map<String, dynamic>;
    }
    return decoded;
  }

  Map<String, dynamic> _decodedMap(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AdminRemoteApiException(
        'Respons backend tidak berisi objek JSON.',
      );
    }
    return decoded;
  }

  String _message(http.Response response, String fallback) {
    final decoded = _decodedMap(response);
    final message = decoded['message'];
    return message is String && message.isNotEmpty ? message : fallback;
  }

  TahunAjaran _tahunFromJson(Map<String, dynamic> json) {
    return TahunAjaran(
      id: _string(json['id']),
      tahun: _string(json['tahun']),
      status: _string(json['status']).toLowerCase() == 'aktif'
          ? TahunAjaranStatus.aktif
          : TahunAjaranStatus.nonAktif,
      semesterGanjil: json['semester_ganjil'] == true,
      semesterGenap: json['semester_genap'] == true,
      tanggalMulai: _date(json['tanggal_mulai']),
      tanggalSelesai: _date(json['tanggal_selesai']),
    );
  }

  MataKuliah _mataKuliahFromJson(Map<String, dynamic> json) {
    return MataKuliah(
      id: _string(json['kode']),
      kode: _string(json['kode']),
      nama: _string(json['nama']),
      semester: _integer(json['semester']),
      sks: _integer(json['sks']),
    );
  }

  static String _statusValue(TahunAjaranStatus status) =>
      status == TahunAjaranStatus.aktif ? 'aktif' : 'non_aktif';

  static String? _dateValue(DateTime? value) =>
      value?.toIso8601String().split('T').first;

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());

  static String _string(Object? value) => value?.toString() ?? '';

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(_string(value)) ?? 0;
}

final adminMasterDataService = AdminMasterDataService();
