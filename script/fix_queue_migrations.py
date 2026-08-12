import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && export $(cat .env | xargs) && bundle exec rails db:migrate:queue 2>&1 && systemctl restart tributa-lab && sleep 10 && curl -s http://localhost:3000/up'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
