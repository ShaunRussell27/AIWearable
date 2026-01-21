# Deploy Flask Server to Railway

## Step 1: Create Railway Account
1. Go to https://railway.app
2. Sign up (free account)
3. Click "Create New Project"

## Step 2: Connect GitHub or Deploy From This Folder
### Option A: Deploy directly (easiest)
1. In Railway dashboard, click "New Project"
2. Select "Deploy from GitHub" OR "Empty Project"
3. If using "Empty Project":
   - Click "Add Service" → "GitHub Repo"
   - Connect your repo OR drag & drop this folder

### Option B: Manual Upload
1. Drag & drop this entire folder to Railway dashboard
2. Railway auto-detects Python project

## Step 3: Configure Railway
1. Railway will auto-detect `requirements.txt`
2. Set environment variables:
   - PORT → 5000 (usually auto-set)
3. Click "Deploy"

Railway will:
- Install dependencies from requirements.txt
- Run `gunicorn server:app` automatically
- Give you a public URL like: `https://aiwearable-server-xyz.railway.app`

## Step 4: Update Watch Code
Once deployed, update the server URL in your watch app:

**File:** `source/AIWearableMenuDelegate.mc`
**Line:** ~19

Change:
```monkeyc
exporter.uploadToServer("https://aiwearable-server.railway.app/api/health-data");
```

To your actual Railway URL:
```monkeyc
exporter.uploadToServer("https://your-actual-railway-url.railway.app/api/health-data");
```

## Step 5: Test Upload
1. Deploy watch app
2. Press menu → "Upload Data"
3. Check Railway logs in dashboard - should show "✓ Received data from watch"

## Access Data for AI Model

### Get All Data
```bash
curl https://your-railway-url.railway.app/api/data
```

### Get Latest 20 Readings
```bash
curl https://your-railway-url.railway.app/api/data/latest?limit=20
```

### Get Statistics
```bash
curl https://your-railway-url.railway.app/api/data/stats
```

### Python Example for AI Model
```python
import requests

# Fetch latest readings
response = requests.get('https://your-railway-url.railway.app/api/data')
data = response.json()

readings = data['readings']
print(f"Total readings: {len(readings)}")

# Extract heart rates for AI model
heart_rates = [r['heartRate'] for r in readings]
stress_levels = [r['stress'] for r in readings]

# Feed to your AI model
predictions = your_model.predict(heart_rates, stress_levels)
```

## Server Endpoints Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/health-data` | POST | Watch sends data here |
| `/api/status` | GET | Check if server is running |
| `/api/data` | GET | Get ALL stored readings (for AI) |
| `/api/data/latest` | GET | Get latest N readings |
| `/api/data/stats` | GET | Get HR/stress statistics |

## Troubleshooting

### Server won't deploy
- Check `requirements.txt` syntax
- Ensure `server.py` is in root directory
- Check Railway logs for Python errors

### Watch can't upload
- Verify Railway URL is correct
- Watch needs WiFi capability
- Check watch can reach internet

### Data not appearing
- Check Railway logs: "✓ Received data from watch" should appear
- Verify watch is pressing "Upload Data" menu option
- Check POST endpoint is `/api/health-data`

## Free Railway Tier
- 500 hours/month (plenty for this)
- 1GB RAM
- Enough for continuous data collection
- Always running (no laptop needed!)

Your server is now 24/7 accessible for data collection!
