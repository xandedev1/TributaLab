import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check JSON content
cmd = 'python3 -c "import json; d=json.load(open(\"/var/www/tributa-lab/tmp/razao_servicos.json\")); r=d[\"records\"][0]; print(list(r.keys()))"'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("Keys:", stdout.read().decode().strip())

# Check local JSON
import json
with open(r'c:\Users\xandao\Documents\GitHub\TributaLab\tmp\razao_servicos.json') as f:
    d = json.load(f)
    print("Local keys:", list(d['records'][0].keys()))

client.close()
