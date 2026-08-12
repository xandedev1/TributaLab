import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

stdin, stdout, stderr = client.exec_command('cat /var/www/tributa-lab/config/puma.rb | grep -E "port|bind"')
print(stdout.read().decode())

client.close()
