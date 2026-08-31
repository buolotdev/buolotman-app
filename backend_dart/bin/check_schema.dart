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
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );
  
  try {
    var res = await connection.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'accounts_technician_profile'");
    var cols = res.map((e) => e[0] as String).toList();
    print("TECHNICIAN PROFILE COLUMNS: $cols");

    var res2 = await connection.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'accounts_user'");
    var cols2 = res2.map((e) => e[0] as String).toList();
    print("USER COLUMNS: $cols2");
  } catch(e) {
    print(e);
  } finally {
    await connection.close();
  }
}
