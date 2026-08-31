import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'];
  if (dbUrl == null) {
    print('DATABASE_URL not found');
    exit(1);
  }

  final uri = Uri.parse(dbUrl);
  final connection = await Connection.open(
    Endpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : 5432,
      database: uri.path.replaceAll('/', ''),
      username: uri.userInfo.split(':')[0],
      password: uri.userInfo.split(':')[1],
    ),
    settings: const ConnectionSettings(sslMode: SslMode.require),
  );

  try {
    print('Running Batch 9 Migration for References, Payouts, and Work Days...');

    // 1. Add fields to accounts_technician_profile
    await connection.execute('''
      ALTER TABLE accounts_technician_profile
      ADD COLUMN IF NOT EXISTS preferred_payout_method VARCHAR(255),
      ADD COLUMN IF NOT EXISTS bank_account_name VARCHAR(255),
      ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(255),
      ADD COLUMN IF NOT EXISTS bank_name VARCHAR(255),
      ADD COLUMN IF NOT EXISTS mobile_money_number VARCHAR(255),
      ADD COLUMN IF NOT EXISTS payout_currency VARCHAR(10),
      ADD COLUMN IF NOT EXISTS payment_verification_status VARCHAR(50) DEFAULT 'Unverified',
      ADD COLUMN IF NOT EXISTS preferred_working_days TEXT,
      ADD COLUMN IF NOT EXISTS preferred_working_hours VARCHAR(255);
    ''');
    print('Updated accounts_technician_profile with payout and work availability fields.');

    // 2. Create accounts_technician_reference table
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS accounts_technician_reference (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
        employer_name VARCHAR(255),
        reference_name VARCHAR(255),
        relationship VARCHAR(255),
        contact_info TEXT,
        recommendation_document_url TEXT,
        status VARCHAR(50) DEFAULT 'Pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    print('Created accounts_technician_reference table.');

  } catch (e) {
    print('Migration error: \$e');
  } finally {
    await connection.close();
  }
}
