import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && git checkout -- . && git pull origin main && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && bundle install && systemctl restart tributa-lab && sleep 10 && ss -tlnp | grep 3000 && curl -s http://127.0.0.1:3000/up && curl -s https://realaudittech.com/up'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
