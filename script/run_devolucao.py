import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Run extractor
cmd = '''cd /var/www/tributa-lab && export PYTHON=/usr/bin/python3 && python3 script/extract_devolucao_pdf.py "storage/private/fiscal_auditor/solucoes/efd_razao/Razao/Devolucao.pdf" tmp/devolucao.json'''
stdin, stdout, stderr = client.exec_command(cmd, timeout=300)
print(stdout.read().decode())
print(stderr.read().decode())

# Restart
stdin, stdout, stderr = client.exec_command('systemctl restart tributa-lab', timeout=30)
import time
time.sleep(12)

# Verify
stdin, stdout, stderr = client.exec_command('curl -s -o /dev/null -w "%{http_code}" https://realaudittech.com/auditor-fiscal/devolucoes', timeout=30)
print("Status:", stdout.read().decode())

client.close()
print("DONE")
