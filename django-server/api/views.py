from django.http import JsonResponse
import socket

def test_endpoint(request):
    return JsonResponse({
        'status': 'online',
        'hostname': socket.gethostname(),
        'message': 'mDNS service discovered and connected!'
    })