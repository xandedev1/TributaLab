import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && set -a && source .env && set +a && RAILS_ENV=production bundle exec rails db:migrate:queue 2>&1 | tail -20 && echo "---MIGRATE-QUEUE-DONE---" && systemctl restart tributa-lab && sleep 10 && curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/up && echo "" && journalctl -u tributa-lab --since "30 sec ago" --no-pager | grep -iE "error|500|exception" | tail -10'''

stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
print("STDOUT:")
print(stdout.read().decode())
print("STDERR:")
print(stderr.read().decode())
client.close()
