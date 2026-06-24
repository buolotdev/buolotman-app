#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""

import os
import sys


def main() -> None:
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings.dev")
    
    # Avoid slow reverse DNS lookups on local/LAN development requests
    try:
        from django.core.servers.basehttp import WSGIRequestHandler
        WSGIRequestHandler.address_string = lambda self: self.client_address[0]
    except ImportError:
        pass

    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
