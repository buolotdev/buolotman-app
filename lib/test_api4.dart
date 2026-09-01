import 'package:http/http.dart' as http;
void main() async {
  try {
    final res = await http.get(Uri.parse('https://boulotman-api.onrender.com/api/tasks/'));
    print('API TASKS: ' + res.body);
  } catch(e) {
    print('Error: $e');
  }
}
