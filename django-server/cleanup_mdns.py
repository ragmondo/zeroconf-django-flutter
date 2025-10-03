#!/usr/bin/env python3
"""
Cleanup ghost mDNS services by sending goodbye packets (TTL=0)
"""
import socket
from zeroconf import ServiceInfo, Zeroconf
import time

def cleanup_ghost_services():
    """Send goodbye packets for all Django API Server instances"""

    # Get network IP
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        local_ip = s.getsockname()[0]
    finally:
        s.close()

    hostname = socket.gethostname()
    service_type = '_django-api._tcp.local.'

    # Service names that might be registered
    service_names = [
        'Django API Server',
        'Django API Server-2',
        'Django API Server-3',
        'Django API Server-4'
    ]

    zeroconf = Zeroconf()

    for service_name in service_names:
        print(f"Sending goodbye packet for: {service_name}")
        full_service_name = f'{service_name}.{service_type}'

        # Create service info with TTL=0 to send goodbye packet
        info = ServiceInfo(
            service_type,
            full_service_name,
            addresses=[socket.inet_aton(local_ip)],
            port=8000,
            properties={},
            server=f'{hostname}.local.'
        )

        try:
            # First register the service (in case it wasn't properly tracked)
            zeroconf.register_service(info, allow_name_change=False, ttl=120)
            time.sleep(0.5)

            # Now unregister it properly, which sends goodbye packet
            zeroconf.unregister_service(info)
            print(f"  ✅ Goodbye packet sent for {service_name}")

        except Exception as e:
            print(f"  ⚠️ Could not cleanup {service_name}: {e}")

    # Also flush the mDNS cache on macOS
    print("\nFlushing mDNS cache...")
    import subprocess
    try:
        subprocess.run(['sudo', 'dscacheutil', '-flushcache'], check=True)
        print("✅ mDNS cache flushed")
    except:
        print("⚠️ Could not flush cache (may need sudo)")

    zeroconf.close()
    print("\n✅ Cleanup complete")

if __name__ == "__main__":
    cleanup_ghost_services()