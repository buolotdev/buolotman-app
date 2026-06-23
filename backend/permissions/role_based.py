from rest_framework.permissions import BasePermission


class IsClient(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'CLIENT'


class IsTechnician(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'TECHNICIAN'


class IsCompany(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'COMPANY'


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role == 'ADMIN'


class IsOwner(BasePermission):
    def has_object_permission(self, request, view, obj):
        if hasattr(obj, 'user'):
            return obj.user == request.user
        if hasattr(obj, 'client'):
            return obj.client == request.user
        if hasattr(obj, 'sender'):
            return obj.sender == request.user
        return False


class IsTaskClient(BasePermission):
    def has_object_permission(self, request, view, obj):
        return hasattr(obj, 'client') and obj.client == request.user


class IsConversationParticipant(BasePermission):
    def has_object_permission(self, request, view, obj):
        if hasattr(obj, 'participants'):
            return request.user in obj.participants.all()
        return False
