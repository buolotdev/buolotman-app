import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  print('Loading environment...');
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'];
  
  if (dbUrl == null || dbUrl.isEmpty) {
    print('ERROR: DATABASE_URL is not set.');
    exit(1);
  }
  
  print('Connecting to database...');
  
  // Parse Supabase connection string
  final uri = Uri.parse(dbUrl);
  final host = uri.host;
  final port = uri.hasPort ? uri.port : 5432;
  final databaseName = uri.path.replaceAll('/', '');
  final username = uri.userInfo.split(':')[0];
  final password = uri.userInfo.split(':')[1];
  
  final endpoint = Endpoint(
    host: host,
    port: port,
    database: databaseName,
    username: username,
    password: password,
  );
  
  final connection = await Connection.open(
    endpoint,
    settings: const ConnectionSettings(
      sslMode: SslMode.require,
    ),
  );
  
  print('Connected successfully. Running migration batch 3 (technician profile)...');

  final sql = '''
    ALTER TABLE accounts_technician_profile
      ADD COLUMN IF NOT EXISTS experience TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS daily_rate NUMERIC(10,2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS fixed_price NUMERIC(10,2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS inspection_fee NUMERIC(10,2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS starting_price NUMERIC(10,2) DEFAULT 0,
      ADD COLUMN IF NOT EXISTS work_preferences JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS tools_and_equipment JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS licences JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS years_experience INTEGER DEFAULT 0,
      ADD COLUMN IF NOT EXISTS primary_occupation TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS city TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS preferred_languages JSONB DEFAULT '[]',
      ADD COLUMN IF NOT EXISTS verification_badge TEXT DEFAULT 'Unverified',
      ADD COLUMN IF NOT EXISTS tagline TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS national_id_number TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS national_id_front TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS national_id_back TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS selfie_url TEXT DEFAULT '',
      ADD COLUMN IF NOT EXISTS own_tools BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS has_vehicle BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS willing_to_travel BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS service_radius_km INTEGER DEFAULT 0,
      ADD COLUMN IF NOT EXISTS available_now BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS accepts_full_time BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS accepts_part_time BOOLEAN DEFAULT true,
      ADD COLUMN IF NOT EXISTS accepts_emergency BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS accepts_weekends BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS accepts_remote BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS accepts_onsite BOOLEAN DEFAULT true,
      ADD COLUMN IF NOT EXISTS bm_concierge BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS bm_build_team BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS bm_emergency BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS can_supervise BOOLEAN DEFAULT false;
  ''';
  
  try {
    await connection.execute(sql);
    print('Migration completed successfully.');
  } catch (e) {
    print('Migration failed: \$e');
  } finally {
    await connection.close();
  }
}
