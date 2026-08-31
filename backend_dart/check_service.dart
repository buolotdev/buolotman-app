import 'package:postgres/postgres.dart';
void main() async {
  final conn = await Connection.open(
    Endpoint(host: 'ep-patient-cloud-ab3hrp06.eu-west-2.aws.neon.tech', database: 'neondb', username: 'neondb_owner', password: r'npg_HhY9Sebxv3tn', port: 5432),
    settings: ConnectionSettings(sslMode: SslMode.require)
  );
  final res = await conn.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'accounts_technician_service'");
  print(res.map((r) => '${r[0]}: ${r[1]}').toList());
  await conn.close();
}
