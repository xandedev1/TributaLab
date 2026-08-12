import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Clear assets and recompile
cmd = '''cd /var/www/tributa-lab && rm -rf public/assets/* && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && RAILS_ENV=production bundle exec rails assets:precompile 2>&1 | tail -10'''
stdin, stdout, stderr = client.exec_command(cmd, timeout=300)
print(stdout.read().decode())
print(stderr.read().decode())

# Restart
stdin, stdout, stderr = client.exec_command('systemctl restart tributa-lab', timeout=30)
import time
time.sleep(12)

# Verify
stdin, stdout, stderr = client.exec_command('curl -s https://realaudittech.com/assets/fiscal_auditor.css | grep -c "fa-report-nav__item"', timeout=30)
print("CSS has fa-report-nav__item:", stdout.read().decode())

client.close()
print("DONE")
