import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://localhost:8000/api';
  final ts = DateTime.now().millisecondsSinceEpoch;
  final email = 'test' + ts.toString() + '@test.com';
  
  print('Registering ' + email + '...');
  var res = await http.post(
    Uri.parse(baseUrl + '/auth/register/technician/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': 'password123',
      'first_name': 'Test',
      'last_name': 'Test',
      'phone_number': '1234567890'
    })
  );
  print('Reg: ' + res.statusCode.toString() + ' ' + res.body);

  res = await http.post(
    Uri.parse(baseUrl + '/auth/login/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': 'password123'
    })
  );
  print('Login: ' + res.statusCode.toString());
  
  if (res.statusCode != 200) return;
  final data = jsonDecode(res.body);
  final token = data['access'];
  
  res = await http.patch(
    Uri.parse(baseUrl + '/auth/me/'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token.toString()
    },
    body: jsonEncode({
      "first_name": "Test",
      "last_name": "Test",
      "phone": "1234567890",
      "country": "US",
      "bio": "test bio",
      "tagline": "test tagline",
      "hourly_rate": 50.0,
      "daily_rate": 400.0,
      "fixed_price": 0.0,
      "inspection_fee": 20.0,
      "starting_price": 50.0,
      "availability_status": "available",
      "skills": ["Plumbing", "Electrical"],
      "certifications": ["Cert 1"],
      "tools_and_equipment": ["Hammer"],
      "work_preferences": ["Residential"],
      "experience": "5 years",
      "city": "NY",
      "preferred_languages": ["English"],
      "years_experience": 5,
      "primary_occupation": "Plumber",
      "licences": ["Lic 1"],
      "own_tools": true,
      "has_vehicle": true,
      "willing_to_travel": true,
      "service_radius_km": 50,
      "available_now": true,
      "accepts_full_time": true,
      "accepts_part_time": true,
      "accepts_emergency": true,
      "accepts_weekends": true,
      "accepts_remote": false,
      "accepts_onsite": true,
      "bm_concierge": false,
      "bm_build_team": false,
      "bm_emergency": false,
      "can_supervise": true
    })
  );
  
  print('Update: ' + res.statusCode.toString());
  print('Body: ' + res.body);
}
