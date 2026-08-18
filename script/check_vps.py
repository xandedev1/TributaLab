import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check if the new code is deployed
cmd = 'grep -c "page_pdf" /var/www/tributa-lab/app/services/fiscal_auditor/efd_razao_dashboard.rb'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("page_pdf in dashboard:", stdout.read().decode().strip())

cmd2 = 'grep -c "fa-nf-link" /var/www/tributa-lab/app/views/fiscal_auditor/efd_razao/show.html.erb'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("fa-nf-link in view:", stdout.read().decode().strip())

cmd3 = 'grep -c "fa-nf-link" /var/www/tributa-lab/app/assets/stylesheets/fiscal_auditor.css'
stdin, stdout, stderr = client.exec_command(cmd3, timeout=30)
print("fa-nf-link in CSS:", stdout.read().decode().strip())

# Check if JSONs have page field
cmd4 = 'python3 -c "import json; d=json.load(open(\"/var/www/tributa-lab/tmp/razao_servicos.json\")); print(\"page\" in d[\"records\"][0] if d[\"records\"] else False)"'
stdin, stdout, stderr = client.exec_command(cmd4, timeout=30)
print("JSON has page:", stdout.read().decode().strip())

client.close()
