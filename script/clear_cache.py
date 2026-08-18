import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Clear Rails cache and restart
cmd = '''cd /var/www/tributa-lab && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && RAILS_ENV=production bundle exec rails runner "Rails.cache.clear" && systemctl restart tributa-lab && sleep 12 && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up'''
stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
print(stdout.read().decode())
print(stderr.read().decode())

client.close()
print("DONE")
