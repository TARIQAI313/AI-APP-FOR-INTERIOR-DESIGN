"""Read-only checks using the public client configuration. No admin key needed."""
import json
import pathlib
import urllib.error
import urllib.request

root = pathlib.Path(__file__).resolve().parents[1]
config = json.loads((root / 'config.json').read_text())
base = config['SUPABASE_URL'].rstrip('/')
key = config['SUPABASE_PUBLISHABLE_KEY']

def request(path, method='GET'):
    req = urllib.request.Request(base + path, method=method, headers={'apikey':key})
    try:
        with urllib.request.urlopen(req, timeout=20) as response:
            body = response.read().decode()
            return response.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as error:
        try:
            value = json.loads(error.read())
        except (ValueError, UnicodeDecodeError):
            value = {}
        return error.code, value

status, settings = request('/auth/v1/settings')
print('Public Auth connection:', status)
if status == 200:
    print('Email signup:', bool(settings.get('external', {}).get('email')))
    print('Email confirmation required:', not settings.get('mailer_autoconfirm', False))
status, data = request('/rest/v1/rooms?select=id&limit=0')
code = data.get('code', '') if isinstance(data, dict) else ''
if code == 'PGRST205':
    print('Database: rooms table is not deployed/exposed yet.')
elif code == '42501' or status in (401, 403):
    print('Database: anonymous room reads are denied, as expected.')
else:
    print('Database response:', status, code, '(verify owner-only RLS after deployment)')
status, data = request('/functions/v1/design-api', 'OPTIONS')
print('Edge endpoint:', 'not deployed yet' if status == 404 else str(status))
print('These checks do not test sign-in, provider credentials or live generation.')
