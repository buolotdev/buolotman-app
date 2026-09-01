import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL']!;
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
    await connection.execute("ALTER TABLE accounts_user ADD COLUMN date_of_birth VARCHAR(255) DEFAULT '';");
    print("Added date_of_birth to accounts_user.");
  } catch (e) {
    print("Error adding date_of_birth: \$e");
  }

  try {
    await connection.execute("ALTER TABLE accounts_user ADD COLUMN education_level VARCHAR(255) DEFAULT '';");
    print("Added education_level to accounts_user.");
  } catch (e) {
    print("Error adding education_level: \$e");
  }

  try {
    await connection.execute("ALTER TABLE accounts_user ADD COLUMN expertise_level VARCHAR(255) DEFAULT '';");
    print("Added expertise_level to accounts_user.");
  } catch (e) {
    print("Error adding expertise_level: \$e");
  }

  try {
    await connection.execute("ALTER TABLE accounts_technician_profile ADD COLUMN preferred_languages JSONB DEFAULT '[]'::jsonb;");
    print("Added preferred_languages to accounts_technician_profile.");
  } catch (e) {
    print("Error adding preferred_languages: \$e");
  }

  await connection.close();
}
