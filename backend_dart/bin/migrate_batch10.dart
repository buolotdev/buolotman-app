import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'] ?? 'postgres://buolot:buolot_password@localhost:5432/buolot_db';
  print('Connecting to DB at $dbUrl');

  final uri = Uri.parse(dbUrl);
  final conn = await Connection.open(
    Endpoint(
      host: uri.host,
      database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'buolot_db',
      username: uri.userInfo.split(':').first,
      password: uri.userInfo.split(':').length > 1 ? uri.userInfo.split(':')[1] : null,
      port: uri.port > 0 ? uri.port : 5432,
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  print('Connected. Running migration batch 10...');

  try {
    // 1. Update `accounts_technician_profile` with missing fields
    final missingFields = [
      'business_type VARCHAR(50)',
      'accepts_individual_jobs BOOLEAN DEFAULT true',
      'accepts_team_projects BOOLEAN DEFAULT true',
      'accepts_long_term_contracts BOOLEAN DEFAULT true',
      'accepts_short_term_jobs BOOLEAN DEFAULT true',
      'can_transport_equipment BOOLEAN DEFAULT false',
      'has_ppe BOOLEAN DEFAULT false',
      'has_specialist_machinery BOOLEAN DEFAULT false',
      'has_driving_licence BOOLEAN DEFAULT false',
      'bm_contractor_projects BOOLEAN DEFAULT false',
      'interested_in_long_term_placement BOOLEAN DEFAULT false',
      'team_leader_experience BOOLEAN DEFAULT false',
      'project_management_experience BOOLEAN DEFAULT false',
    ];

    for (final field in missingFields) {
      final colName = field.split(' ').first;
      try {
        await conn.execute('ALTER TABLE accounts_technician_profile ADD COLUMN $colName ${field.substring(colName.length + 1)}');
        print('Added $colName to accounts_technician_profile');
      } catch (e) {
        if (!e.toString().contains('already exists') && !e.toString().contains('duplicate column')) {
          print('Error adding $colName: $e');
        }
      }
    }

    // 2. Update `accounts_technician_portfolio` with missing fields
    final portfolioFields = [
      'project_location VARCHAR(255)',
      'completion_date VARCHAR(50)',
      'client_company VARCHAR(255)',
      'project_value VARCHAR(100)'
    ];

    for (final field in portfolioFields) {
      final colName = field.split(' ').first;
      try {
        await conn.execute('ALTER TABLE accounts_technician_portfolio ADD COLUMN $colName ${field.substring(colName.length + 1)}');
        print('Added $colName to accounts_technician_portfolio');
      } catch (e) {
        if (!e.toString().contains('already exists') && !e.toString().contains('duplicate column')) {
          print('Error adding $colName: $e');
        }
      }
    }

    // 3. Create Hierarchical Service Tables
    final createCategoryTable = '''
      CREATE TABLE IF NOT EXISTS tasks_category (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE
      );
    ''';
    await conn.execute(createCategoryTable);
    print('Created tasks_category table.');

    final createSubcategoryTable = '''
      CREATE TABLE IF NOT EXISTS tasks_subcategory (
        id SERIAL PRIMARY KEY,
        category_id INTEGER REFERENCES tasks_category(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        UNIQUE (category_id, name)
      );
    ''';
    await conn.execute(createSubcategoryTable);
    print('Created tasks_subcategory table.');

    final createServiceTable = '''
      CREATE TABLE IF NOT EXISTS tasks_service (
        id SERIAL PRIMARY KEY,
        subcategory_id INTEGER REFERENCES tasks_subcategory(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        UNIQUE (subcategory_id, name)
      );
    ''';
    await conn.execute(createServiceTable);
    print('Created tasks_service table.');

    final createTechnicianServicesTable = '''
      CREATE TABLE IF NOT EXISTS accounts_technician_service (
        id SERIAL PRIMARY KEY,
        technician_id INTEGER REFERENCES accounts_technician_profile(id) ON DELETE CASCADE,
        service_id INTEGER REFERENCES tasks_service(id) ON DELETE CASCADE,
        is_verified_skill BOOLEAN DEFAULT false,
        UNIQUE (technician_id, service_id)
      );
    ''';
    await conn.execute(createTechnicianServicesTable);
    print('Created accounts_technician_service table.');

    // 4. Seed initial hierarchical data if empty
    final catCheck = await conn.execute('SELECT count(*) FROM tasks_category');
    if (catCheck.isNotEmpty && int.parse(catCheck.first[0].toString()) == 0) {
      print('Seeding initial hierarchical service data...');
      
      // Category: Electrical & Electronics Engineering
      final cat1Result = await conn.execute("INSERT INTO tasks_category (name) VALUES ('Electrical & Electronics Engineering') RETURNING id");
      final cat1Id = cat1Result.first[0] as int;

      // Subcategory: Electrical Engineering Services
      final sub1Result = await conn.execute("INSERT INTO tasks_subcategory (category_id, name) VALUES ($cat1Id, 'Electrical Engineering Services') RETURNING id");
      final sub1Id = sub1Result.first[0] as int;

      // Services
      final services = [
        'Residential electrical installation',
        'Commercial electrical systems',
        'Generator installation',
        'Solar PV installation',
        'Inverter systems',
        'Electrical inspections'
      ];
      
      for (final srv in services) {
        await conn.execute(Sql.named("INSERT INTO tasks_service (subcategory_id, name) VALUES (@subId, @name)"), parameters: {
          'subId': sub1Id,
          'name': srv
        });
      }

      // Category: Plumbing
      final cat2Result = await conn.execute("INSERT INTO tasks_category (name) VALUES ('Plumbing') RETURNING id");
      final cat2Id = cat2Result.first[0] as int;

      // Subcategory: Pipe fitting
      final sub2Result = await conn.execute("INSERT INTO tasks_subcategory (category_id, name) VALUES ($cat2Id, 'Pipe fitting & Installation') RETURNING id");
      final sub2Id = sub2Result.first[0] as int;

      final services2 = [
        'Water heater installation',
        'Leak detection and repair',
        'Toilet installation',
        'Pipe unclogging'
      ];
      
      for (final srv in services2) {
        await conn.execute(Sql.named("INSERT INTO tasks_service (subcategory_id, name) VALUES (@subId, @name)"), parameters: {
          'subId': sub2Id,
          'name': srv
        });
      }

      print('Seeding completed.');
    } else {
      print('Categories already exist, skipping seeding.');
    }

    print('Migration batch 10 completed successfully.');
  } catch (e, st) {
    print('Migration failed: $e');
    print(st);
  } finally {
    await conn.close();
  }
}
