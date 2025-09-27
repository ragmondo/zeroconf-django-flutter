from django.apps import AppConfig
import socket
import logging
from zeroconf import ServiceInfo, Zeroconf

logger = logging.getLogger(__name__)

class ApiConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'api'

    def ready(self):
        import os
        # Register service regardless of RUN_MAIN for better compatibility
        # Avoid double registration in development by checking if already registered
        if not hasattr(self, 'zeroconf'):
            self.register_service()

    def register_service(self):
        try:
            port = 8000
            hostname = socket.gethostname()

            # Get actual network IP, not localhost
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                # Connect to an external address to get the actual IP
                s.connect(('8.8.8.8', 80))
                local_ip = s.getsockname()[0]
            finally:
                s.close()

            service_type = '_django-api._tcp.local.'
            service_name = f'Django API Server'
            full_service_name = f'{service_name}.{service_type}'

            properties = {
                'version': '1.0',
                'api_endpoint': '/api/',
                'framework': 'Django',
                'description': 'POC Django Server with mDNS'
            }

            info = ServiceInfo(
                service_type,
                full_service_name,
                addresses=[socket.inet_aton(local_ip)],
                port=port,
                properties=properties,
                server=f'{hostname}.local.'
            )

            self.zeroconf = Zeroconf()
            # Allow name change to handle duplicates
            self.zeroconf.register_service(info, allow_name_change=True)
            self.service_info = info

            logger.info(f"mDNS service registered: {service_name} on {local_ip}:{port}")
            print(f"✅ mDNS service registered: {service_name} on {local_ip}:{port}")
            print(f"   Service type: {service_type}")

        except Exception as e:
            import traceback
            logger.error(f"Failed to register mDNS service: {e}")
            print(f"❌ Failed to register mDNS service: {e}")
            print(f"   Error type: {type(e).__name__}")
            print(f"   Traceback:\n{traceback.format_exc()}")