import paramiko
import os

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Upload JSONs with page field
sftp = client.open_sftp()
local_tmp = r'c:\Users\xandao\Documents\GitHub\TributaLab\tmp'
for f in ['efd_razao.json', 'razao_servicos.json', 'razao_vendas.json']:
    lp = os.path.join(local_tmp, f)
    rp = f'/var/www/tributa-lab/tmp/{f}'
    if os.path.exists(lp):
        sftp.put(lp, rp)
        print(f"Uploaded {f} ({os.path.getsize(lp)} bytes)")
    else:
        print(f"MISSING: {f}")
sftp.close()

# Verify JSON has page
cmd = 'python3 -c "import json; d=json.load(open(\"/var/www/tributa-lab/tmp/razao_servicos.json\")); print(\"page\" in d[\"records\"][0] if d[\"records\"] else False)"'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("JSON has page:", stdout.read().decode().strip())

# Restart
stdin, stdout, stderr = client.exec_command('systemctl restart tributa-lab', timeout=30)
import time
time.sleep(12)

# Check
stdin, stdout, stderr = client.exec_command('curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up', timeout=30)
print("Status:", stdout.read().decode())

client.close()
print("DONE")
