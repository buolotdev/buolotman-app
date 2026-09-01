import os

models_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\models.py'
with open(models_path, 'r', encoding='utf-8') as f:
    models_content = f.read()

if 'date_of_birth' not in models_content:
    target = "    response_time = models.CharField(max_length=50, blank=True)\n"
    replacement = target + "    date_of_birth = models.DateField(null=True, blank=True)\n    address = models.CharField(max_length=255, blank=True)\n"
    models_content = models_content.replace(target, replacement)
    
    with open(models_path, 'w', encoding='utf-8') as f:
        f.write(models_content)
    print("models.py updated")
else:
    print("models.py already updated")

serializers_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\serializers.py'
with open(serializers_path, 'r', encoding='utf-8') as f:
    serializers_content = f.read()

if 'date_of_birth' not in serializers_content:
    target = "            data['bio'] = profile.bio"
    replacement = "            data['date_of_birth'] = profile.date_of_birth\n            data['address'] = profile.address\n" + target
    serializers_content = serializers_content.replace(target, replacement)
    
    with open(serializers_path, 'w', encoding='utf-8') as f:
        f.write(serializers_content)
    print("serializers.py updated")
else:
    print("serializers.py already updated")
