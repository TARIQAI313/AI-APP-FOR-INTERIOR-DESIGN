$port = 8080
$htmlPath = Join-Path (Split-Path $PSScriptRoot -Parent) "live_preview.html"
$content = [System.IO.File]::ReadAllBytes($htmlPath)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Prefixes.Add("http://127.0.0.1:$port/")
try {
    $listener.Start()
    Write-Host "Reverie Live Server running at http://localhost:$port/"
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $response = $context.Response
        $response.ContentType = "text/html; charset=utf-8"
        $response.ContentLength64 = $content.Length
        $response.OutputStream.Write($content, 0, $content.Length)
        $response.OutputStream.Close()
    }
} catch {
    Write-Error $_
} finally {
    $listener.Stop()
}
