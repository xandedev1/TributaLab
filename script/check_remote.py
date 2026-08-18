import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Read first 500 bytes of remote file
cmd = 'head -c 500 /var/www/tributa-lab/tmp/razao_servicos.json'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("Remote file start:", stdout.read().decode()[:200])

client.close()
