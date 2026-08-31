import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'] ?? 'postgres://buolot:buolot_password@localhost:5432/buolot_db';
  print('Connecting to DB at \$dbUrl');

  final uri = Uri.parse(dbUrl);
  final conn = await Connection.open(
    Endpoint(
      host: uri.host,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'buolot_db',
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':')[1] : null,
      port: uri.port > 0 ? uri.port : 5432,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  print('Connected. Running migration batch 11...');

  try {
    final createPortfolioTable = '''
      CREATE TABLE IF NOT EXISTS accounts_technician_portfolio (
        id SERIAL PRIMARY KEY,
        technician_id INTEGER REFERENCES accounts_technician_profile(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        image_url TEXT,
        project_location VARCHAR(255),
        completion_date VARCHAR(50),
        client_company VARCHAR(255),
        project_value VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''';
    await conn.execute(createPortfolioTable);
    print('Created accounts_technician_portfolio table.');

    print('Migration batch 11 completed successfully.');
  } catch (e, st) {
    print('Migration failed: \$e');
    print(st);
  } finally {
    await conn.close();
  }
}
