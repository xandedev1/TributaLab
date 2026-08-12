import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# First deploy the code fix
cmd = 'cd /var/www/tributa-lab && git checkout -- . && git pull origin main'
stdin, stdout, stderr = client.exec_command(cmd, timeout=60)
print(stdout.read().decode())

# Run extraction in background on VPS
cmd2 = '''cd /var/www/tributa-lab && export PYTHON=/usr/bin/python3 && nohup python3 script/extract_efd_razao.py "storage/private/fiscal_auditor/solucoes/efd_razao/arquivos EFD" tmp/efd_razao.json > /tmp/efd_extract.log 2>&1 &
echo "EFD extraction started, PID: $!"'''
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print(stdout.read().decode())

cmd3 = '''cd /var/www/tributa-lab && export PYTHON=/usr/bin/python3 && nohup python3 script/extract_razao_pdf.py "storage/private/fiscal_auditor/solucoes/efd_razao/Razao/Servicos Mercado Interno.pdf" tmp/razao_servicos.json > /tmp/razao_servicos.log 2>&1 &
echo "Servicos extraction started, PID: $!"'''
stdin, stdout, stderr = client.exec_command(cmd3, timeout=30)
print(stdout.read().decode())

cmd4 = '''cd /var/www/tributa-lab && export PYTHON=/usr/bin/python3 && nohup python3 script/extract_razao_pdf.py "storage/private/fiscal_auditor/solucoes/efd_razao/Razao/Venda Mercado Interno.pdf" tmp/razao_vendas.json > /tmp/razao_vendas.log 2>&1 &
echo "Vendas extraction started, PID: $!"'''
stdin, stdout, stderr = client.exec_command(cmd4, timeout=30)
print(stdout.read().decode())

client.close()
print("\nExtraction started in background. Waiting for completion...")
