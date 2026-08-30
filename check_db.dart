import 'dart:io'; import 'package:postgres/postgres.dart'; import 'package:dotenv/dotenv.dart'; void main() async { var env = DotEnv(includePlatformEnvironment: true)..load(); final dbUrl = env['DATABASE_URL']!; final uri = Uri.parse(dbUrl); final connection = await Connection.open(Endpoint(host: uri.host, port: uri.hasPort ? uri.port : 5432, database: uri.path.replaceAll('/', ''), username: uri.userInfo.split(':')[0], password: uri.userInfo.split(':')[1]), settings: const ConnectionSettings(sslMode: SslMode.require)); var res1 = await connection.execute(\
SELECT
column_name
FROM
information_schema.columns
WHERE
table_name
=
accounts_user
\); print('accounts_user columns: ' + res1.map((r) => r[0]).join(', ')); var res2 = await connection.execute(\SELECT
column_name
FROM
information_schema.columns
WHERE
table_name
=
accounts_technician_profile
\); print('accounts_technician_profile columns: ' + res2.map((r) => r[0]).join(', ')); await connection.close(); }
