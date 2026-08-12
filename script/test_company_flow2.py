import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

cmd = '''cd /var/www/tributa-lab && curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt -L -X POST -d "username=Xande&password=123321" https://realaudittech.com/auditor-fiscal/login && echo "---" && curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/empresas | grep -c "fa-company-card" && echo "---" && curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt -X POST https://realaudittech.com/auditor-fiscal/empresas/solucoes && curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/ | grep -c "Nenhum dado" && echo "---" && curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt -X POST https://realaudittech.com/auditor-fiscal/empresas/appa && curl -s -c /tmp/cookies.txt -b /tmp/cookies.txt https://realaudittech.com/auditor-fiscal/ | grep -c "R\\$"'''

stdin, stdout, stderr = client.exec_command(cmd)
print(stdout.read().decode())
print(stderr.read().decode())
client.close()
