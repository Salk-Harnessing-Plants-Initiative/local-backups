# -------------------------------------
# HPI Incremental Backup Script
# Compatible with PowerShell 5.1
# -------------------------------------

# === CONFIGURATION ===
$imagesSource = "C:\Users\Elizabeth\Desktop\phenotyping\local-backup-test"
$dbSource = "C:\Users\Elizabeth\.bloom\prisma.db"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$computerName = $env:COMPUTERNAME
$backupRoot = "\\multilab-na.ad.salk.edu\hpi_automation\backups\$computerName"
$slackWebhook = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXX"

# === DESTINATION PATHS ===
$dbBackupDir = Join-Path $backupRoot "database_snapshots\$timestamp"
$imagesBackupDir = Join-Path $backupRoot "images"

# === LOGGING ===
$logDir = "C:\ProgramData\HPI_Backup\logs"
$logFile = "$logDir\backup_$timestamp.log"

if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
Set-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Starting backup on $computerName"

# === SLACK FUNCTION ===
function Send-SlackMessage {
    param (
        [string]$message,
        [string]$webhookUrl
    )

    $payload = @{ text = $message } | ConvertTo-Json -Depth 3
    try {
        Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType 'application/json'
    } catch {
        Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [WARNING] Failed to send Slack message: $($_.Exception.Message)"
    }
}

# === BACKUP DATABASE ===
Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Backing up database file to '$dbBackupDir'"
New-Item -ItemType Directory -Path $dbBackupDir -Force | Out-Null

try {
    Copy-Item -Path $dbSource -Destination $dbBackupDir -Force
    Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [OK] Database backup successful."
} catch {
    Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [ERROR] Database backup FAILED: $($_.Exception.Message)"
}

# === BACKUP IMAGES (Incremental) ===
Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Updating image backup at '$imagesBackupDir'"
New-Item -ItemType Directory -Path $imagesBackupDir -Force | Out-Null

robocopy $imagesSource $imagesBackupDir /E /Z /NP /R:2 /W:5 /LOG+:$logFile

if ($LASTEXITCODE -le 7) {
    Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [OK] Image backup update successful."
} else {
    Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [WARNING] Image backup encountered issues (exit code $LASTEXITCODE)"
}

# === DONE ===
Add-Content -Path $logFile -Encoding UTF8 -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Backup script completed."

# === SLACK SUMMARY ALERT ===
try {
    $summaryLines = Get-Content -Path $logFile -Tail 50 | Select-String "^\[.*\] \[(OK|WARNING|ERROR)\]" | Select-Object -Last 5
    $summaryText = $summaryLines -join "`n"

    $message = @"
:floppy_disk: Backup on *$computerName* completed at:
$summaryText
"@

    Send-SlackMessage -message $message -webhookUrl $slackWebhook
} catch {
    $errorMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [WARNING] Slack summary could not be generated: $($_.Exception.Message)"
    Add-Content -Path $logFile -Encoding UTF8 -Value $errorMessage
}
