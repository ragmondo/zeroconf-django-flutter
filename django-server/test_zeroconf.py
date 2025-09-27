#!/usr/bin/env python
import socket
import time
from zeroconf import ServiceInfo, Zeroconf

def test_zeroconf():
    try:
        port = 8000
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)

        print(f"Hostname: {hostname}")
        print(f"IP: {local_ip}")
        print(f"Port: {port}")

        service_type = '_django-api._tcp.local.'
        service_name = 'Django API Server'
        full_service_name = f'{service_name}.{service_type}'

        print(f"\nService type: {service_type}")
        print(f"Service name: {service_name}")
        print(f"Full service name: {full_service_name}")

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

        print("\nCreating Zeroconf instance...")
        zeroconf = Zeroconf()

        print("Registering service...")
        zeroconf.register_service(info)

        print(f"✅ Service registered successfully!")
        print("Service will be advertised for 30 seconds...")

        # Keep service alive for 30 seconds
        time.sleep(30)

        print("\nUnregistering service...")
        zeroconf.unregister_service(info)
        zeroconf.close()
        print("✅ Service unregistered")

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        print(f"Traceback:\n{traceback.format_exc()}")

if __name__ == "__main__":
    test_zeroconf()