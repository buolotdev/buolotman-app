import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'];
  
  if (dbUrl == null || dbUrl.isEmpty) {
    print('ERROR: DATABASE_URL is not set.');
    exit(1);
  }
  
  final uri = Uri.parse(dbUrl);
  final connection = await Connection.open(
    Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.path.replaceAll('/', ''),
      username: uri.userInfo.split(':')[0],
      password: uri.userInfo.split(':')[1],
    ),
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );
  
  print('Running migration batch 5 (certifications)...');

  final sql = '''
    ALTER TABLE accounts_technician_profile
      ADD COLUMN IF NOT EXISTS certifications JSONB DEFAULT '[]';
  ''';
  
  try {
    await connection.execute(sql);
    print('Migration completed successfully.');
  } catch (e) {
    print('Migration failed: \$e');
  } finally {
    await connection.close();
  }
}
