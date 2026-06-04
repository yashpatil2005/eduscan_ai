# Deploying EduScan AI Backend

This guide covers deploying the EduScan AI Flask backend to production using [Render](https://render.com), a popular platform for hosting web services with a generous free tier.

---

## Table of Contents

1. [Why Render?](#why-render)
2. [Prerequisites](#prerequisites)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Environment Variables](#environment-variables)
5. [Configuration Options](#configuration-options)
6. [Testing Your Deployment](#testing-your-deployment)
7. [Updating Your Deployment](#updating-your-deployment)
8. [Troubleshooting](#troubleshooting)
9. [Production Considerations](#production-considerations)

---

## Why Render?

**Advantages:**
- ✅ **Generous Free Tier**: 750 hours/month (always-on)
- ✅ **Easy Deployment**: Direct from GitHub
- ✅ **Automatic HTTPS**: SSL certificate included
- ✅ **Simple Scaling**: Upgrade when needed
- ✅ **Good Documentation**: Clear and comprehensive

**Limitations (Free Tier):**
- Service sleeps after 15 minutes of inactivity
- Wakes up on next request (30-60 second delay)
- 512 MB RAM
- Shared CPU

**When to Upgrade:**
- Consistent traffic (no sleep delays)
- Need more RAM/CPU
- Custom domains with advanced features

---

## Prerequisites

Before deploying, ensure you have:

1. **GitHub Account**: With your code pushed to a repository
2. **Render Account**: Free account at [render.com](https://render.com)
3. **OpenRouter API Key**: From [openrouter.ai/keys](https://openrouter.ai/keys)
4. **Working Backend**: Test locally first with `python app.py`

---

## Step-by-Step Deployment

### Step 1: Push Code to GitHub

Ensure your repository is ready:

```bash
# Check current status
git status

# Make sure .env is NOT tracked
git ls-files | grep .env
# Should return nothing

# Commit any pending changes
git add .
git commit -m "Prepare for Render deployment"
git push origin main
```

**Verify these files exist:**
- ✅ `eduscan_backend/app.py`
- ✅ `eduscan_backend/requirements.txt`
- ✅ `eduscan_backend/.env.example`
- ✅ `.gitignore` (with `.env` listed)

### Step 2: Create Web Service on Render

1. **Log in to Render Dashboard**
   - Visit [dashboard.render.com](https://dashboard.render.com)
   - Sign in with GitHub (recommended)

2. **Create New Web Service**
   - Click **"New"** button (top right)
   - Select **"Web Service"**

3. **Connect Repository**
   - Find your `eduscan_ai` repository
   - Click **"Connect"**
   - If you don't see it, click "Configure account" and grant access

4. **Configure Service**

   | Setting | Value |
   |---------|-------|
   | **Name** | `eduscan-backend` (or your preferred name) |
   | **Environment** | Python 3 |
   | **Region** | Choose closest to your users (e.g., Oregon/US West) |
   | **Branch** | `main` (or your default branch) |
   | **Root Directory** | `eduscan_backend` |

5. **Build Command**
   ```bash
   pip install -r requirements.txt
   ```

6. **Start Command**
   ```bash
   gunicorn app:app
   ```

   > **Note:** Gunicorn is already in `requirements.txt`. It handles production WSGI serving.

7. **Select Plan**
   - Choose **"Free"** plan
   - Click **"Advanced"** to see more options (we'll configure those next)

### Step 3: Configure Environment Variables

Click **"Add Environment Variable"** for each:

#### Required Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `OPENROUTER_API_KEY` | `sk-or-v1-your-key-here` | Your OpenRouter API key |
| `PORT` | `10000` | Render's default port (automatically set, but good to specify) |

#### Optional Variables

| Variable Name | Value | Description |
|---------------|-------|-------------|
| `MODEL_ID` | `deepseek/deepseek-r1-0528-qwen3-8b:free` | AI model (default is free DeepSeek) |
| `ALLOWED_ORIGINS` | `*` | CORS origins (change in production) |
| `MAX_UPLOAD_MB` | `25` | Max file upload size |
| `MAX_PROMPT_CHARS` | `8000` | Max text sent to AI |
| `REQUEST_TIMEOUT_SECONDS` | `45` | API timeout |
| `FLASK_DEBUG` | `false` | Debug mode (never true in production) |

**Example Configuration:**

```bash
# Required
OPENROUTER_API_KEY=sk-or-v1-abc123def456ghi789

# Optional but recommended
MODEL_ID=deepseek/deepseek-r1-0528-qwen3-8b:free
ALLOWED_ORIGINS=*
MAX_UPLOAD_MB=25
MAX_PROMPT_CHARS=8000
REQUEST_TIMEOUT_SECONDS=45
FLASK_DEBUG=false
```

> **Security Tip:** Never share your `OPENROUTER_API_KEY`. Render encrypts environment variables.

### Step 4: Create Web Service

1. Review all settings
2. Click **"Create Web Service"**

**Render will:**
- Clone your repository
- Install Python dependencies
- Start the Flask application
- Provide a public URL

**Wait 2-3 minutes** for the initial deployment.

### Step 5: Verify Deployment

Once deployment is complete, you'll see:

```
Your service is live 🎉
URL: https://eduscan-backend.onrender.com
```

**Test the health endpoint:**

```bash
curl https://eduscan-backend.onrender.com/health
```

Expected response:
```json
{"status": "ok"}
```

**Test PDF processing** (optional):

```bash
curl -X POST \
  -F "pdf=@test.pdf" \
  https://eduscan-backend.onrender.com/summarize-pdf
```

Expected: JSON response with summary, flashcards, etc.

---

## Environment Variables

### Complete Reference

Copy this template for your Render environment variables:

```bash
# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

# OpenRouter API Key (get from https://openrouter.ai/keys)
OPENROUTER_API_KEY=sk-or-v1-your-key-here

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================

# AI Model to use
# Default: deepseek/deepseek-r1-0528-qwen3-8b:free (FREE)
# Options: google/gemini-flash-1.5, meta-llama/llama-3.1-8b-instruct
MODEL_ID=deepseek/deepseek-r1-0528-qwen3-8b:free

# OpenRouter API URL
# Default: https://openrouter.ai/api/v1/chat/completions
OPENROUTER_API_URL=https://openrouter.ai/api/v1/chat/completions

# CORS Allowed Origins
# For development: *
# For production: https://your-flutter-app.com,https://www.your-app.com
ALLOWED_ORIGINS=*

# Upload Limits
MAX_UPLOAD_MB=25
MAX_PROMPT_CHARS=8000

# Request Timeout (seconds)
REQUEST_TIMEOUT_SECONDS=45

# Server Port (Render sets automatically, but good to specify)
PORT=10000

# Debug Mode (NEVER true in production!)
FLASK_DEBUG=false
```

### Updating Environment Variables

1. Go to Render Dashboard
2. Select your service
3. Click **"Environment"** tab
4. Edit variables
5. Click **"Save Changes"**
6. Service will automatically restart

---

## Configuration Options

### CORS Configuration

**For Development (allow all):**
```bash
ALLOWED_ORIGINS=*
```

**For Production (restrict to your app):**
```bash
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

**For Multiple Environments:**
- Set to `*` for development/testing
- Specify exact domains for production

### Model Selection

**Free Development:**
```bash
MODEL_ID=deepseek/deepseek-r1-0528-qwen3-8b:free
```

**Production (if free tier insufficient):**
```bash
MODEL_ID=google/gemini-flash-1.5
```

**Premium Quality:**
```bash
MODEL_ID=anthropic/claude-3-haiku
```

> **Cost Note:** Paid models require credits in your OpenRouter account. Monitor usage at openrouter.ai/credits.

### Upload Limits

**Free Tier Limits:**
- 512 MB RAM (affects large PDF processing)
- Consider keeping `MAX_UPLOAD_MB` at 25 or lower
- Test with your typical PDF sizes

---

## Testing Your Deployment

### Health Check

```bash
curl https://your-service.onrender.com/health
```

### PDF Upload Test

```bash
# Create a small test PDF or use an existing one
curl -X POST \
  -F "pdf=@/path/to/test.pdf" \
  https://your-service.onrender.com/summarize-pdf
```

### Sakhi Chat Test

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello, can you help me study?"}' \
  https://your-service.onrender.com/ask-sakhi
```

### Article Fetch Test

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"url": "https://en.wikipedia.org/wiki/Flutter_(software)"}' \
  https://your-service.onrender.com/fetch-article
```

---

## Updating Your Deployment

### Automatic Deployments

Render automatically deploys when you push to the connected branch:

```bash
# Make changes
git add .
git commit -m "Update backend"
git push origin main

# Render automatically redeploys (takes ~2-3 minutes)
```

### Manual Deploy

1. Go to Render Dashboard
2. Select your service
3. Click **"Manual Deploy"**
4. Select **"Deploy latest commit"**

### Rollback

1. Go to Render Dashboard
2. Select your service
3. Click **"Logs"** tab
4. Find previous deployment
5. Click **"Rollback"**

---

## Troubleshooting

### "Service Unavailable" Error

**Cause:** Service is sleeping (free tier)

**Solution:**
- First request wakes the service (30-60 seconds)
- For production, upgrade to paid tier (no sleeping)
- Or use a ping service to keep it awake (see below)

**Keep-Alive Ping (Free Tier Workaround):**

Use a free cron job service like [cron-job.org](https://cron-job.org):

1. Create account at cron-job.org
2. Create new cron job
3. URL: `https://your-service.onrender.com/health`
4. Schedule: Every 10 minutes
5. This keeps your service awake 24/7

### "Failed to connect to AI service"

**Cause:** OpenRouter API key issue

**Solution:**
1. Verify `OPENROUTER_API_KEY` is set in Render environment variables
2. Check key is valid at openrouter.ai/keys
3. Restart service after updating variables

### "Could not read text from the uploaded PDF"

**Cause:** OCR dependencies missing or timeout

**Solution:**
1. Check Render logs for errors
2. Verify Tesseract is installed (included in `requirements.txt` dependencies)
3. Reduce `MAX_UPLOAD_MB` if files are too large
4. Check if PDF is scanned image or text-based

### Build Failures

**Check Render Logs:**
1. Go to Render Dashboard
2. Select your service
3. Click **"Logs"** tab
4. Look for error messages

**Common Issues:**

**Missing Dependencies:**
```
ModuleNotFoundError: No module named 'xxx'
```
**Solution:** Add to `requirements.txt` and redeploy

**Python Version:**
Render uses Python 3.11 by default (good for this project)

### Port Already in Use

**Cause:** Hardcoded port in code

**Solution:**
Ensure `app.py` uses:
```python
port = int(os.getenv("PORT", "5000"))
```

This is already correct in the codebase.

### CORS Errors

**Cause:** Frontend can't access backend

**Solution:**
1. Check `ALLOWED_ORIGINS` includes your frontend URL
2. For development, use `*`
3. For production, specify exact domains

**Flutter App Error:**
```
XMLHttpRequest error
```
**Fix:** Add your Render URL to `ALLOWED_ORIGINS`:
```bash
ALLOWED_ORIGINS=https://your-render-url.onrender.com,*,http://localhost:5000
```

---

## Production Considerations

### Security Checklist

- [ ] `.env` file is NOT in version control
- [ ] `OPENROUTER_API_KEY` is set as environment variable
- [ ] `FLASK_DEBUG=false` in production
- [ ] `ALLOWED_ORIGINS` restricted to known domains
- [ ] Firebase security rules properly configured
- [ ] No secrets in logs or error messages

### Performance Optimization

**Free Tier:**
- First request after sleep: ~30-60 seconds (cold start)
- Subsequent requests: ~1-3 seconds
- Large PDFs (>10MB) may timeout

**Upgrading to Paid:**
- No sleeping (always on)
- More RAM (1GB+)
- Faster CPU
- Custom domains
- Priority support

### Monitoring

**Render Dashboard:**
- CPU/RAM usage
- Request logs
- Error rates
- Deployment history

**OpenRouter Dashboard:**
- API usage
- Rate limits
- Credits remaining
- Model performance

### Scaling Options

**When to Upgrade:**
- Consistent traffic (no sleep delays acceptable)
- Large PDFs processing (need more RAM)
- High volume (many concurrent users)
- Production app with users

**Upgrade Path:**
1. Starter: $7/month (512MB RAM, always on)
2. Pro: $25/month (2GB RAM, faster CPU)
3. Custom: Contact Render

---

## Connecting Flutter App to Production Backend

### Update Backend URL

In your Flutter app, update the backend URL:

**Development:**
```bash
flutter run --dart-define=EDUSCAN_BACKEND_URL=http://127.0.0.1:5000
```

**Production:**
```bash
flutter run --dart-define=EDUSCAN_BACKEND_URL=https://your-service.onrender.com
```

### Build Release APK

```bash
flutter build apk --release \
  --dart-define=EDUSCAN_BACKEND_URL=https://your-service.onrender.com
```

### Environment-Specific Configuration

Create separate build configurations:

**lib/config/app_config.dart** (already exists):
```dart
class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'EDUSCAN_BACKEND_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );
}
```

---

## Summary

### Quick Deploy Checklist

- [ ] Code pushed to GitHub
- [ ] `.env` NOT in git (verified)
- [ ] Render account created
- [ ] Web service configured
- [ ] Environment variables set (`OPENROUTER_API_KEY`)
- [ ] Deploy button clicked
- [ ] Health check passed (`/health`)
- [ ] PDF upload tested
- [ ] Flutter app updated with new URL
- [ ] Production build created

### Your Deployment URL

After deployment, your backend will be at:

```
https://your-service-name.onrender.com
```

**Update your Flutter app:**
```bash
flutter run --dart-define=EDUSCAN_BACKEND_URL=https://your-service-name.onrender.com
```

---

## Getting Help

**Render Support:**
- Documentation: [render.com/docs](https://render.com/docs)
- Community: [community.render.com](https://community.render.com)
- Status: [status.render.com](https://status.render.com)

**OpenRouter Support:**
- Discord: [discord.gg/openrouter](https://discord.gg/openrouter)
- Documentation: [openrouter.ai/docs](https://openrouter.ai/docs)

**EduScan AI Issues:**
- GitHub Issues: [github.com/yourusername/eduscan_ai/issues](https://github.com/yourusername/eduscan_ai/issues)
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (if available)

---

**Your backend should now be live! 🚀**

Next steps:
1. Test with your Flutter app
2. Configure production Firebase (if not done)
3. Build and distribute your app
4. Monitor usage and scale as needed

Happy deploying!
