import time
import json
from django.http import JsonResponse


class RateLimitMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        self.requests = {}

    def __call__(self, request):
        ip = self.get_client_ip(request)
        now = time.time()
        window = 60
        max_requests = 100

        if ip not in self.requests:
            self.requests[ip] = []

        self.requests[ip] = [t for t in self.requests[ip] if now - t < window]

        if len(self.requests[ip]) >= max_requests:
            return JsonResponse({'error': 'Rate limit exceeded'}, status=429)

        self.requests[ip].append(now)
        return self.get_response(request)

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0]
        return request.META.get('REMOTE_ADDR')
