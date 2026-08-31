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
    for (var table in ['accounts_user', 'accounts_technician_profile', 'accounts_portfolio_item']) {
      var res = await connection.execute("SELECT column_name FROM information_schema.columns WHERE table_name = '" + table + "'");
      var cols = res.map((e) => e[0] as String).toList();
      print(table + " COLUMNS: " + cols.join(', '));
    }
  } catch(e) {
    print(e);
  } finally {
    await connection.close();
  }
}
