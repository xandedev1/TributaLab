import paramiko
import os

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Deploy code
stdin, stdout, stderr = client.exec_command('cd /var/www/tributa-lab && git checkout -- . && git pull origin main', timeout=60)
print(stdout.read().decode()[-500:])

# Upload pre-generated JSONs
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

# Restart
stdin, stdout, stderr = client.exec_command('systemctl restart tributa-lab', timeout=30)
import time
time.sleep(12)

# Verify
stdin, stdout, stderr = client.exec_command('curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up && echo "" && journalctl -u tributa-lab --since "15 sec ago" --no-pager | grep -iE "error|500" | tail -3', timeout=30)
print("STATUS:", stdout.read().decode())

client.close()
print("DONE")
