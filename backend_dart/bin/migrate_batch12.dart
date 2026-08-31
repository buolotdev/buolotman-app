import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final dbUrl = Platform.environment['DATABASE_URL'] ?? 'postgresql://neondb_owner:npg_HhY9Sebxv3tn@ep-patient-cloud-ab3hrp06.eu-west-2.aws.neon.tech/neondb?sslmode=require';
  
  final uri = Uri.parse(dbUrl);
  final username = uri.userInfo.split(':')[0];
  final password = uri.userInfo.split(':')[1];
  final dbHost = uri.host;
  final dbPort = uri.port == 0 ? 5432 : uri.port;
  final dbName = uri.path.replaceAll('/', '');

  final conn = await Connection.open(
    Endpoint(
      host: dbHost,
      port: dbPort,
      database: dbName,
      username: username,
      password: password,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    print('Starting migration 12...');

    // Drop old accounts_technician_service table
    await conn.execute('DROP TABLE IF EXISTS accounts_technician_service CASCADE');
    print('Dropped old accounts_technician_service table.');

    // Create correct many-to-many relationship mapping table
    final createMappingTable = '''
      CREATE TABLE accounts_technician_service (
        id SERIAL PRIMARY KEY,
        technician_id INTEGER REFERENCES accounts_technician_profile(id) ON DELETE CASCADE,
        service_id INTEGER REFERENCES tasks_service(id) ON DELETE CASCADE,
        is_verified_skill BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (technician_id, service_id)
      );
    ''';
    await conn.execute(createMappingTable);
    print('Created correct accounts_technician_service table.');

    print('Migration 12 completed successfully.');
  } catch (e, st) {
    print('Migration failed: $e');
    print(st);
  } finally {
    await conn.close();
  }
}
