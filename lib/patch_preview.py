import os

settings_path = r'c:\Users\Haram\Desktop\buolot-man-app\lib\technician_profile_settings_screen.dart'
with open(settings_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = "iconTheme: const IconThemeData(color: Color(0xFF001F3F)),"

replacement = """iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
          actions: [
            TextButton.icon(
              onPressed: () {
                Get.to(() => public_profile.PublicTechnicianProfileScreen(
                  technicianData: Get.find<AppState>().technicianProfile ?? {},
                ));
              },
              icon: const Icon(Icons.remove_red_eye, color: Color(0xFFFF4500), size: 18),
              label: const Text('Preview', style: TextStyle(color: Color(0xFFFF4500), fontWeight: FontWeight.bold)),
            ),
          ],"""

if 'import \'public_technician_profile_screen.dart\' as public_profile;' not in content:
    content = "import 'public_technician_profile_screen.dart' as public_profile;\n" + content
    
if 'TextButton.icon(' not in content and target in content:
    content = content.replace(target, replacement)
    
    with open(settings_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Added Preview button to app bar")
