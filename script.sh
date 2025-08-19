#!/usr/bin/env python3
import psutil
import socket
import shutil
import smtplib
from email.mime.text import MIMEText
from datetime import datetime

# ---------- Configuration ----------
CPU_THRESHOLD = 80        # %
MEM_THRESHOLD = 80        # %
DISK_THRESHOLD = 85       # %
CHECK_HOST = "google.com" # replace with trading API host
CHECK_PORT = 80           # replace with trading API port
ALERT_EMAIL = "alerts@example.com"
FROM_EMAIL = "noreply@example.com"
SMTP_SERVER = "smtp.example.com"

# ---------- Health Checks ----------
def check_cpu():
    usage = psutil.cpu_percent(interval=1)
    return usage, usage < CPU_THRESHOLD

def check_memory():
    mem = psutil.virtual_memory()
    return mem.percent, mem.percent < MEM_THRESHOLD

def check_disk():
    disk = shutil.disk_usage("/")
    usage = (disk.used / disk.total) * 100
    return usage, usage < DISK_THRESHOLD

def check_connectivity(host, port):
    try:
        socket.create_connection((host, port), timeout=5)
        return True
    except Exception:
        return False

# ---------- Alerting ----------
def send_email_alert(subject, body):
    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = FROM_EMAIL
    msg["To"] = ALERT_EMAIL

    try:
        with smtplib.SMTP(SMTP_SERVER) as server:
            server.sendmail(FROM_EMAIL, ALERT_EMAIL, msg.as_string())
        print(" Alert email sent")
    except Exception as e:
        print(f" Failed to send email: {e}")

# ---------- Main ----------
def run_checks():
    report = []
    status_ok = True

    # CPU
    cpu_usage, ok = check_cpu()
    report.append(f"CPU Usage: {cpu_usage:.2f}% - {'OK' if ok else 'HIGH'}")
    status_ok &= ok

    # Memory
    mem_usage, ok = check_memory()
    report.append(f"Memory Usage: {mem_usage:.2f}% - {'OK' if ok else 'HIGH'}")
    status_ok &= ok

    # Disk
    disk_usage, ok = check_disk()
    report.append(f"Disk Usage: {disk_usage:.2f}% - {'OK' if ok else 'HIGH'}")
    status_ok &= ok

    # Connectivity
    ok = check_connectivity(CHECK_HOST, CHECK_PORT)
    report.append(f"Connectivity to {CHECK_HOST}:{CHECK_PORT} - {'OK' if ok else 'FAILED'}")
    status_ok &= ok

    # Final Report
    full_report = "\n".join(report)
    print("\n=== System Health Report ===")
    print(full_report)

    if not status_ok:
        send_email_alert(" System Health Alert", full_report)

if __name__ == "__main__":
    print(f"Running system checks @ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    run_checks()
