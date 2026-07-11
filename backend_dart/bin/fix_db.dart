import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(Endpoint(
    host: 'ep-aged-snowflake-a5t485x1-pooler.us-east-2.aws.neon.tech',
    database: 'neondb',
    username: 'neondb_owner',
    password: 'npg_1G5SgDmykEIF',
    port: 5432,
  ), settings: ConnectionSettings(sslMode: SslMode.require));

  await conn.execute("UPDATE companies_project SET milestones_total = 3 WHERE title = 'test'");
  print('Updated milestones_total to 3!');
  await conn.close();
}
