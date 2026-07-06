import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load(['../.env']);
  final dbUrl = env['DATABASE_URL']!;
  final pool = Pool.withUrl(dbUrl);
  
  // Since we also need to delete related data (cascade or manually)
  // we will execute a direct DELETE
  final res = await pool.execute(
    Sql.named('DELETE FROM accounts_user WHERE email = @email RETURNING id, first_name, last_name, email'),
    parameters: {'email': 'tech-testing@gmail.com'},
  );
  
  if (res.isEmpty) {
    print('No user found with email tech-testing@gmail.com');
  } else {
    final row = res[0].toColumnMap();
    print('Deleted: ' + row['first_name'].toString() + ' ' + row['last_name'].toString());
  }
  await pool.close();
}
