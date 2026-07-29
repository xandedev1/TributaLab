param(
    [string]$OutputPath = "tmp/esocial_fgts_2025-01.json",
    [int]$DebugPort = 9222
)

$ErrorActionPreference = "Stop"

function Invoke-CdpEvaluate {
    param(
        [string]$WebSocketUrl,
        [string]$Expression
    )

    $socket = [System.Net.WebSockets.ClientWebSocket]::new()
    $socket.ConnectAsync([Uri]$WebSocketUrl, [Threading.CancellationToken]::None).GetAwaiter().GetResult() | Out-Null

    try {
        $payload = @{
            id = 1
            method = "Runtime.evaluate"
            params = @{
                expression = $Expression
                returnByValue = $true
            }
        } | ConvertTo-Json -Compress -Depth 8

        $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
        $socket.SendAsync(
            [ArraySegment[byte]]::new($bytes),
            [System.Net.WebSockets.WebSocketMessageType]::Text,
            $true,
            [Threading.CancellationToken]::None
        ).GetAwaiter().GetResult() | Out-Null

        $buffer = New-Object byte[] 65536

        do {
          $stream = [IO.MemoryStream]::new()

          do {
            $result = $socket.ReceiveAsync(
              [ArraySegment[byte]]::new($buffer),
              [Threading.CancellationToken]::None
            ).GetAwaiter().GetResult()
            $stream.Write($buffer, 0, $result.Count)
          } while (-not $result.EndOfMessage)

          $response = [Text.Encoding]::UTF8.GetString($stream.ToArray()) | ConvertFrom-Json
        } while ($response.id -ne 1)

        if ($response.error) {
          throw "Chrome DevTools retornou erro: $($response.error.message)"
        }

        if ($response.result.exceptionDetails) {
          $exception = $response.result.exceptionDetails.exception
          throw "A avaliação da página falhou: $($exception.description)"
        }

        return $response.result.result.value
    }
    finally {
        $socket.Dispose()
    }
}

$page = $null
$targets = Invoke-RestMethod -Uri "http://127.0.0.1:$DebugPort/json/list"
foreach ($target in $targets) {
  if ($target.type -eq "page" -and $target.url -match "/Totalizador/FGTSPorEmpregador") {
    $page = $target
    break
  }
}

if (-not $page) {
    throw "A página do Totalizador de FGTS por Empregador não está aberta no Chrome isolado."
}

$expression = @'
(() => {
  const clean = (value) => (value || '').replace(/\s+/g, ' ').trim();
  const establishmentHeader = Array.from(document.querySelectorAll('h2.titulo-tabela'))
    .find((header) => clean(header.innerText).startsWith('Estabelecimento:'));

  if (!establishmentHeader) {
    throw new Error('Cabeçalho do estabelecimento não encontrado. Pesquise a competência antes de executar a extração.');
  }

  const establishmentText = clean(establishmentHeader.innerText);
  const establishmentMatch = establishmentText.match(/^Estabelecimento:\s*([^\s]+)\s*-\s*(.+)$/);
  const lotationHeaders = Array.from(document.querySelectorAll('.estabelecimento-lotacao > .accordion > h2'));
  const receipt = document.body.innerText.match(/1\.1\.\d+/)?.[0] || null;

  const lotations = lotationHeaders.map((header, index) => {
    const headerText = clean(header.innerText);
    const codeMatch = headerText.match(/E\d{5}-\d{3}-\d{2}A/);
    const typeMatch = headerText.match(/:\s*(\d{2})\s*-\s*(.+)$/);
    const panel = header.nextElementSibling;
    const table = panel.querySelector('table');

    return {
      sequence: index + 1,
      lotation_code: codeMatch ? codeMatch[0] : null,
      lotation_type_code: typeMatch ? typeMatch[1] : null,
      lotation_type_description: typeMatch ? typeMatch[2] : typePart,
      table_headers: Array.from(table.querySelectorAll('thead th')).map((cell) => clean(cell.innerText)),
      rows: Array.from(table.querySelectorAll('tbody tr')).map((row) => {
        const cells = Array.from(row.cells).map((cell) => clean(cell.innerText));
        return {
          calculation_base: cells[0],
          incidence_indicator: cells[1],
          remuneration_base: cells[2],
          fgts_to_deposit: cells[3],
          fgts_notification: cells[4],
          rubric_nature: cells[5]
        };
      })
    };
  });

  return JSON.stringify({
    source: {
      url: window.location.href,
      extracted_at: new Date().toISOString(),
      period: document.querySelector('#PeriodoApuracao')?.value || null,
      closing_receipt: receipt
    },
    establishment: {
      registration: establishmentMatch ? establishmentMatch[1] : null,
      name: establishmentMatch ? establishmentMatch[2] : establishmentText
    },
    lotations
  });
})()
'@

$extractedJson = Invoke-CdpEvaluate -WebSocketUrl $page.webSocketDebuggerUrl -Expression $expression
$result = $extractedJson | ConvertFrom-Json

if ($result.source.period -ne "01/2025") {
    throw "Competência inesperada: $($result.source.period). Esperado: 01/2025."
}

$lotationCount = @($result.lotations).Count
$rowCount = @($result.lotations | ForEach-Object { $_.rows }).Count

if ($lotationCount -ne 147) {
    throw "Quantidade inesperada de lotações: $lotationCount. Esperado: 147."
}

if ($rowCount -ne 296) {
    throw "Quantidade inesperada de linhas de FGTS: $rowCount. Esperado: 296."
}

$invalidLotations = @($result.lotations | Where-Object { -not $_.lotation_code -or -not $_.lotation_type_code })
if ($invalidLotations.Count -gt 0) {
  throw "Foram encontradas $($invalidLotations.Count) lotações com cabeçalho fora do formato esperado."
}

$directory = Split-Path -Parent $OutputPath
if ($directory) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

$result | ConvertTo-Json -Depth 100 | Set-Content -Path $OutputPath -Encoding utf8

Write-Output "Extração salva em $OutputPath"
Write-Output "Estabelecimento: $($result.establishment.registration) - $($result.establishment.name)"
Write-Output "Lotações: $lotationCount"
Write-Output "Linhas de FGTS: $rowCount"