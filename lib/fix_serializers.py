import os

serializers_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\serializers.py'
with open(serializers_path, 'r', encoding='utf-8') as f:
    serializers_content = f.read()

bad_string = """
from .models import TechnicianReference

class TechnicianReferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = TechnicianReference
        fields = '__all__'
        read_only_fields = ['id', 'technician', 'is_verified_by_platform', 'created_at']
"""

if bad_string in serializers_content:
    serializers_content = serializers_content.replace(bad_string, "")
    
    target_import = "from django.contrib.auth.password_validation import validate_password\n"
    if target_import in serializers_content:
        serializers_content = serializers_content.replace(target_import, target_import + "\n" + bad_string.strip() + "\n")
    
    with open(serializers_path, 'w', encoding='utf-8') as f:
        f.write(serializers_content)
    print("Fixed serializers.py")
