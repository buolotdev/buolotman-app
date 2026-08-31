import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'];
  if (dbUrl == null) {
    print('DATABASE_URL not found');
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
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    print('Running Batch 7 Migration for Technician fields...');

    await connection.execute('''
      ALTER TABLE accounts_technician_profile
      ADD COLUMN IF NOT EXISTS cv_resume_url TEXT,
      ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(255),
      ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(50);
    ''');
    print('Successfully added cv_resume_url, emergency_contact_name, emergency_contact_phone to accounts_technician_profile.');

  } catch (e) {
    print('Migration error: \$e');
  } finally {
    await connection.close();
  }
}
