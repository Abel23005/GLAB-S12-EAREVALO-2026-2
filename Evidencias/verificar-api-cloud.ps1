$ErrorActionPreference = 'Stop'
$base = 'https://eventos-api-glab-s12.onrender.com'
$outDir = $PSScriptRoot
$handler = [System.Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect = $false
$client = [System.Net.Http.HttpClient]::new($handler)
$rows = [System.Collections.Generic.List[object]]::new()

function Request($name, $method, $path, $expected, $body = $null) {
    $request = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::new($method), "$base$path")
    if ($null -ne $body) {
        $json = ConvertTo-Json -InputObject $body -Depth 10 -Compress
        $request.Content = [System.Net.Http.StringContent]::new($json, [System.Text.Encoding]::UTF8, 'application/json')
    }
    $response = $client.SendAsync($request).GetAwaiter().GetResult()
    $status = [int]$response.StatusCode
    $content = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $rows.Add([pscustomobject]@{
        Caso = $name; Metodo = $method; Ruta = $path; Esperado = $expected; Obtenido = $status
        Resultado = if ($status -eq $expected) { 'OK' } else { 'FALLO' }
        Location = if ($response.Headers.Location) { $response.Headers.Location.ToString() } else { '' }
    })
    $request.Dispose()
    $response.Dispose()
    return $content
}

$categories = @(Request 'Listar categorías' GET '/api/categorias' 200 | ConvertFrom-Json)
$categoryWithEvents = $null
$events = @(Request 'Listar eventos' GET '/api/eventos' 200 | ConvertFrom-Json)
$sampleEvent = $events[0]
$categoryWithEvents = $sampleEvent.categoriaId
$existingCategory = $categories | Where-Object Id -eq $categoryWithEvents | Select-Object -First 1

Request 'Categoría existente' GET "/api/categorias/$categoryWithEvents" 200 | Out-Null
Request 'Categoría inexistente' GET '/api/categorias/999999' 404 | Out-Null
Request 'Eventos de categoría' GET "/api/categorias/$categoryWithEvents/eventos" 200 | Out-Null
Request 'Eventos de categoría inexistente' GET '/api/categorias/999999/eventos' 404 | Out-Null
Request 'Categoría duplicada' POST '/api/categorias' 409 @{ nombre = $existingCategory.nombre; descripcion = 'Duplicada para verificar 409' } | Out-Null

$suffix = [guid]::NewGuid().ToString('N').Substring(0, 8)
$newCategoryName = "Prueba $suffix"
$createdCategory = Request 'Crear categoría' POST '/api/categorias' 201 @{ nombre = $newCategoryName; descripcion = 'Registro temporal de verificación cloud' } | ConvertFrom-Json
Request 'Actualizar categoría' PUT "/api/categorias/$($createdCategory.id)" 204 @{ id = $createdCategory.id; nombre = "$newCategoryName editada"; descripcion = 'Verificación PUT' } | Out-Null
Request 'Id de categoría no coincide' PUT "/api/categorias/$($createdCategory.id)" 400 @{ id = 999999; nombre = 'No coincide'; descripcion = '' } | Out-Null
Request 'Actualizar categoría inexistente' PUT '/api/categorias/999999' 404 @{ id = 999999; nombre = 'No existe'; descripcion = '' } | Out-Null
Request 'Nombre duplicado al actualizar categoría' PUT "/api/categorias/$($createdCategory.id)" 409 @{ id = $createdCategory.id; nombre = $existingCategory.nombre; descripcion = '' } | Out-Null
Request 'No borrar categoría con eventos' DELETE "/api/categorias/$categoryWithEvents" 409 | Out-Null
Request 'Eliminar categoría temporal' DELETE "/api/categorias/$($createdCategory.id)" 204 | Out-Null
Request 'Eliminar categoría inexistente' DELETE '/api/categorias/999999' 404 | Out-Null

