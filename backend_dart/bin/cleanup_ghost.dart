import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load(['../.env']);
  final dbUrl = env['DATABASE_URL']!;
  final pool = Pool.withUrl(dbUrl);
  
  // Find any ghost accounts that were soft-deleted but still blocking registration
  final res = await pool.execute(
    Sql.named("SELECT id, first_name, email, username, is_active FROM accounts_user WHERE email ILIKE '%tech-testing%' OR username ILIKE '%tech-testing%'"),
  );
  
  for (final row in res) {
    final m = row.toColumnMap();
    print('Found: $m');
    final id = m['id'] as int;
    // Anonymize so re-registration works
    await pool.execute(
      Sql.named("UPDATE accounts_user SET is_active = false, email = 'del$id@x.co', username = 'del$id@x.co', phone = LEFT('del$id', 15) WHERE id = @id"),
      parameters: {'id': id},
    );
    print('Anonymized user id=$id');
  }
  
  if (res.isEmpty) {
    print('No ghost accounts found.');
  }
  
  await pool.close();
}
