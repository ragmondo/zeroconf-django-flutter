from rest_framework.decorators import api_view
from rest_framework.response import Response
import socket
import platform

@api_view(['GET'])
def server_info(request):
    return Response({
        'status': 'online',
        'hostname': socket.gethostname(),
        'platform': platform.platform(),
        'python_version': platform.python_version(),
        'service': 'Django mDNS POC Server',
        'version': '1.0.0',
        'endpoints': {
            'info': '/api/info/',
            'health': '/api/health/',
            'echo': '/api/echo/'
        }
    })

@api_view(['GET'])
def health_check(request):
    return Response({
        'status': 'healthy',
        'service': 'Django mDNS POC Server'
    })

@api_view(['POST'])
def echo(request):
    return Response({
        'received': request.data,
        'echo': request.data
    })