Request 'Filtrar eventos' GET "/api/eventos?categoriaId=$categoryWithEvents" 200 | Out-Null
Request 'Evento existente' GET "/api/eventos/$($sampleEvent.id)" 200 | Out-Null
Request 'Evento inexistente' GET '/api/eventos/999999' 404 | Out-Null
Request 'Evento duplicado' POST '/api/eventos' 409 @{
    titulo = $sampleEvent.titulo; lugar = $sampleEvent.lugar; fecha = $sampleEvent.fecha
    aforo = $sampleEvent.aforo; precio = $sampleEvent.precio; categoriaId = $sampleEvent.categoriaId
} | Out-Null
Request 'Categoría inválida al crear evento' POST '/api/eventos' 400 @{
    titulo = "Inválido $suffix"; lugar = 'Lima'; fecha = [DateTime]::UtcNow.AddDays(90).ToString('o')
    aforo = 20; precio = 10; categoriaId = 999999
} | Out-Null

$newEventTitle = "Evento temporal $suffix"
$createdEvent = Request 'Crear evento' POST '/api/eventos' 201 @{
    titulo = $newEventTitle; lugar = 'Lima'; fecha = [DateTime]::UtcNow.AddDays(90).ToString('o')
    aforo = 20; precio = 10; categoriaId = $categoryWithEvents
} | ConvertFrom-Json
Request 'Actualizar evento' PUT "/api/eventos/$($createdEvent.id)" 204 @{
    id = $createdEvent.id; titulo = "$newEventTitle editado"; lugar = 'Lima'; fecha = $createdEvent.fecha
    aforo = 22; precio = 11; categoriaId = $categoryWithEvents
} | Out-Null
Request 'Id de evento no coincide' PUT "/api/eventos/$($createdEvent.id)" 400 @{
    id = 999999; titulo = 'No coincide'; lugar = 'Lima'; fecha = $createdEvent.fecha
    aforo = 22; precio = 11; categoriaId = $categoryWithEvents
} | Out-Null
Request 'Actualizar evento inexistente' PUT '/api/eventos/999999' 404 @{
    id = 999999; titulo = 'No existe'; lugar = 'Lima'; fecha = $createdEvent.fecha
    aforo = 22; precio = 11; categoriaId = $categoryWithEvents
} | Out-Null
Request 'Categoría inválida al actualizar evento' PUT "/api/eventos/$($createdEvent.id)" 400 @{
    id = $createdEvent.id; titulo = 'Categoría inválida'; lugar = 'Lima'; fecha = $createdEvent.fecha
    aforo = 22; precio = 11; categoriaId = 999999
} | Out-Null
Request 'Duplicado al actualizar evento' PUT "/api/eventos/$($createdEvent.id)" 409 @{
    id = $createdEvent.id; titulo = $sampleEvent.titulo; lugar = $sampleEvent.lugar; fecha = $sampleEvent.fecha
    aforo = $sampleEvent.aforo; precio = $sampleEvent.precio; categoriaId = $sampleEvent.categoriaId
} | Out-Null
Request 'Eliminar evento temporal' DELETE "/api/eventos/$($createdEvent.id)" 204 | Out-Null
Request 'Eliminar evento inexistente' DELETE '/api/eventos/999999' 404 | Out-Null

$rows | Export-Csv -NoTypeInformation -Encoding utf8 (Join-Path $outDir 'resultados-cloud.csv')
$passed = @($rows | Where-Object Resultado -eq 'OK').Count
$failed = $rows.Count - $passed
$report = @(
    '# Verificación de API en Render'
    ''
    "- URL: $base"
    "- Swagger: $base/swagger/index.html"
    "- Fecha UTC: $([DateTime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss'))"
    "- Casos: $($rows.Count)"
    "- Correctos: $passed"
    "- Fallidos: $failed"
    ''
    '| Caso | Método | Ruta | Esperado | Obtenido | Resultado |'
    '|---|---|---|---:|---:|---|'
)
foreach ($row in $rows) { $report += "| $($row.Caso) | $($row.Metodo) | ``$($row.Ruta)`` | $($row.Esperado) | $($row.Obtenido) | $($row.Resultado) |" }
$report | Set-Content -Encoding utf8 (Join-Path $outDir 'resultados-cloud.md')
$rows | Format-Table Caso, Metodo, Ruta, Esperado, Obtenido, Resultado -AutoSize
"Total: $($rows.Count); Correctos: $passed; Fallidos: $failed"
$client.Dispose()
if ($failed -gt 0) { exit 1 }
