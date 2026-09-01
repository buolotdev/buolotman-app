import 'package:http/http.dart' as http; void main() async { final res = await http.get(Uri.parse('https://buolot-man-backend.onrender.com/api/tasks/')); print('TASKS: ' + res.body); }
