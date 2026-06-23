"""
Rate-limit decorators using DRF's ScopedRateThrottle.
"""
from rest_framework.decorators import throttle_classes
from rest_framework.throttling import ScopedRateThrottle


class AuthLoginThrottle(ScopedRateThrottle):
    scope = "auth_login"


class AuthRegisterThrottle(ScopedRateThrottle):
    scope = "auth_register"


class UploadThrottle(ScopedRateThrottle):
    scope = "upload"


class OtpThrottle(ScopedRateThrottle):
    scope = "auth_otp"


def rate_limit_auth_login(view_func):
    return throttle_classes([AuthLoginThrottle])(view_func)


def rate_limit_auth_register(view_func):
    return throttle_classes([AuthRegisterThrottle])(view_func)


def rate_limit_upload(view_func):
    return throttle_classes([UploadThrottle])(view_func)


def rate_limit_otp(view_func):
    return throttle_classes([OtpThrottle])(view_func)
