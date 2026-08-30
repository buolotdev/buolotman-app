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
    // Technician profile document URLs
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS national_id_front CHARACTER VARYING;");
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS national_id_back CHARACTER VARYING;");
    await pool.execute("ALTER TABLE accounts_technician_profile ADD COLUMN IF NOT EXISTS selfie_url CHARACTER VARYING;");
    print('Added technician document fields!');

    // Company profile document URLs
    await pool.execute("ALTER TABLE companies_profile ADD COLUMN IF NOT EXISTS business_registration_url CHARACTER VARYING;");
    await pool.execute("ALTER TABLE companies_profile ADD COLUMN IF NOT EXISTS tax_id_url CHARACTER VARYING;");
    await pool.execute("ALTER TABLE companies_profile ADD COLUMN IF NOT EXISTS operating_licence_url CHARACTER VARYING;");
    print('Added company document fields!');
    
  } catch (e) {
    print('Error during migration: $e');
  } finally {
    await pool.close();
    print('Migration complete!');
  }
}
