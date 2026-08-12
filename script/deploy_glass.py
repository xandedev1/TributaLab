import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = 'cd /var/www/tributa-lab && git checkout -- . && git pull origin main && rm -rf public/assets/* && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && RAILS_ENV=production bundle exec rails assets:precompile 2>&1 | tail -3 && systemctl restart tributa-lab && sleep 12 && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up'
stdin, stdout, stderr = client.exec_command(cmd, timeout=300)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
