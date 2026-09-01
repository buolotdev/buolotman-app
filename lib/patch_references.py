import os

# 1. Update models.py
models_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\models.py'
with open(models_path, 'r', encoding='utf-8') as f:
    models_content = f.read()

new_models_fields = """
    identity_verified = models.BooleanField(default=False)
    professional_verified = models.BooleanField(default=False)
    boulotman_verified = models.BooleanField(default=False)

    @property
    def verification_badge(self):
        if self.boulotman_verified:
            return "Boulot Man Verified Professional"
        if self.professional_verified:
            return "Professional Verified"
        if self.identity_verified:
            return "Identity Verified"
        return "Unverified"
"""

new_reference_model = """
class TechnicianReference(models.Model):
    technician = models.ForeignKey(User, on_delete=models.CASCADE, related_name='technician_references')
    reference_name = models.CharField(max_length=255)
    relationship = models.CharField(max_length=255)
    contact_information = models.CharField(max_length=255)
    company_reference = models.CharField(max_length=255, blank=True)
    recommendation_document = models.URLField(max_length=500, blank=True)
    is_verified_by_platform = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
"""

if 'identity_verified = models.BooleanField' not in models_content:
    # Inject fields into TechnicianProfile
    target_prof = "    years_experience = models.PositiveIntegerField(default=0)"
    models_content = models_content.replace(target_prof, new_models_fields.strip('\n') + "\n    " + target_prof.strip())
    
    # Inject TechnicianReference model at the end
    models_content += "\n" + new_reference_model
    
    with open(models_path, 'w', encoding='utf-8') as f:
        f.write(models_content)
    print("models.py updated with references and badges")


# 2. Update serializers.py
serializers_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\serializers.py'
with open(serializers_path, 'r', encoding='utf-8') as f:
    serializers_content = f.read()

reference_serializer = """
from .models import TechnicianReference

class TechnicianReferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = TechnicianReference
        fields = '__all__'
        read_only_fields = ['id', 'technician', 'is_verified_by_platform', 'created_at']
"""

badge_fields = """
                'identity_verified': profile.identity_verified,
                'professional_verified': profile.professional_verified,
                'boulotman_verified': profile.boulotman_verified,
                'verification_badge': profile.verification_badge,
"""

if 'TechnicianReferenceSerializer' not in serializers_content:
    serializers_content = reference_serializer + "\n" + serializers_content
    
    # Add badge fields to UserMeSerializer
    target_ser_field = "'address': profile.address,"
    serializers_content = serializers_content.replace(target_ser_field, target_ser_field + badge_fields)
    
    with open(serializers_path, 'w', encoding='utf-8') as f:
        f.write(serializers_content)
    print("serializers.py updated with Reference serializer and badge fields")


# 3. Update views.py
views_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\views.py'
with open(views_path, 'r', encoding='utf-8') as f:
    views_content = f.read()

reference_views = """
@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def technician_references(request):
    from .models import TechnicianReference
    from .serializers import TechnicianReferenceSerializer
    if request.method == 'GET':
        qs = TechnicianReference.objects.filter(technician=request.user)
        return Response(TechnicianReferenceSerializer(qs, many=True).data)
    elif request.method == 'POST':
        serializer = TechnicianReferenceSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(technician=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def technician_reference_detail(request, ref_id):
    from .models import TechnicianReference
    try:
        ref = TechnicianReference.objects.get(id=ref_id, technician=request.user)
        ref.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
    except TechnicianReference.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)
"""

if 'def technician_references(' not in views_content:
    views_content += "\n" + reference_views
    with open(views_path, 'w', encoding='utf-8') as f:
        f.write(views_content)
    print("views.py updated with references endpoints")


# 4. Update urls.py
urls_path = r'c:\Users\Haram\Desktop\buolot-man\backend\apps\accounts\urls.py'
with open(urls_path, 'r', encoding='utf-8') as f:
    urls_content = f.read()

url_patterns = """
    path('references/', views.technician_references, name='technician_references'),
    path('references/<int:ref_id>/', views.technician_reference_detail, name='technician_reference_detail'),
"""

if 'references/' not in urls_content:
    target_url = "path('me/', views.me, name='me'),"
    urls_content = urls_content.replace(target_url, target_url + url_patterns)
    with open(urls_path, 'w', encoding='utf-8') as f:
        f.write(urls_content)
    print("urls.py updated with references routes")

