import paramiko
import time
import os

for i in range(10):
    try:
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host', timeout=20)
        print(f"Connected on attempt {i+1}")
        break
    except Exception as e:
        print(f"Attempt {i+1}: {type(e).__name__}")
        time.sleep(20)
else:
    print("FAILED")
    exit(1)

# 1. Kill any stuck python
stdin, stdout, stderr = client.exec_command('pkill -9 -f extract_ 2>/dev/null; echo killed', timeout=30)
print(stdout.read().decode())

# 2. Deploy fixed code (never runs extract in request cycle)
stdin, stdout, stderr = client.exec_command('cd /var/www/tributa-lab && git checkout -- . && git pull origin main', timeout=60)
print(stdout.read().decode()[-500:])

# 3. Upload pre-generated JSONs from local (extraction ran locally already)
sftp = client.open_sftp()
local_tmp = r'c:\Users\xandao\Documents\GitHub\TributaLab\tmp'
for f in ['efd_razao.json', 'razao_servicos.json', 'razao_vendas.json']:
    lp = os.path.join(local_tmp, f)
    rp = f'/var/www/tributa-lab/tmp/{f}'
    if os.path.exists(lp):
        sftp.put(lp, rp)
        print(f"Uploaded {f} ({os.path.getsize(lp)} bytes)")
    else:
        print(f"MISSING LOCAL: {f}")
sftp.close()

# 4. Restart
stdin, stdout, stderr = client.exec_command('systemctl restart tributa-lab', timeout=30)
time.sleep(12)

# 5. Verify
stdin, stdout, stderr = client.exec_command('curl -s -o /dev/null -w "%{http_code}" -m 10 https://realaudittech.com/up; echo ""; journalctl -u tributa-lab --since "30 sec ago" --no-pager | grep -iE "error|500" | tail -5', timeout=30)
print("STATUS:", stdout.read().decode())

client.close()
print("DONE")
