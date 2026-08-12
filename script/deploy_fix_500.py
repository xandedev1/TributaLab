import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && git checkout -- . && git pull origin main && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && bundle install && RAILS_ENV=production bundle exec rails db:migrate:queue && systemctl restart tributa-lab && sleep 10 && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up && echo "" && journalctl -u tributa-lab --since "1 min ago" --no-pager | grep -iE "error|500|exception" | tail -10'''

stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
print("STDOUT:")
print(stdout.read().decode())
print("STDERR:")
print(stderr.read().decode())
client.close()
