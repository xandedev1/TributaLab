import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check JSON structure
cmd = 'python3 -c "import json; d=json.load(open(\"/var/www/tributa-lab/tmp/razao_servicos.json\")); print(type(d)); print(list(d.keys()) if isinstance(d, dict) else len(d))"'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("JSON structure:", stdout.read().decode())

# Check first record
cmd2 = 'python3 -c "import json; d=json.load(open(\"/var/www/tributa-lab/tmp/razao_servicos.json\")); r=d[\"records\"][0] if isinstance(d, dict) else d[0]; print(r)"'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("First record:", stdout.read().decode())

client.close()
