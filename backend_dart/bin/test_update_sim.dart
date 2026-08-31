import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';
import 'dart:convert';

void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbUrl = env['DATABASE_URL'];
  final uri = Uri.parse(dbUrl!);
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
  
  final body = <String, dynamic>{
    'first_name': 'Haram',
    'last_name': 'Test',
    'tagline': 'I am a pro',
    'phone': '1234567',
    'country': 'Nigeria',
    'bio': 'My bio',
    'hourly_rate': 100.0,
    'starting_price': 50.0,
    'skills': ['Plumbing'],
    'work_preferences': ['Onsite'],
    'own_tools': true,
  };

  try {
    var userId = 1; // Assuming a user exists
    
    // User update
    final allowedUserFields = ['first_name', 'last_name', 'phone', 'avatar_url', 'language_preference', 'country', 'address', 'date_of_birth', 'education_level', 'expertise_level'];
    final userUpdates = <String, dynamic>{};
    for (final f in allowedUserFields) {
      if (body.containsKey(f)) userUpdates[f] = body[f];
    }
    
    print('USER UPDATES: $userUpdates');
    
    if (userUpdates.isNotEmpty) {
      final queryParts = userUpdates.keys.map((k) => '$k = @$k').join(', ');
      final params = Map<String, dynamic>.from(userUpdates)..['id'] = userId;
      print('USER QUERY: UPDATE accounts_user SET $queryParts, updated_at = NOW() WHERE id = @id');
      await connection.execute(
        Sql.named('UPDATE accounts_user SET $queryParts, updated_at = NOW() WHERE id = @id'),
        parameters: params,
      );
    }
    
    // Profile Update
    final allowedProfileFields = [
      'bio', 'hourly_rate', 'availability_status', 'certifications', 'experience', 
      'daily_rate', 'fixed_price', 'inspection_fee', 'starting_price', 'work_preferences', 
      'tools_and_equipment', 'licences', 'years_experience', 'primary_occupation', 
      'city', 'preferred_languages', 'national_id_front', 'national_id_back', 'selfie_url', 'national_id_number',
      'own_tools', 'has_vehicle', 'willing_to_travel', 'service_radius_km',
      'available_now', 'accepts_full_time', 'accepts_part_time', 'accepts_emergency',
      'accepts_weekends', 'accepts_remote', 'accepts_onsite',
      'bm_concierge', 'bm_build_team', 'bm_emergency', 'can_supervise', 'tagline'
    ];
    final profileUpdates = <String, dynamic>{};
    for (final f in allowedProfileFields) {
      if (body.containsKey(f)) {
        if (f == 'hourly_rate' || f == 'daily_rate' || f == 'fixed_price' || f == 'inspection_fee' || f == 'starting_price') {
          profileUpdates[f] = double.tryParse(body[f].toString()) ?? 0.0;
        } else if (f == 'years_experience' || f == 'service_radius_km') {
          profileUpdates[f] = int.tryParse(body[f].toString()) ?? 0;
        } else if (f == 'certifications' || f == 'work_preferences' || f == 'tools_and_equipment' || f == 'licences' || f == 'preferred_languages') {
          profileUpdates[f] = jsonEncode(body[f]);
        } else if (f == 'own_tools' || f == 'has_vehicle' || f == 'willing_to_travel' || f == 'available_now' ||
                   f == 'accepts_full_time' || f == 'accepts_part_time' || f == 'accepts_emergency' || 
                   f == 'accepts_weekends' || f == 'accepts_remote' || f == 'accepts_onsite' ||
                   f == 'bm_concierge' || f == 'bm_build_team' || f == 'bm_emergency' || f == 'can_supervise') {
          profileUpdates[f] = body[f] == true || body[f] == 'true';
        } else {
          profileUpdates[f] = body[f];
        }
      }
    }
    
    print('PROFILE UPDATES: $profileUpdates');
    
    if (profileUpdates.isNotEmpty) {
      final queryParts = profileUpdates.keys.map((k) => '$k = @$k').join(', ');
      final params = Map<String, dynamic>.from(profileUpdates)..['userId'] = userId;
      print('PROFILE QUERY: UPDATE accounts_technician_profile SET $queryParts WHERE user_id = @userId');
      await connection.execute(
        Sql.named('UPDATE accounts_technician_profile SET $queryParts WHERE user_id = @userId'),
        parameters: params,
      );
    }
    
    // Handle skills update if passed
    if (body.containsKey('skills')) {
      final skillsList = body['skills'] as List? ?? [];
      
      final profRes = await connection.execute(
        Sql.named('SELECT id FROM accounts_technician_profile WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      if (profRes.isNotEmpty) {
        final profId = profRes[0][0] as int;
        
        await connection.execute(
          Sql.named('DELETE FROM accounts_technician_profile_skills WHERE technicianprofile_id = @profId'),
          parameters: {'profId': profId},
        );
        
        for (final skName in skillsList) {
          final skStr = skName.toString().trim();
          if (skStr.isEmpty) continue;
          
          var skRes = await connection.execute(
            Sql.named('SELECT id FROM tasks_skill WHERE LOWER(name) = LOWER(@name)'),
            parameters: {'name': skStr},
          );
          int skId;
          if (skRes.isEmpty) {
            final slug = skStr.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
            final insertRes = await connection.execute(
              Sql.named('INSERT INTO tasks_skill (name, slug) VALUES (@name, @slug) RETURNING id'),
              parameters: {'name': skStr, 'slug': slug},
            );
            skId = insertRes[0][0] as int;
          } else {
            skId = skRes[0][0] as int;
          }
          
          await connection.execute(
            Sql.named('INSERT INTO accounts_technician_profile_skills (technicianprofile_id, skill_id) VALUES (@profId, @skId)'),
            parameters: {'profId': profId, 'skId': skId},
          );
        }
      }
    }

    final updatedUser = await connection.execute(Sql.named('SELECT * FROM accounts_user WHERE id = @id'), parameters: {'id': userId});
    final u = updatedUser[0].toColumnMap();
    final data = {
      'id': u['id'],
      'username': u['username'] ?? '',
      'first_name': u['first_name'] ?? '',
      'last_name': u['last_name'] ?? '',
      'email': u['email'] ?? '',
      'role': u['role'] ?? 'CLIENT',
      'phone': u['phone'] ?? '',
      'tagline': u['tagline'] ?? '',
    };

    if (u['role'] == 'TECHNICIAN' || true) { // Force technician logic for test
      final profileQuery = await connection.execute(
        Sql.named('SELECT * FROM accounts_technician_profile WHERE user_id = @id'),
        parameters: {'id': userId},
      );
      if (profileQuery.isNotEmpty) {
        data.addAll(profileQuery[0].toColumnMap());
      }
      
      final skillsQuery = await connection.execute(
        Sql.named('''
          SELECT s.name 
          FROM tasks_skill s
          JOIN accounts_technician_profile_skills ts ON ts.skill_id = s.id
          JOIN accounts_technician_profile p ON p.id = ts.technicianprofile_id
          WHERE p.user_id = @id
        '''),
        parameters: {'id': userId},
      );
      data['skills'] = skillsQuery.map((row) => row[0]).toList();
    }
    
    print("SUCCESS: $data");
  } catch(e, st) {
    print("FAILED: $e\n$st");
  } finally {
    await connection.close();
  }
}
