from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import (
    CustomTokenObtainPairSerializer,
    ClientRegistrationSerializer,
    TechnicianRegistrationSerializer,
    CompanyRegistrationSerializer,
    UserMeSerializer,
)


# ─── JWT Login ───────────────────────────────────────────────────────────────

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


# ─── REGISTER CLIENT ─────────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([AllowAny])
def register_client(request):
    serializer = ClientRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(
            {"message": "Client registered successfully."},
            status=status.HTTP_201_CREATED
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─── REGISTER TECHNICIAN ──────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([AllowAny])
def register_technician(request):
    serializer = TechnicianRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(
            {"message": "Technician registered successfully. Awaiting verification."},
            status=status.HTTP_201_CREATED
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─── REGISTER COMPANY ─────────────────────────────────────────────────────────

@api_view(['POST'])
@permission_classes([AllowAny])
def register_company(request):
    serializer = CompanyRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(
            {"message": "Company registered successfully. Awaiting verification."},
            status=status.HTTP_201_CREATED
        )
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─── ME (current user) ────────────────────────────────────────────────────────

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def me(request):
    serializer = UserMeSerializer(request.user)
    return Response(serializer.data)
