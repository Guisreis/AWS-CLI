$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFileName = "Log_$timestamp.txt"
$logFile = Join-Path -Path "D:\Cervello\logs\Log_Archive_Cervello" -ChildPath $logFileName

$Objects = Get-ChildItem -Path "D:\Cervello\Arquivos" -Recurse | Where-Object { ((Get-Date) - $_.LastWriteTime).Days -gt 465 }

foreach ($Object in $Objects) {
    $S3Path = "s3://archive-cervello/" + ($Object.FullName -replace [regex]::Escape("D:\Cervello\Arquivos\"), "")

    try {
        # Execute o comando 'aws' para copiar o objeto para o S3
        aws s3 mv $($Object.FullName) $S3Path

        # Registro de sucesso no log
        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Sucesso: $($Object.FullName) foi copiado para $S3Path"
        Write-Output $logMessage | Out-File -Append -FilePath $logFile
    }
    catch {
        # Registro de falha no log
        $errorMessage = $_.Exception.Message
        $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Falha: Não foi possível copiar $($Object.FullName) para $S3Path. Erro: $errorMessage"
        Write-Output $logMessage | Out-File -Append -FilePath $logFile
    }
}


aws s3api list-objects --bucket archive-cervello --output json --query "length(Contents)"


