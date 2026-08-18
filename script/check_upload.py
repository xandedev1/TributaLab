import paramiko
import os

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check file sizes
sftp = client.open_sftp()
local_tmp = r'c:\Users\xandao\Documents\GitHub\TributaLab\tmp'

for f in ['razao_servicos.json']:
    lp = os.path.join(local_tmp, f)
    rp = f'/var/www/tributa-lab/tmp/{f}'
    
    local_size = os.path.getsize(lp)
    remote_size = sftp.stat(rp).st_size
    
    print(f"{f}:")
    print(f"  Local: {local_size} bytes")
    print(f"  Remote: {remote_size} bytes")
    print(f"  Match: {local_size == remote_size}")

sftp.close()
client.close()
