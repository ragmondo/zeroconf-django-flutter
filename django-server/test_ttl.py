#!/usr/bin/env python3
"""
Test script to verify TTL values for mDNS service
"""
import socket
import time
from zeroconf import ServiceInfo, Zeroconf, ServiceBrowser, ServiceListener

class TestListener(ServiceListener):
    def add_service(self, zc, type_, name):
        info = zc.get_service_info(type_, name)
        if info:
            print(f"\n✅ Service found: {name}")
            print(f"   Address: {socket.inet_ntoa(info.addresses[0])}")
            print(f"   Port: {info.port}")
            print(f"   Host TTL: {info.host_ttl} seconds")
            print(f"   Other TTL: {info.other_ttl} seconds")
            print(f"   Properties: {info.properties}")

    def remove_service(self, zc, type_, name):
        print(f"\n❌ Service removed: {name}")

    def update_service(self, zc, type_, name):
        print(f"\n🔄 Service updated: {name}")

def test_ttl():
    """Test TTL values by registering and monitoring a service"""
    print("Starting TTL test...")

    # Get network IP
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        local_ip = s.getsockname()[0]
    finally:
        s.close()

    hostname = socket.gethostname()
    service_type = '_test-ttl._tcp.local.'
    service_name = 'TTL Test Service'
    full_service_name = f'{service_name}.{service_type}'

    # Create service with specific TTL values
    info = ServiceInfo(
        service_type,
        full_service_name,
        addresses=[socket.inet_aton(local_ip)],
        port=9999,
        properties={'test': 'ttl'},
        server=f'{hostname}.local.',
        host_ttl=30,   # 30 seconds for testing
        other_ttl=30   # 30 seconds for testing
    )

    zeroconf = Zeroconf()

    # Register the service
    print(f"\n📡 Registering service with TTL=30 seconds...")
    zeroconf.register_service(info)
    print(f"✅ Service registered: {service_name}")

    # Start browsing for the service
    listener = TestListener()
    browser = ServiceBrowser(zeroconf, service_type, listener)

    print("\n⏰ Service should disappear in ~30 seconds if no refresh...")
    print("   Press Ctrl+C to send goodbye packet and exit\n")

    try:
        # Wait and let the service expire
        time.sleep(45)
        print("\n⚠️ If service is still visible, TTL might not be working correctly")
    except KeyboardInterrupt:
        print("\n\n🛑 Sending goodbye packet...")
    finally:
        # Unregister the service (sends goodbye packet)
        zeroconf.unregister_service(info)
        zeroconf.close()
        print("✅ Service unregistered and cleaned up")

if __name__ == "__main__":
    test_ttl()