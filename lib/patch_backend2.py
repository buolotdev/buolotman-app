import os

views_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\views.py'
with open(views_path, 'r', encoding='utf-8') as f:
    views_content = f.read()

target_me = """    elif request.method == 'PATCH':
        serializer = UserMeSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)"""

replacement_me = """    elif request.method == 'PATCH':
        serializer = UserMeSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            user = request.user
            if user.role == 'TECHNICIAN' and hasattr(user, 'technician_profile'):
                profile = user.technician_profile
                fields = ['bio', 'hourly_rate', 'availability_status', 'date_of_birth', 'address']
                updated = False
                for field in fields:
                    if field in request.data:
                        setattr(profile, field, request.data[field])
                        updated = True
                if updated:
                    profile.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)"""

if 'profile.save()' not in views_content:
    views_content = views_content.replace(target_me, replacement_me)
    with open(views_path, 'w', encoding='utf-8') as f:
        f.write(views_content)
    print("views.py patched")


serializers_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\serializers.py'
with open(serializers_path, 'r', encoding='utf-8') as f:
    serializers_content = f.read()

target_userme = """class UserMeSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'first_name', 'last_name', 'email', 'username', 'role', 'phone', 'avatar_url', 'is_verified', 'language_preference', 'country', 'created_at']
        read_only_fields = ['id', 'email', 'role', 'is_verified', 'created_at']"""

replacement_userme = """class UserMeSerializer(serializers.ModelSerializer):
    profile = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'first_name', 'last_name', 'email', 'username', 'role', 'phone', 'avatar_url', 'is_verified', 'language_preference', 'country', 'created_at', 'profile']
        read_only_fields = ['id', 'email', 'role', 'is_verified', 'created_at']

    def get_profile(self, obj):
        if obj.role == 'TECHNICIAN' and hasattr(obj, 'technician_profile'):
            profile = obj.technician_profile
            return {
                'bio': profile.bio,
                'hourly_rate': str(profile.hourly_rate) if profile.hourly_rate else None,
                'date_of_birth': profile.date_of_birth,
                'address': profile.address,
                'skills': [s.name for s in profile.skills.all()],
                'languages': profile.languages,
                'completed_jobs': profile.completed_jobs,
                'average_rating': str(profile.average_rating),
                'availability_status': profile.availability_status,
                'portfolio': profile.portfolio,
                'response_time': profile.response_time,
            }
        return {}"""

if 'def get_profile' not in serializers_content:
    serializers_content = serializers_content.replace(target_userme, replacement_userme)
    with open(serializers_path, 'w', encoding='utf-8') as f:
        f.write(serializers_content)
    print("serializers.py patched")

