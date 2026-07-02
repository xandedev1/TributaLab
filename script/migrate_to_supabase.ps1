$ErrorActionPreference = "Stop"

function Invoke-Checked {
  param(
    [Parameter(Mandatory = $true)]
    [ScriptBlock]$Command
  )

  $global:LASTEXITCODE = 0
  & $Command
  $success = $?
  $exitCode = $LASTEXITCODE
  if ((-not $success) -or $exitCode -ne 0) {
    throw "Comando falhou com exit code $exitCode."
  }
}

function Assert-SupabaseDatabaseUrl {
  if ([string]::IsNullOrWhiteSpace($env:SUPABASE_DATABASE_URL)) {
    throw "SUPABASE_DATABASE_URL vazia."
  }

  if ($env:SUPABASE_DATABASE_URL -match '\.\.\.') {
    throw "A SUPABASE_DATABASE_URL contem '...'. Copie a URI completa do painel do Supabase, sem abreviar o host."
  }

  if ($env:SUPABASE_DATABASE_URL -notmatch '^postgres(ql)?://') {
    throw "A SUPABASE_DATABASE_URL precisa comecar com postgresql:// ou postgres://."
  }

  if ($env:SUPABASE_DATABASE_URL -match 'pooler\.supabase\.com' -and $env:SUPABASE_DATABASE_URL -notmatch '^postgres(ql)?://postgres\.[^:]+:') {
    throw "Para pooler.supabase.com, o usuario deve ser postgres.<project-ref>, por exemplo postgres.eqafmzumyjiecvuezfrz."
  }
}

if (-not $env:SUPABASE_DATABASE_URL) {
  $secureUrl = Read-Host "Cole a SUPABASE_DATABASE_URL completa" -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureUrl)
  try {
    $env:SUPABASE_DATABASE_URL = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

Assert-SupabaseDatabaseUrl

Invoke-Checked { bundle exec ruby script/test_supabase_connection.rb }

$previousDatabaseUrl = $env:DATABASE_URL
try {
  $env:DATABASE_URL = $env:SUPABASE_DATABASE_URL
  Invoke-Checked { bundle exec ruby script/load_schema_to_supabase.rb }
} finally {
  if ($null -eq $previousDatabaseUrl) {
    Remove-Item Env:\DATABASE_URL -ErrorAction SilentlyContinue
  } else {
    $env:DATABASE_URL = $previousDatabaseUrl
  }
}

Invoke-Checked { bundle exec ruby script/copy_database_to_supabase.rb }