import 'package:go_router/go_router.dart';

import '../pages/admin/tahun_ajaran_list_page.dart';
import '../pages/admin/tambah_tahun_ajaran_page.dart';

final adminRouter = createAdminRouter();

GoRouter createAdminRouter() => GoRouter(
  initialLocation: AdminRoutePaths.tahunAjaran,
  routes: [
    GoRoute(
      path: AdminRoutePaths.tahunAjaran,
      builder: (context, state) => const TahunAjaranListPage(),
      routes: [
        GoRoute(
          path: AdminRoutePaths.tambahTahunAjaranSegment,
          builder: (context, state) => const TambahTahunAjaranPage(),
        ),
      ],
    ),
  ],
);

abstract final class AdminRoutePaths {
  static const tahunAjaran = '/admin/tahun-ajaran';
  static const tambahTahunAjaranSegment = 'tambah';
  static const tambahTahunAjaran = '$tahunAjaran/$tambahTahunAjaranSegment';
}
