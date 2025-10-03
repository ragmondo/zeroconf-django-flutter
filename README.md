# mDNS Service Discovery POC - Django Server & Flutter iOS/macOS App

A minimal proof of concept demonstrating mDNS/Bonjour service discovery between a Django server and Flutter applications on iOS and macOS.

## Architecture

- **Django Server**: Advertises itself using Zeroconf (python-zeroconf library) with TTL management and proper cleanup
- **Flutter iOS/macOS App**: Discovers the Django server using Bonsoir package (native Bonjour/mDNS)

## Features

- Automatic mDNS service registration with customizable TTL values
- Proper service cleanup on shutdown (goodbye packets)
- Cross-platform Flutter app (iOS and macOS)
- Minimal dependencies and clean architecture
- Ghost service cleanup utilities

## Requirements

### Django Server
- Python 3.8+
- Django==5.0.6
- zeroconf==0.147.2

### Flutter App
- Flutter SDK: >=3.0.0 <4.0.0
- bonsoir: ^5.1.11 (cross-platform mDNS, uses native iOS Bonjour)
- http: ^1.2.0
- iOS 13.0+ (required by bonsoir_darwin)

## Quick Start

### 1. Django Server

```bash
cd django-server
python3 -m venv venv
source venv/bin/activate  # On macOS/Linux
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

You should see:
```
✅ mDNS service registered: Django API Server on [IP]:8000
   Service type: _django-api._tcp.local.
```

### 2. Flutter App

```bash
cd flutter-app
flutter pub get

# For iOS Simulator
flutter run -d "iPhone"

# For physical iOS device
flutter run -d "Your Device Name"

# For macOS
flutter run -d macos
```

## How It Works

### Service Discovery Flow

1. Django server starts and automatically registers mDNS service with 120-second TTL
2. Service advertises on `_django-api._tcp.local.` with properties
3. Flutter app discovers services when "Start Discovery" is tapped
4. App resolves service details and displays host:port
5. "Test" button sends HTTP request to verify connectivity

### API Endpoints

- `GET /api/` - Returns server information and current time

### mDNS TTL Configuration

The Django server sets explicit TTL values:
- **Host TTL**: 120 seconds (A/AAAA records)
- **Other TTL**: 120 seconds (SRV/TXT records)

Services expire automatically if not refreshed within the TTL period.

## Platform Configuration

### iOS Requirements

**Info.plist** (`ios/Runner/Info.plist`):
```xml
<key>NSBonjourServices</key>
<array>
    <string>_django-api._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs local network access to discover Django servers</string>
```

**Minimum iOS Version**: 13.0 (set in `ios/Podfile`)

**Code Signing**: Automatic signing enabled in Xcode project

### macOS Requirements

**Entitlements** (`macos/Runner/*.entitlements`):
```xml
<key>com.apple.security.network.client</key>
<true/>
```

Plus same Info.plist entries as iOS.

## Utilities

### Clean Ghost Services

If you see lingering "ghost" services after server shutdown:

```bash
cd django-server
source venv/bin/activate
python cleanup_mdns.py
```

This sends goodbye packets for all Django API Server instances.

### Test TTL Behavior

```bash
cd django-server
source venv/bin/activate
python test_ttl.py
```

Creates a test service with 30-second TTL to verify expiration.

## Troubleshooting

### iOS Build Issues

**Provisioning Profile Error**:
```bash
# Add automatic provisioning to Xcode project
open flutter-app/ios/Runner.xcworkspace
# Select team in Signing & Capabilities
```

**Minimum iOS Version Error**:
- Already fixed: Podfile sets `platform :ios, '13.0'`

### Service Discovery Issues

**Services Not Found**:
1. Verify same network: `ping [server-ip]`
2. Check mDNS: `dns-sd -B _django-api._tcp`
3. Verify firewall allows port 5353 (mDNS) and 8000 (HTTP)

**Ghost Services**:
- Run `cleanup_mdns.py` to send goodbye packets
- Services expire after 2 minutes (120s TTL)

**Multiple Service Instances**:
- Kill all Django processes: `pkill -f "manage.py runserver"`
- Run cleanup script to remove registrations

### Network Issues

**Django Must Bind to All Interfaces**:
```bash
# Correct - accessible from network
python manage.py runserver 0.0.0.0:8000

# Wrong - only localhost
python manage.py runserver  # defaults to 127.0.0.1
```

## Technical Details

### Service Cleanup

The Django server implements proper cleanup:
- Signal handlers for SIGTERM and SIGINT
- atexit registration for cleanup
- Sends goodbye packets (TTL=0) on shutdown

### IP Detection

Server detects actual network IP (not localhost):
```python
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(('8.8.8.8', 80))
local_ip = s.getsockname()[0]
```

### Service Resolution

Flutter app performs two-step discovery:
1. Find service via browse
2. Resolve details before use

## Files Structure

```
mdns-poc/
├── django-server/
│   ├── api/
│   │   ├── apps.py          # mDNS registration with TTL
│   │   └── views.py         # Minimal API endpoint
│   ├── cleanup_mdns.py      # Ghost service cleanup
│   ├── test_ttl.py          # TTL testing utility
│   └── requirements.txt
├── flutter-app/
│   ├── lib/
│   │   └── main.dart        # Minimal discovery UI
│   ├── ios/
│   │   ├── Runner/Info.plist
│   │   └── Podfile          # iOS 13.0 minimum
│   └── pubspec.yaml
└── README.md
```

## Recent Updates

- Added explicit TTL configuration (120 seconds)
- Implemented proper service cleanup with goodbye packets
- Added cleanup utilities for ghost services
- Fixed iOS automatic code signing
- Set minimum iOS version to 13.0 for bonsoir compatibility
- Minimized codebase (~54% reduction)

## References

- [python-zeroconf documentation](https://python-zeroconf.readthedocs.io/)
- [Bonsoir package](https://pub.dev/packages/bonsoir)
- [Apple Bonjour Overview](https://developer.apple.com/bonjour/)
- [mDNS RFC 6762](https://tools.ietf.org/html/rfc6762)