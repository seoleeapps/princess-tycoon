"""PixelLab v2 전송. 변경 요청을 자동 재시도하지 않으며 비밀값을 오류에 싣지 않는다."""
import base64
import io
import json
import os
import urllib.error
import urllib.request

BASE = 'https://api.pixellab.ai/v2'

def token():
    value = os.environ.get('PIXELLAB_API_TOKEN', '').strip()
    if not value:
        raise RuntimeError('PIXELLAB_API_TOKEN is required')
    return value

def b64(image):
    buffer = io.BytesIO()
    image.save(buffer, format='PNG')
    return {'type':'base64', 'base64':base64.b64encode(buffer.getvalue()).decode(), 'format':'png'}

def request(path, credential, body=None):
    if not path.startswith('/') or '://' in path:
        raise ValueError('Expected a relative PixelLab endpoint')
    request_body = json.dumps(body).encode() if body is not None else None
    operation = urllib.request.Request(BASE+path, data=request_body,
        headers={'Authorization':'Bearer '+credential, 'Content-Type':'application/json'},
        method='POST' if body is not None else 'GET')
    try:
        with urllib.request.urlopen(operation, timeout=120) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        code=error.code
        error.close()
        raise RuntimeError('PixelLab HTTP '+str(code)) from None
    except urllib.error.URLError:
        raise RuntimeError('PixelLab network request failed') from None
