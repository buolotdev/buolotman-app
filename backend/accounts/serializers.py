from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from .models import TechnicianProfile, CompanyProfile

User = get_user_model()


# ─── JWT ────────────────────────────────────────────────────────────────────

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        data['role'] = self.user.role
        data['username'] = self.user.username
        data['email'] = self.user.email
        return data


# ─── CLIENT ─────────────────────────────────────────────────────────────────

class ClientRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'password']

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role='CLIENT',
        )
        return user


# ─── TECHNICIAN ──────────────────────────────────────────────────────────────

class TechnicianRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    phone_number = serializers.CharField(required=False, allow_blank=True)
    skills = serializers.CharField(required=False, allow_blank=True, help_text="Comma-separated skills")
    hourly_rate = serializers.DecimalField(max_digits=10, decimal_places=2, required=False, allow_null=True)

    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'password', 'phone_number', 'skills', 'hourly_rate']

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def create(self, validated_data):
        phone_number = validated_data.pop('phone_number', '')
        skills = validated_data.pop('skills', '')
        hourly_rate = validated_data.pop('hourly_rate', None)

        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            role='TECHNICIAN',
        )

        TechnicianProfile.objects.create(
            user=user,
            phone_number=phone_number,
            skills=skills,
            hourly_rate=hourly_rate,
        )
        return user


# ─── COMPANY ─────────────────────────────────────────────────────────────────

class CompanyRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    company_name = serializers.CharField()
    registration_number = serializers.CharField(required=False, allow_blank=True)
    services_offered = serializers.CharField(required=False, allow_blank=True)
    company_size = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = ['email', 'password', 'company_name', 'registration_number', 'services_offered', 'company_size']

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def create(self, validated_data):
        company_name = validated_data.pop('company_name')
        registration_number = validated_data.pop('registration_number', '')
        services_offered = validated_data.pop('services_offered', '')
        company_size = validated_data.pop('company_size', '')

        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            role='COMPANY',
        )

        CompanyProfile.objects.create(
            user=user,
            company_name=company_name,
            registration_number=registration_number,
            services_offered=services_offered,
            company_size=company_size,
        )
        return user


# ─── ME ──────────────────────────────────────────────────────────────────────

class UserMeSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'first_name', 'last_name', 'email', 'username', 'role']
