# local-backups

# HPI Data Acquisition Backup Script

This PowerShell script automates secure, backups of database files and image directories from data acquisition computers to a central server (`\\multilab-na.ad.salk.edu\hpi_automation`). It includes logging and Slack notifications.

---

## 🚀 Features

- 🗂 Incremental backup of image directories
- 🧠 Snapshot-style backup of database file (`prisma.db`)
- 📅 Timestamped backup folders
- 📄 Detailed UTF-8 encoded logs
- 🔔 Slack notifications with status summary

---

## 🛠 Requirements

- Windows 10+ with PowerShell 5.1
- Network access to: `\\multilab-na.ad.salk.edu\hpi_automation`
- AD credentials with write access to the target share
- Images scanned using https://github.com/eberrigan/bloom-desktop-pilot.
- Prisma database with metadata from scans.
- A Slack Webhook URL (for alerting)

---

## 🧾 What It Backs Up

| Item        | Behavior                     | Destination Format |
|-------------|------------------------------|---------------------|
| `prisma.db` | Snapshot every run           | `backups/<host>/database_snapshots/<timestamp>/` |
| Image Dir   | Incremental sync (no delete) | `backups/<host>/images/` |

---

## 🧪 Testing the Script

1. Save the script as `backup.ps1`
2. Modify `$imagesSource`, `$dbSource`, `$slackWebhook` in the script to image directory, database location, and Slack webhook respectively.
2. Open PowerShell:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\backup.ps1
   ```

---

## 🖥 Recommended Deployment (Per Computer)

1. Store the script at:
   ```
   C:\ProgramData\HPI_Backup\backup.ps1
   ```
2. Create a scheduled task:
   - Run weekly at night (e.g., Sunday 2AM)
   - Set to run "Whether user is logged on or not"
   - Run with highest privileges
   - Use:
     ```
     Program: powershell
     Arguments: -ExecutionPolicy Bypass -File "C:\ProgramData\HPI_Backup\backup.ps1"
     ```
**Note** For this to work, the database and images have to be in a location that is accessible to user running the script.

---

## 📬 Slack Notification

The script posts a summary to Slack using your configured Incoming Webhook.

Example message:
```
:floppy_disk: Backup on TALMO-LAB-02 completed at:

[OK] Database backup successful.
[OK] Image backup update successful.
Backup script completed.
```

Customize the alert in the script by editing the `Send-SlackMessage` function or adjusting the log filters.

---

## 📁 Log Output

Logs are stored at:

```
C:\ProgramData\HPI_Backup\logs\backup_<timestamp>.log
```

Each run appends detailed backup status, robocopy output, and any errors.

---
