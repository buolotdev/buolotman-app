import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load(['../.env']);
  final dbUrl = env['DATABASE_URL']!;
  final pool = Pool.withUrl(dbUrl);
  
  final res = await pool.execute(
    Sql.named("SELECT id, first_name, last_name, email FROM accounts_user WHERE email ILIKE '%tech%testing%' OR first_name ILIKE '%Liam%' OR last_name ILIKE '%Liam%'"),
  );
  
  for (final row in res) {
    print(row.toColumnMap());
  }

  // delete
  final res2 = await pool.execute(
    Sql.named("DELETE FROM accounts_user WHERE email ILIKE '%tech%testing%' OR first_name ILIKE '%Liam%' OR last_name ILIKE '%Liam%' RETURNING id, email"),
  );
  for (final row in res2) {
    print("Deleted: " + row.toColumnMap().toString());
  }

  await pool.close();
}
