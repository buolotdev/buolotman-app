import random
import string
import logging

logger = logging.getLogger(__name__)


def generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))


def send_otp(phone, otp):
    logger.info("OTP for %s: %s", phone, otp)
    return True
