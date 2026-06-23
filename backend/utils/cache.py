"""
Caching utilities with Redis fallback to local memory.

If Redis is configured (REDIS_URL env var), uses django-redis.
Otherwise falls back to local memory cache so the app still works in dev.
"""
from django.core.cache import cache
from functools import wraps
import hashlib
import json
import logging

logger = logging.getLogger(__name__)


def make_cache_key(prefix: str, params: dict) -> str:
    raw = json.dumps(params, sort_keys=True, default=str)
    digest = hashlib.md5(raw.encode()).hexdigest()
    return f"{prefix}:{digest}"


def cached(prefix: str, ttl: int = 300):
    """Decorator to cache a view's response for `ttl` seconds.

    Falls back silently to no-cache if the cache backend errors.
    """
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(request, *args, **kwargs):
            params = {
                "GET": dict(request.GET.items()),
                "user": request.user.id if request.user.is_authenticated else None,
                "args": args,
                "kwargs": kwargs,
            }
            key = make_cache_key(prefix, params)
            try:
                hit = cache.get(key)
                if hit is not None:
                    return hit
            except Exception as exc:
                logger.warning("Cache get failed for %s: %s", key, exc)

            response = view_func(request, *args, **kwargs)

            try:
                if hasattr(response, "status_code") and 200 <= response.status_code < 300:
                    cache.set(key, response, ttl)
            except Exception as exc:
                logger.warning("Cache set failed for %s: %s", key, exc)

            return response
        return wrapper
    return decorator


def invalidate(prefix: str):
    """Invalidate all keys with the given prefix (use after writes)."""
    try:
        from django_redis import get_redis_connection
        conn = get_redis_connection("default")
        keys = list(conn.scan_iter(match=f"boulotman:1:{prefix}:*"))
        if keys:
            conn.delete(*keys)
    except Exception:
        try:
            cache.clear()
        except Exception as exc:
            logger.warning("Cache invalidate failed: %s", exc)
