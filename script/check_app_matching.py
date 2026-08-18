import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('179.198.110.235', username='root', password='6.18.13.1.8Host')

# Check what the app is calculating
cmd = '''cd /var/www/tributa-lab && export PATH="/root/.rbenv/bin:/root/.rbenv/shims:$PATH" && RAILS_ENV=production bundle exec rails runner "
require 'json'

data = FiscalAuditor::EfdRazaoDashboard.records('solucoes')
puts 'A100: ' + data[:a100].size.to_s
puts 'C100: ' + data[:c100].size.to_s
puts 'Razão Serviços: ' + data[:razao_servicos].size.to_s
puts 'Razão Vendas: ' + data[:razao_vendas].size.to_s

# Check matching
efd_nfs = data[:a100].map(&:num_nf).to_set
razao_nfs = data[:razao_servicos].map(&:num_nf).to_set
puts 'Matched: ' + (efd_nfs & razao_nfs).size.to_s
puts 'Unmatched EFD: ' + (efd_nfs - razao_nfs).size.to_s
puts 'Unmatched Razão: ' + (razao_nfs - efd_nfs).size.to_s
" 2>&1'''
stdin, stdout, stderr = client.exec_command(cmd, timeout=120)
print(stdout.read().decode())
print(stderr.read().decode())

client.close()
