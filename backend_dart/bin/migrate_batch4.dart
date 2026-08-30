import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  print('Loading environment...');
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'];
  
  if (dbUrl == null || dbUrl.isEmpty) {
    print('ERROR: DATABASE_URL is not set.');
    exit(1);
  }
  
  print('Connecting to database...');
  final uri = Uri.parse(dbUrl);
  final host = uri.host;
  final port = uri.hasPort ? uri.port : 5432;
  final databaseName = uri.path.replaceAll('/', '');
  final username = uri.userInfo.split(':')[0];
  final password = uri.userInfo.split(':')[1];
  
  final endpoint = Endpoint(
    host: host,
    port: port,
    database: databaseName,
    username: username,
    password: password,
  );
  
  final connection = await Connection.open(
    endpoint,
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );
  
  print('Connected successfully. Running migration batch 4 (accounts_user fields)...');

  final sql = '''
    ALTER TABLE accounts_user
      ADD COLUMN IF NOT EXISTS country TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS address TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS date_of_birth TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS education_level TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS expertise_level TEXT DEFAULT '';
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
