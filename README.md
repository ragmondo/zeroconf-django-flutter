# mDNS Service Discovery POC - Django Server & Flutter iOS/macOS App

A minimal proof of concept demonstrating mDNS/Bonjour service discovery between a Django server and Flutter applications on iOS and macOS.

## Architecture

- **Django Server**: Advertises itself using Zeroconf (python-zeroconf library)
- **Flutter iOS/macOS App**: Discovers the Django server using Bonsoir package (native Bonjour/mDNS)

## Library Versions (Proven Working)

### Django Server
- Django==5.0.6
- zeroconf==0.147.2 (latest as of 2025)
- djangorestframework==3.15.2

### Flutter iOS/macOS App
- Flutter SDK: >=3.0.0 <4.0.0
- bonsoir: ^5.1.11 (cross-platform mDNS, uses native iOS Bonjour)
- http: ^1.2.0

## Setup Instructions

### Django Server Setup

1. Navigate to the Django server directory:
```bash
cd mdns-poc/django-server
```

2. Create a Python virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On macOS/Linux
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run migrations:
```bash
python manage.py migrate
```

5. Start the Django server:
```bash
python manage.py runserver 0.0.0.0:8000
```

You should see:
```
✅ mDNS service registered: Django API Server on [your-hostname] on [IP]:8000
   Service type: _django-api._tcp.local.
```

### Flutter iOS/macOS App Setup

1. Navigate to the Flutter app directory:
```bash
cd mdns-poc/flutter-app
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Platform-specific setup:

**For iOS:**
- Ensure you have Xcode installed and configured
- Run on iOS simulator or device:
```bash
flutter run -d ios
```

**For macOS:**
- Ensure you have Xcode installed
- Run on macOS:
```bash
flutter run -d macos
```

To list available devices:
```bash
flutter devices
```

## How It Works

### Django Server

The Django server automatically registers an mDNS service when it starts:

- **Service Type**: `_django-api._tcp.local.`
- **Port**: 8000
- **Properties**: Includes API version, endpoints, and description
- **Registration**: Happens automatically in `api/apps.py` when Django starts

API Endpoints:
- `/api/info/` - Server information
- `/api/health/` - Health check
- `/api/echo/` - Echo test endpoint

### Flutter iOS/macOS App

The app uses Bonsoir package which leverages native Bonjour framework on both iOS and macOS:

1. Tap "Start Discovery" to begin scanning for `_django-api._tcp` services
2. Discovered services appear in the list with host and port information
3. Tap "Test" to make an HTTP request to the discovered server
4. Server response is displayed below

### Platform-Specific Configuration

**iOS** (`ios/Runner/Info.plist`):
- **NSBonjourServices**: Declares the service types the app will browse
- **NSLocalNetworkUsageDescription**: User-facing description for local network access

**macOS** (`macos/Runner/Info.plist` and entitlements files):
- **NSBonjourServices**: Declares the service types the app will browse
- **NSLocalNetworkUsageDescription**: User-facing description for local network access
- **com.apple.security.network.client**: Network client entitlement for sandboxed macOS apps

## Testing on iOS/macOS

### iOS Simulator
The iOS simulator should work immediately if the Django server is running on the same machine.

### macOS
The macOS app should discover the Django server running on the same machine or on the same network immediately.

### Physical iOS Device
For testing on a physical iOS device:
1. Ensure both the Django server machine and iOS device are on the same WiFi network
2. The Django server must be accessible from the network (firewall configured)
3. Run Django with `0.0.0.0:8000` to bind to all network interfaces

## Troubleshooting

### Server Not Discovered
- Verify both devices are on the same network
- Check firewall settings allow mDNS (port 5353) and HTTP (port 8000)
- On macOS, ensure the Django server shows in the Network browser
- Restart the discovery after a few seconds if needed

### Connection Failed After Discovery
- Verify the Django server is running on `0.0.0.0:8000` not `127.0.0.1:8000`
- Check the discovered IP address is correct
- Test direct HTTP connection: `curl http://[IP]:8000/api/info/`

## Technical Notes

### Why These Libraries?

**python-zeroconf (0.147.2)**:
- Pure Python implementation, no external dependencies
- Actively maintained (latest update Sept 2025)
- Compatible with Apple Bonjour and Avahi

**Bonsoir Flutter Package**:
- Uses native platform APIs (Bonjour on iOS and macOS)
- Better reliability than pure Dart implementations
- Handles iOS 14+ local network privacy requirements
- Works seamlessly on macOS with proper entitlements
- Active maintenance and good documentation

### mDNS Service Type

Using `_django-api._tcp` as the service type:
- Follows mDNS naming conventions
- Unique enough to avoid conflicts
- TCP indicates HTTP REST API service

## References

- [python-zeroconf documentation](https://python-zeroconf.readthedocs.io/)
- [Bonsoir package](https://pub.dev/packages/bonsoir)
- [Apple Bonjour Overview](https://developer.apple.com/bonjour/)