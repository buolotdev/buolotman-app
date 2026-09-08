import os

# Fix 1: technician_profile_settings_screen.dart
settings_path = r'c:\Users\Haram\Desktop\buolot-man-app\lib\technician_profile_settings_screen.dart'
with open(settings_path, 'r', encoding='utf-8') as f:
    settings_content = f.read()

target1 = "technicianData: Get.find<AppState>().technicianProfile ?? {},"
replacement1 = """technicianData: {
                    'first_name': Get.find<AppState>().currentUser.firstName,
                    'last_name': Get.find<AppState>().currentUser.lastName,
                    'username': Get.find<AppState>().currentUser.name,
                    'avatar_url': Get.find<AppState>().currentUser.avatar,
                    'primary_occupation': Get.find<AppState>().currentUser.primaryOccupation,
                    'verification_badge': Get.find<AppState>().currentUser.verificationBadge,
                    'average_rating': '4.9',
                    'city': Get.find<AppState>().currentUser.city,
                    'identity_verified': Get.find<AppState>().currentUser.identityVerified ?? false,
                    'professional_verified': Get.find<AppState>().currentUser.professionalVerified ?? false,
                    'boulotman_verified': Get.find<AppState>().currentUser.boulotmanVerified ?? false,
                    'years_experience': Get.find<AppState>().currentUser.yearsExperience,
                    'completed_jobs': 94,
                    'bio': Get.find<AppState>().currentUser.bio,
                    'hourly_rate': Get.find<AppState>().currentUser.hourlyRate,
                    'daily_rate': Get.find<AppState>().currentUser.dailyRate,
                    'starting_price': Get.find<AppState>().currentUser.startingPrice,
                  },"""

if target1 in settings_content:
    settings_content = settings_content.replace(target1, replacement1)
    with open(settings_path, 'w', encoding='utf-8') as f:
        f.write(settings_content)
    print("Fixed technician_profile_settings_screen.dart")

# Fix 2: public_technician_profile_screen.dart
public_path = r'c:\Users\Haram\Desktop\buolot-man-app\lib\public_technician_profile_screen.dart'
with open(public_path, 'r', encoding='utf-8') as f:
    public_content = f.read()

target2 = """          const Container(
            color: Colors.white,
            height: 400, // Fixed height for demo
            child: TabBarView("""

replacement2 = """          Container(
            color: Colors.white,
            height: 400, // Fixed height for demo
            child: TabBarView("""

if target2 in public_content:
    public_content = public_content.replace(target2, replacement2)
    with open(public_path, 'w', encoding='utf-8') as f:
        f.write(public_content)
    print("Fixed public_technician_profile_screen.dart const error")

