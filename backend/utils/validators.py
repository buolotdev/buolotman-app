import re


def validate_phone(phone):
    pattern = re.compile(r'^\+?[\d\s-]{6,20}$')
    return bool(pattern.match(phone))


def validate_email(email):
    pattern = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
    return bool(pattern.match(email))


def sanitize_input(text):
    if not text:
        return text
    text = text.strip()
    text = re.sub(r'<[^>]+>', '', text)
    return text
