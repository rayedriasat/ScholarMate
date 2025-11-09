# Keep Render Service Alive

## Problem
Render free tier spins down after 15 minutes of inactivity, causing 502 errors.

## Solution: Use a Free Cron Service

### Option A: cron-job.org (Recommended)
1. Go to https://cron-job.org/en/
2. Create free account
3. Add new cron job:
   - URL: `https://scholarmate-fc1r.onrender.com/api/health`
   - Interval: Every 10 minutes
   - Method: GET

### Option B: UptimeRobot
1. Go to https://uptimerobot.com/
2. Create free account (50 monitors)
3. Add HTTP(s) monitor:
   - URL: `https://scholarmate-fc1r.onrender.com/api/health`
   - Interval: 5 minutes

### Option C: GitHub Actions (if you have a repo)
Create `.github/workflows/keep-alive.yml`:

```yaml
name: Keep Render Alive
on:
  schedule:
    - cron: '*/10 * * * *'  # Every 10 minutes
  workflow_dispatch:

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Render
        run: curl https://scholarmate-fc1r.onrender.com/api/health
```

## Note
This only works during active hours. For 24/7 uptime, upgrade to Render paid tier ($7/month).
