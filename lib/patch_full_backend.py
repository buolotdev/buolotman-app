import os

# 1. Update models.py
models_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\models.py'
with open(models_path, 'r', encoding='utf-8') as f:
    models_content = f.read()

new_fields = """
    years_experience = models.PositiveIntegerField(default=0)
    primary_occupation = models.CharField(max_length=255, blank=True)
    certifications = models.JSONField(default=list, blank=True)
    licences = models.JSONField(default=list, blank=True)
    education_level = models.CharField(max_length=255, blank=True)
    expertise_level = models.CharField(max_length=255, blank=True)
    business_type = models.CharField(max_length=255, blank=True)
    daily_rate = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    fixed_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    inspection_fee = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    starting_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    own_tools = models.BooleanField(default=False)
    has_vehicle = models.BooleanField(default=False)
    has_ppe = models.BooleanField(default=False)
    has_specialist_machinery = models.BooleanField(default=False)
    has_driving_licence = models.BooleanField(default=False)
    can_transport_equipment = models.BooleanField(default=False)
    willing_to_travel = models.BooleanField(default=False)
    service_radius_km = models.PositiveIntegerField(default=0)
    available_now = models.BooleanField(default=False)
    accepts_full_time = models.BooleanField(default=False)
    accepts_part_time = models.BooleanField(default=True)
    accepts_emergency = models.BooleanField(default=False)
    accepts_weekends = models.BooleanField(default=False)
    accepts_remote = models.BooleanField(default=False)
    accepts_onsite = models.BooleanField(default=True)
    bm_concierge = models.BooleanField(default=False)
    bm_build_team = models.BooleanField(default=False)
    bm_emergency = models.BooleanField(default=False)
    bm_contractor_projects = models.BooleanField(default=False)
    can_supervise = models.BooleanField(default=False)
    team_leader_experience = models.BooleanField(default=False)
    project_management_experience = models.BooleanField(default=False)
    interested_in_long_term_placement = models.BooleanField(default=False)
    national_id_number = models.CharField(max_length=255, blank=True)
    national_id_front = models.URLField(max_length=500, blank=True)
    national_id_back = models.URLField(max_length=500, blank=True)
    selfie_url = models.URLField(max_length=500, blank=True)
    emergency_contact_name = models.CharField(max_length=255, blank=True)
    emergency_contact_phone = models.CharField(max_length=50, blank=True)
    preferred_payout_method = models.CharField(max_length=50, blank=True)
    bank_account_name = models.CharField(max_length=255, blank=True)
    bank_account_number = models.CharField(max_length=255, blank=True)
    bank_name = models.CharField(max_length=255, blank=True)
    mobile_money_number = models.CharField(max_length=50, blank=True)
    payout_currency = models.CharField(max_length=10, blank=True)
    payment_verification_status = models.CharField(max_length=50, default='Unverified')
    tools_and_equipment = models.JSONField(default=list, blank=True)
    work_preferences = models.JSONField(default=list, blank=True)
    preferred_working_days = models.JSONField(default=list, blank=True)
    preferred_working_hours = models.CharField(max_length=255, blank=True)
"""

if 'years_experience' not in models_content:
    target = "    address = models.CharField(max_length=255, blank=True)\n"
    models_content = models_content.replace(target, target + new_fields)
    with open(models_path, 'w', encoding='utf-8') as f:
        f.write(models_content)
    print("models.py updated with all 50+ fields")

# 2. Update views.py
views_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\views.py'
with open(views_path, 'r', encoding='utf-8') as f:
    views_content = f.read()

