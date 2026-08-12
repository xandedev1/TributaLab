import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''sed -i 's|proxy_pass http://localhost:3000;|proxy_pass http://127.0.0.1:3000;|' /etc/nginx/sites-enabled/tributa-lab && nginx -t && systemctl reload nginx && curl -s https://realaudittech.com/up'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
