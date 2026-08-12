import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check if the CSS file has the new styles
cmd = 'grep -c "fa-report-nav__item" /var/www/tributa-lab/app/assets/stylesheets/fiscal_auditor.css'
stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
print("Source CSS has fa-report-nav__item:", stdout.read().decode())

# Check the compiled CSS
cmd2 = 'grep -c "fa-report-nav__item" /var/www/tributa-lab/public/assets/fiscal_auditor-*.css'
stdin, stdout, stderr = client.exec_command(cmd2, timeout=30)
print("Compiled CSS has fa-report-nav__item:", stdout.read().decode())

# Check which CSS file is being served
cmd3 = 'ls -la /var/www/tributa-lab/public/assets/fiscal_auditor-*.css'
stdin, stdout, stderr = client.exec_command(cmd3, timeout=30)
print("CSS files:", stdout.read().decode())

client.close()
