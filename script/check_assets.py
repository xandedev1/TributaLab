import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Verifica se o CSS tá sendo servido
stdin, stdout, stderr = client.exec_command('curl -s https://realaudittech.com/assets/fiscal_auditor.css | grep -c "fa-company-card"')
print('CSS tem fa-company-card:', stdout.read().decode().strip())

# Verifica o HTML
stdin, stdout, stderr = client.exec_command('curl -s https://realaudittech.com/auditor-fiscal/empresas | grep -c "fa-company-card"')
print('HTML tem fa-company-card:', stdout.read().decode().strip())

# Verifica se o CSS foi compilado
stdin, stdout, stderr = client.exec_command('ls -la /var/www/tributa-lab/public/assets/fiscal_auditor*.css 2>/dev/null | head -5')
print('Assets:', stdout.read().decode())

client.close()
