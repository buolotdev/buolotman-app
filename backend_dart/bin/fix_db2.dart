import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  final dbUrl = Platform.environment['DATABASE_URL'];
  if (dbUrl == null) {
    print('No DATABASE_URL found!');
    return;
  }
  print('Connecting...');
  final pool = Pool.withUrl(dbUrl);
  await pool.execute("UPDATE companies_project SET milestones_total = 3 WHERE title = 'test'");
  print('Updated milestones_total to 3!');
  await pool.close();
}
