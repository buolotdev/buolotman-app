import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final r = await http.post(
      Uri.parse('https://buolotman-app.onrender.com/api/auth/register/technician/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': 'Test',
        'last_name': 'Tech',
        'email': 'testtech23@test.com',
        'password': 'password123',
        'phone': '1234567891'
      })
    );
    print('REGISTER: ' + r.body);

    final auth = await http.post(
      Uri.parse('https://buolotman-app.onrender.com/api/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': 'testtech23@test.com',
        'password': 'password123'
      })
    );
    print('LOGIN: ' + auth.body);

    final token = jsonDecode(auth.body)['access'];

    final res = await http.get(
      Uri.parse('https://buolotman-app.onrender.com/api/tasks/'),
      headers: {'Authorization': 'Bearer $token'}
    );
    print('TASKS: ' + res.body);
  } catch (e) {
    print('ERROR: $e');
  }
}
