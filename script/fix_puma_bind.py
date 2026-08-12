import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && sed -i 's/port ENV.fetch("PORT", 3000)/bind "tcp:\/\/0.0.0.0:#{ENV.fetch("PORT", 3000)}"/' config/puma.rb && grep bind config/puma.rb && systemctl restart tributa-lab && sleep 10 && curl -s http://127.0.0.1:3000/up'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
