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
    print('Running Batch 8 Migration for Portfolio fields...');

    await connection.execute('''
      ALTER TABLE accounts_portfolio_item
      ADD COLUMN IF NOT EXISTS service_performed VARCHAR(255),
      ADD COLUMN IF NOT EXISTS video_url TEXT,
      ADD COLUMN IF NOT EXISTS project_location VARCHAR(255),
      ADD COLUMN IF NOT EXISTS client_company VARCHAR(255),
      ADD COLUMN IF NOT EXISTS before_image_url TEXT;
    ''');
    print('Successfully added missing fields to accounts_portfolio_item.');

  } catch (e) {
    print('Migration error: \$e');
  } finally {
    await connection.close();
  }
}
