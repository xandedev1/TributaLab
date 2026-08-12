import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Force deploy
cmd = 'cd /var/www/tributa-lab && git fetch origin && git reset --hard origin/main && git clean -fd'
stdin, stdout, stderr = client.exec_command(cmd, timeout=60)
print(stdout.read().decode())
print(stderr.read().decode())

# Verify code
cmd2 = 'sed -n "113,120p" /var/www/tributa-lab/app/services/fiscal_auditor/efd_razao_dashboard.rb'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("Code after deploy:")
print(stdout.read().decode())

# Restart
stdin, stdout, stderr = client.exec_command('systemctl restart tributa-lab', timeout=30)
import time
time.sleep(12)

# Test
stdin, stdout, stderr = client.exec_command('curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up', timeout=30)
print("Status:", stdout.read().decode())

client.close()
print("DONE")
