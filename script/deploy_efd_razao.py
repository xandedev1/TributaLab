import paramiko
import os
import stat

VPS_HOST = '179.198.110.235'
VPS_USER = 'root'
VPS_PASS = '6.18.13.1.8Host'
LOCAL_BASE = r'c:\Users\xandao\Documents\GitHub\TributaLab\storage\private\fiscal_auditor\solucoes\efd_razao'
REMOTE_BASE = '/var/www/tributa-lab/storage/private/fiscal_auditor/solucoes/efd_razao'

def ssh_exec(client, cmd):
    print(f">>> {cmd}")
    stdin, stdout, stderr = client.exec_command(cmd, timeout=300)
    out = stdout.read().decode()
    err = stderr.read().decode()
    if out: print(out)
    if err: print(f"STDERR: {err}")
    return out, err

def sftp_mkdirs(sftp, path):
    try:
        sftp.stat(path)
    except FileNotFoundError:
        parent = os.path.dirname(path)
        sftp_mkdirs(sftp, parent)
        sftp.mkdir(path)

def sftp_put_dir(sftp, local_dir, remote_dir):
    sftp_mkdirs(sftp, remote_dir)
    for item in os.listdir(local_dir):
        local_path = os.path.join(local_dir, item)
        remote_path = f"{remote_dir}/{item}"
        if os.path.isfile(local_path):
            print(f"  Upload: {item} ({os.path.getsize(local_path)} bytes)")
            sftp.put(local_path, remote_path)
        elif os.path.isdir(local_path):
            sftp_put_dir(sftp, local_path, remote_path)

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(VPS_HOST, username=VPS_USER, password=VPS_PASS)

# 1. Deploy code
ssh_exec(client, 'cd /var/www/tributa-lab && git checkout -- . && git pull origin main')

# 2. Install pdfplumber on VPS
ssh_exec(client, 'pip3 install pdfplumber 2>&1 | tail -5')

# 3. Create directories and upload data
transport = client.get_transport()
sftp = paramiko.SFTPClient.from_transport(transport)

print("\n=== Uploading EFD files ===")
sftp_put_dir(sftp, os.path.join(LOCAL_BASE, 'arquivos EFD'), f'{REMOTE_BASE}/arquivos EFD')

print("\n=== Uploading Razao PDFs ===")
sftp_put_dir(sftp, os.path.join(LOCAL_BASE, 'Razao'), f'{REMOTE_BASE}/Razao')

sftp.close()

# 4. Restart service
ssh_exec(client, 'systemctl restart tributa-lab')

# 5. Wait and check
import time
time.sleep(12)
ssh_exec(client, 'curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up')

# 6. Check for errors
ssh_exec(client, 'journalctl -u tributa-lab --since "30 sec ago" --no-pager | grep -iE "error|500|exception" | tail -10')

client.close()
print("\n=== DONE ===")
