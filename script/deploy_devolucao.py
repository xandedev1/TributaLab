import paramiko
import os

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Upload Devolucao PDF
sftp = client.open_sftp()
local_pdf = r'C:\Users\xandao\Downloads\devolucao appa\RAZÃO DEVOLUÇÃO.pdf'
remote_dir = '/var/www/tributa-lab/storage/private/fiscal_auditor/solucoes/efd_razao/Razao'
remote_pdf = f'{remote_dir}/Devolucao.pdf'

# Create directory if needed
stdin, stdout, stderr = client.exec_command(f'mkdir -p "{remote_dir}"', timeout=30)
print(stdout.read().decode())

# Upload
sftp.put(local_pdf, remote_pdf)
print(f"Uploaded {os.path.getsize(local_pdf)} bytes")

sftp.close()

# Deploy code
stdin, stdout, stderr = client.exec_command('cd /var/www/tributa-lab && git checkout -- . && git pull origin main', timeout=60)
print(stdout.read().decode()[-500:])

# Recompile assets
stdin, stdout, stderr = client.exec_command('cd /var/www/tributa-lab && rm -rf public/assets/* && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && RAILS_ENV=production bundle exec rails assets:precompile 2>&1 | tail -3', timeout=300)
print(stdout.read().decode())

# Restart
stdin, stdout, stderr = client.exec_command('systemctl restart tributa-lab', timeout=30)
import time
time.sleep(12)

# Verify
stdin, stdout, stderr = client.exec_command('curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up', timeout=30)
print("Status:", stdout.read().decode())

client.close()
print("DONE")