new_fields_list = "['bio', 'hourly_rate', 'availability_status', 'date_of_birth', 'address', 'years_experience', 'primary_occupation', 'certifications', 'licences', 'education_level', 'expertise_level', 'business_type', 'daily_rate', 'fixed_price', 'inspection_fee', 'starting_price', 'own_tools', 'has_vehicle', 'has_ppe', 'has_specialist_machinery', 'has_driving_licence', 'can_transport_equipment', 'willing_to_travel', 'service_radius_km', 'available_now', 'accepts_full_time', 'accepts_part_time', 'accepts_emergency', 'accepts_weekends', 'accepts_remote', 'accepts_onsite', 'bm_concierge', 'bm_build_team', 'bm_emergency', 'bm_contractor_projects', 'can_supervise', 'team_leader_experience', 'project_management_experience', 'interested_in_long_term_placement', 'national_id_number', 'national_id_front', 'national_id_back', 'selfie_url', 'emergency_contact_name', 'emergency_contact_phone', 'preferred_payout_method', 'bank_account_name', 'bank_account_number', 'bank_name', 'mobile_money_number', 'payout_currency', 'payment_verification_status', 'tools_and_equipment', 'work_preferences', 'preferred_working_days', 'preferred_working_hours', 'city']"
target_views = "fields = ['bio', 'hourly_rate', 'availability_status', 'date_of_birth', 'address']"

if target_views in views_content:
    views_content = views_content.replace(target_views, "fields = " + new_fields_list)
    with open(views_path, 'w', encoding='utf-8') as f:
        f.write(views_content)
    print("views.py updated to accept all fields")

# 3. Update serializers.py
serializers_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\serializers.py'
with open(serializers_path, 'r', encoding='utf-8') as f:
    serializers_content = f.read()

dict_additions = """
                'years_experience': profile.years_experience,
                'primary_occupation': profile.primary_occupation,
                'certifications': profile.certifications,
                'licences': profile.licences,
                'education_level': profile.education_level,
                'expertise_level': profile.expertise_level,
                'business_type': profile.business_type,
                'daily_rate': str(profile.daily_rate) if profile.daily_rate else None,
                'fixed_price': str(profile.fixed_price) if profile.fixed_price else None,
                'inspection_fee': str(profile.inspection_fee) if profile.inspection_fee else None,
                'starting_price': str(profile.starting_price) if profile.starting_price else None,
                'own_tools': profile.own_tools,
                'has_vehicle': profile.has_vehicle,
                'has_ppe': profile.has_ppe,
                'has_specialist_machinery': profile.has_specialist_machinery,
                'has_driving_licence': profile.has_driving_licence,
                'can_transport_equipment': profile.can_transport_equipment,
                'willing_to_travel': profile.willing_to_travel,
                'service_radius_km': profile.service_radius_km,
                'available_now': profile.available_now,
                'accepts_full_time': profile.accepts_full_time,
                'accepts_part_time': profile.accepts_part_time,
                'accepts_emergency': profile.accepts_emergency,
                'accepts_weekends': profile.accepts_weekends,
                'accepts_remote': profile.accepts_remote,
                'accepts_onsite': profile.accepts_onsite,
                'bm_concierge': profile.bm_concierge,
                'bm_build_team': profile.bm_build_team,
                'bm_emergency': profile.bm_emergency,
                'bm_contractor_projects': profile.bm_contractor_projects,
                'can_supervise': profile.can_supervise,
                'team_leader_experience': profile.team_leader_experience,
                'project_management_experience': profile.project_management_experience,
                'interested_in_long_term_placement': profile.interested_in_long_term_placement,
                'national_id_number': profile.national_id_number,
                'national_id_front': profile.national_id_front,
                'national_id_back': profile.national_id_back,
                'selfie_url': profile.selfie_url,
                'emergency_contact_name': profile.emergency_contact_name,
                'emergency_contact_phone': profile.emergency_contact_phone,
                'preferred_payout_method': profile.preferred_payout_method,
                'bank_account_name': profile.bank_account_name,
                'bank_account_number': profile.bank_account_number,
                'bank_name': profile.bank_name,
                'mobile_money_number': profile.mobile_money_number,
                'payout_currency': profile.payout_currency,
                'payment_verification_status': profile.payment_verification_status,
                'tools_and_equipment': profile.tools_and_equipment,
                'work_preferences': profile.work_preferences,
                'preferred_working_days': profile.preferred_working_days,
                'preferred_working_hours': profile.preferred_working_hours,
"""

target_ser = "'address': profile.address,"
if target_ser in serializers_content and 'years_experience' not in serializers_content:
    serializers_content = serializers_content.replace(target_ser, target_ser + dict_additions)
    with open(serializers_path, 'w', encoding='utf-8') as f:
        f.write(serializers_content)
    print("serializers.py updated to return all fields")
