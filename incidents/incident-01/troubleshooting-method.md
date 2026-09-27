# Incident 01 - Port 8000 Already In Use

## Incident Summary

Nginx failed to start because port `8000`, which Nginx was configured to use, was already occupied by another process.

The investigation identified a Netcat (`nc`) process listening on port `8000`.

**Severity:** Low
**Status:** Resolved
**Service:** Nginx
**Port:** 8000

---

## 1. Incident Symptoms

The expected behaviour was:

```text
Nginx should be running and listening on port 8000.
```

Instead, Nginx failed to start.

### Initial check

```bash
sudo systemctl status nginx
```

The service reported:

```text
Active: failed
```

The important error was:

```text
nginx: [emerg] bind() to 0.0.0.0:8000 failed
```

This indicated that Nginx could not bind to port `8000`.

---

## 2. Investigation

### Step 1 - Check the Nginx service

Command:

```bash
sudo systemctl status nginx
```

Result:

```text
Active: failed
```

The error showed:

```text
bind() to 0.0.0.0:8000 failed
```

### Finding

Nginx was failing during startup because it could not bind to port `8000`.

---

### Step 2 - Check error logs for other possible error

Command:

```bash
sudo tail -n 20 /var/log/nginx/error.log
```

Result:

```text

```

### Finding

Port `8000` was already being used


---

### Step 3 - Who owns the process

Command:

```bash
sudo ss -tuplin | grep :8000
```

Result:

```text
UID    PID   PPID   CMD
moa  4256  334    nc -l 8000
```

### Finding

The process listening on port `8000` was Netcat:

```text
nc -l 8000
```

This was the process intentionally created by the incident generator script to simulate a port conflict.

---

### Step 4 - Investigate reason for the process

Command:


```bash
ps -fp <PID>
```

Result:

```text
UID          PID    PPID  C STIME TTY          TIME CMD
root         334     333  0 Sep13 ?        00:00:03 /init
```

## 5. Root Cause

The root cause was a **port conflict**.

Nginx was configured to listen on:

```text
0.0.0.0:8000
```

However, Netcat was already listening on the same port:

```text
0.0.0.0:8000
```

A single IP/port combination cannot normally be bound by both processes, so Nginx could not start.

### Root cause chain

```text
Netcat starts
     ↓
Netcat listens on port 8000
     ↓
Nginx attempts to start
     ↓
Nginx attempts to bind port 8000
     ↓
Port already occupied
     ↓
Nginx fails to start
```

---

## 6. Resolution

The conflicting Netcat process was terminated.

Command:

```bash
sudo kill <PID>
```

The port was then checked again:

```bash
sudo ss -tulpn | grep :8000
```

The Netcat process was no longer listening on port `8000`.

Nginx was then started:

```bash
sudo systemctl start nginx
```

---

## 7. Verification

### Check Nginx status

```bash
sudo systemctl status nginx
```

Expected result:

```text
Active: active (running)
```

### Check port 8000

```bash
sudo ss -tulpn | grep :8000
```

Expected result should now show Nginx rather than Netcat.

### Test the web server

```bash
curl http://localhost:8000
```

A successful response confirmed that Nginx was accessible.

---

## 8. Final Incident Status

**Status:** Resolved

**Root Cause:** Netcat process occupying TCP port 8000.

**Resolution:** Terminated the conflicting process and restarted Nginx.

**Verification:** Nginx successfully started and responded on port 8000.
