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
    var res = await connection.execute("SELECT column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_name = 'accounts_technician_profile' AND column_name IN ('selfie_url', 'national_id_front', 'national_id_back', 'national_id_number')");
    for (var r in res) {
      print("accounts_technician_profile " + r[0].toString() + ": " + r[1].toString() + " | " + (r[2]?.toString() ?? 'null'));
    }
  } catch(e) {
    print(e);
  } finally {
    await connection.close();
  }
}
