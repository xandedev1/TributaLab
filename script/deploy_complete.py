import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Force deploy
cmd = 'cd /var/www/tributa-lab && git fetch origin && git reset --hard origin/main && git clean -fd'
stdin, stdout, stderr = client.exec_command(cmd, timeout=60)
print(stdout.read().decode())
print(stderr.read().decode())

# Verify
cmd2 = 'grep -c "page_pdf" /var/www/tributa-lab/app/services/fiscal_auditor/efd_razao_dashboard.rb'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("page_pdf in dashboard:", stdout.read().decode().strip())

# Recompile assets
cmd3 = 'cd /var/www/tributa-lab && rm -rf public/assets/* && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && RAILS_ENV=production bundle exec rails assets:precompile 2>&1 | tail -5'
stdin, stdout, stderr = client.exec_command(cmd3, timeout=300)
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
