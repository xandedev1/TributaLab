import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && sed -i 's/plugin :solid_queue if ENV\\["SOLID_QUEUE_IN_PUMA"\\]/plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"] == "true"/' config/puma.rb && grep solid_queue config/puma.rb && systemctl restart tributa-lab && sleep 8 && curl -s https://realaudittech.com/up'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
