# Download this installer, inspect it, then run it. No administrator rights required.
[CmdletBinding()]
param(
  [string]$Version = 'latest',
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'Kiofco\bin'),
  [switch]$Replace
)
$ErrorActionPreference = 'Stop'
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
  throw 'Use cli-install.sh on macOS or Linux.'
}
$architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
$arch = switch ($architecture) { 'X64' { 'amd64' } 'Arm64' { 'arm64' } default { throw 'Unsupported CPU.' } }
$base = 'https://github.com/kiofco-app/kiofco-cli/releases'
if ($Version -eq 'latest') {
  $base += '/latest/download'
} elseif ($Version -match '^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
  $base += "/download/$Version"
} else { throw 'Version must be vMAJOR.MINOR.PATCH.' }

$staging = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($staging) | Out-Null
$temporary = $null
$client = $null
$handler = $null
try {
  # HttpClient explicitly bounds redirects to HTTPS GitHub release delivery hosts.
  Add-Type -AssemblyName System.Net.Http
  $handler = [Net.Http.HttpClientHandler]::new()
  $handler.AllowAutoRedirect = $false
  $client = [Net.Http.HttpClient]::new($handler)
  $client.Timeout = [TimeSpan]::FromSeconds(120)
  function Fetch([string]$Url, [string]$Path) {
    $uri = [Uri]$Url
    for ($hop = 0; $hop -lt 8; $hop++) {
      if ($uri.Scheme -ne 'https' -or $uri.Host -notin @('github.com', 'release-assets.githubusercontent.com', 'objects.githubusercontent.com')) {
        throw 'Unexpected release download destination.'
      }
      $response = $client.GetAsync($uri).GetAwaiter().GetResult()
      try {
        if ([int]$response.StatusCode -in @(301, 302, 303, 307, 308)) {
          $uri = [Uri]::new($uri, $response.Headers.Location)
          continue
        }
        $response.EnsureSuccessStatusCode() | Out-Null
        [IO.File]::WriteAllBytes($Path, $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult())
        return
      } finally { $response.Dispose() }
    }
    throw 'Too many download redirects.'
  }
  $manifest = Join-Path $staging 'SHA256SUMS'
  Fetch "$base/SHA256SUMS" $manifest
  $pattern = '^([a-f0-9]{64})  (kiofco_v[0-9]+\.[0-9]+\.[0-9]+_windows_' + $arch + '\.zip)$'
  $entries = @(Get-Content -LiteralPath $manifest | Where-Object { $_ -cmatch $pattern })
  if ($entries.Count -ne 1) { throw 'Missing or ambiguous release target.' }
  $entries[0] -cmatch $pattern | Out-Null
  $expected = $Matches[1]; $name = $Matches[2]
  if ($Version -ne 'latest' -and $name -ne "kiofco_${Version}_windows_${arch}.zip") {
    throw 'Release manifest does not match requested version.'
  }
  $archive = Join-Path $staging $name
  Fetch "$base/$name" $archive
  if ((Get-FileHash -Algorithm SHA256 -LiteralPath $archive).Hash.ToLowerInvariant() -ne $expected) {
    throw 'Checksum verification failed.'
  }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::OpenRead($archive)
  try {
    $members = @($zip.Entries | ForEach-Object { $_.FullName })
    if ($members.Count -ne 2 -or @($members | Where-Object { $_ -notin @('kiofco.exe', 'README.md') }).Count -gt 0) {
      throw 'Unexpected archive members.'
    }
    $entry = @($zip.Entries | Where-Object { $_.FullName -ceq 'kiofco.exe' })
    if ($entry.Count -ne 1) { throw 'Missing executable.' }
    [IO.Directory]::CreateDirectory($InstallDir) | Out-Null
    $destination = Join-Path $InstallDir 'kiofco.exe'
    if ((Test-Path -LiteralPath $destination) -and -not $Replace) { throw 'Already installed; use -Replace to upgrade.' }
    $temporary = Join-Path $InstallDir ([Guid]::NewGuid().ToString('N') + '.tmp')
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry[0], $temporary, $false)
    Move-Item -LiteralPath $temporary -Destination $destination -Force
  } finally { $zip.Dispose() }
  Write-Output "Installed $destination. Add $InstallDir to your user PATH if needed."
} finally {
  if ($client) { $client.Dispose() }
  if ($handler) { $handler.Dispose() }
  if ($temporary -and (Test-Path -LiteralPath $temporary)) { Remove-Item -LiteralPath $temporary -Force }
  Remove-Item -LiteralPath $staging -Recurse -Force
}
