import os

settings_path = r'c:\Users\Haram\Desktop\buolot-man-app\lib\technician_profile_settings_screen.dart'
with open(settings_path, 'r', encoding='utf-8') as f:
    content = f.read()

target1 = "'identity_verified': Get.find<AppState>().currentUser.identityVerified ?? false,"
replacement1 = "'identity_verified': Get.find<AppState>().currentUser.verificationBadge.contains('Identity') || Get.find<AppState>().currentUser.verificationBadge.contains('Boulot Man'),"

target2 = "'professional_verified': Get.find<AppState>().currentUser.professionalVerified ?? false,"
replacement2 = "'professional_verified': Get.find<AppState>().currentUser.verificationBadge.contains('Professional') || Get.find<AppState>().currentUser.verificationBadge.contains('Boulot Man'),"

target3 = "'boulotman_verified': Get.find<AppState>().currentUser.boulotmanVerified ?? false,"
replacement3 = "'boulotman_verified': Get.find<AppState>().currentUser.verificationBadge.contains('Boulot Man'),"

if target1 in content:
    content = content.replace(target1, replacement1)
    content = content.replace(target2, replacement2)
    content = content.replace(target3, replacement3)
    
    with open(settings_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed compilation errors in technician_profile_settings_screen.dart")
else:
    print("Could not find targets")
