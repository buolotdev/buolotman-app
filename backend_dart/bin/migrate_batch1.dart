import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  final env = DotEnv()..load(['../.env']);
  final dbUrl = env['DATABASE_URL'];
  
  if (dbUrl == null) {
    print('No DATABASE_URL found!');
    return;
  }
  print('Connecting to DB...');
  final pool = Pool.withUrl(dbUrl);
  
  try {
    // Technician profile new fields
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS daily_rate NUMERIC DEFAULT 0;");
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS fixed_price NUMERIC DEFAULT 0;");
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS inspection_fee NUMERIC DEFAULT 0;");
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS work_preferences JSONB;");
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS tools_and_equipment JSONB;");
    
    print('Added technician fields!');

    // Company profile new fields
    await pool.execute("ALTER TABLE companies_profile ADD COLUMN IF NOT EXISTS company_size CHARACTER VARYING;");
    await pool.execute("ALTER TABLE companies_profile ADD COLUMN IF NOT EXISTS capabilities JSONB;");
    
    print('Added company fields!');
    
  } catch (e) {
    print('Error during migration: $e');
  } finally {
    await pool.close();
    print('Migration complete!');
  }
}
