import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'];
  final uri = Uri.parse(dbUrl!);
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
    var res = await connection.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'");
    var tables = res.map((e) => e[0] as String).toList();
    print("TABLES: $tables");
  } catch(e) {
    print(e);
  } finally {
    await connection.close();
  }
}
