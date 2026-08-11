import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && export $(cat .env | xargs) && bundle exec rails assets:precompile 2>&1 && systemctl restart tributa-lab && sleep 5 && curl -s https://realaudittech.com/auditor-fiscal/empresas | grep -c "fa-company-card"'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
