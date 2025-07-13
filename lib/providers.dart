import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_database.dart';
import 'data/i_data_source.dart';
import 'data/local_db_data_source.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final dataSourceProvider = Provider<IDataSource>(
  (ref) => LocalDbDataSource(ref.watch(databaseProvider)),
);

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
}); 