import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check JSON structure
cmd = '''python3 << 'EOF'
import json
with open('/var/www/tributa-lab/tmp/razao_servicos.json') as f:
    d = json.load(f)
print('Type:', type(d))
if isinstance(d, dict):
    print('Keys:', list(d.keys()))
    print('First record:', d['records'][0] if d.get('records') else 'none')
else:
    print('Length:', len(d))
    print('First:', d[0] if d else 'empty')
EOF'''
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print(stdout.read().decode())
print(stderr.read().decode())

client.close()
