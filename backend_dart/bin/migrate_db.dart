import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load(['../.env']);
  final dbUrl = env['DATABASE_URL'];
  
  if (dbUrl == null) {
    print('No DATABASE_URL found!');
    return;
  }
  print('Connecting...');
  final pool = Pool.withUrl(dbUrl);
  await pool.execute("ALTER TABLE companies_project ADD COLUMN IF NOT EXISTS milestones_released INTEGER DEFAULT 0;");
  print('Added milestones_released column!');
  await pool.close();
}
