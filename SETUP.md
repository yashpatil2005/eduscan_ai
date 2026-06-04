# EduScan AI - Complete Setup Guide

This guide walks you through setting up EduScan AI from scratch. Follow these steps in order for a successful installation.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [OpenRouter Setup](#openrouter-setup)
3. [Backend Setup](#backend-setup)
4. [Flutter Setup](#flutter-setup)
5. [Firebase Setup](#firebase-setup-optional)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have the following installed:

### Required Software

| Software | Minimum Version | Download Link |
|----------|----------------|---------------|
| Flutter SDK | 3.8.0 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | 3.0.0 | Included with Flutter |
| Python | 3.10 | [python.org](https://www.python.org/downloads/) |
| Git | Latest | [git-scm.com](https://git-scm.com/) |

### System-Specific Requirements

#### Windows
- **Tesseract OCR**: Download from [tesseract-ocr GitHub](https://github.com/UB-Mannheim/tesseract/wiki)
- **Ghostscript**: Required by OCRmyPDF
- **Visual C++ Redistributable**: May be required for some Python packages

#### macOS
```bash
# Install using Homebrew
brew install tesseract
brew install ghostscript
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install -y tesseract-ocr ghostscript
```

### Verify Installations

```bash
# Check Flutter
flutter doctor

# Check Python
python --version

# Check Tesseract
tesseract --version
```

---

## OpenRouter Setup

EduScan AI uses [OpenRouter](https://openrouter.ai/) to access AI models for generating study materials. This is a **required** step.

### Step 1: Create OpenRouter Account

1. Visit [https://openrouter.ai/](https://openrouter.ai/)
2. Click **"Sign Up"** in the top right
3. Choose your preferred sign-up method:
   - **Option A**: Email and password
   - **Option B**: Google account (recommended for faster setup)
4. Complete the registration process
5. Verify your email if required

### Step 2: Generate API Key

1. Log in to OpenRouter dashboard
2. Click **"Keys"** in the left sidebar
3. Click the **"Create Key"** button
4. Enter a descriptive name:
   - Example: `EduScan AI Development`
   - Example: `EduScan AI Production`
5. Click **"Create"**
6. **⚠️ IMPORTANT**: Copy the API key immediately!
   - The key starts with `sk-or-v1-`
   - You won't be able to see the full key again
   - Store it securely (you'll paste it into `.env` shortly)

### Step 3: Choose Your AI Model

EduScan AI works with multiple AI models. We recommend starting with the **free DeepSeek model**.

| Model | Cost | Speed | Quality | Best For | Model ID |
|-------|------|-------|---------|----------|----------|
| **DeepSeek R1** | **FREE** | Fast | Good | Development & Testing | `deepseek/deepseek-r1-0528-qwen3-8b:free` |
| Gemini Flash 1.5 | Free tier | Very Fast | Excellent | Production | `google/gemini-flash-1.5` |
| Llama 3.1 8B | Free tier | Fast | Good | Balanced | `meta-llama/llama-3.1-8b-instruct` |
| Claude 3 Haiku | Paid | Fast | Excellent | Premium | `anthropic/claude-3-haiku` |

**Our recommendation**: Start with the free DeepSeek model. You can change it later in the `.env` file.

---

## Backend Setup

### Step 1: Navigate to Backend Directory

```bash
cd eduscan_backend
```

### Step 2: Create Virtual Environment

**Windows:**
```bash
python -m venv .venv
.venv\Scripts\activate
```

**macOS/Linux:**
```bash
python3 -m venv .venv
source .venv/bin/activate
```

You should see `(.venv)` in your terminal prompt, indicating the virtual environment is active.

### Step 3: Install Dependencies

```bash
pip install -r requirements.txt
```

This installs:
- Flask (web framework)
- OCRmyPDF & Tesseract (OCR processing)
- PyMuPDF (PDF handling)
- OpenRouter API client (via requests)
- YouTube Search API
- And other required packages

### Step 4: Configure Environment Variables

1. Copy the example environment file:

**Windows:**
```bash
copy .env.example .env
```

**macOS/Linux:**
```bash
cp .env.example .env
```

2. Open `.env` in your favorite text editor

3. Replace the placeholder with your actual OpenRouter API key:

```bash
# Before:
OPENROUTER_API_KEY=replace_with_your_openrouter_key

# After (example):
OPENROUTER_API_KEY=sk-or-v1-abc123def456ghi789jkl012mno345pqr
```

4. **Verify other settings** (optional):
   - `MODEL_ID`: Use default or change to another model from the table above
   - `MAX_UPLOAD_MB`: Default 25MB is usually sufficient
   - `PORT`: Default 5000 is fine for local development

### Step 5: Start the Backend

```bash
python app.py
```

You should see output like:
```
 * Serving Flask app 'app'
 * Debug mode: off
 * Running on http://127.0.0.1:5000
```

**Keep this terminal window open** - the backend needs to keep running!

### Step 6: Test the Backend

Open a new terminal and run:

```bash
curl http://127.0.0.1:5000/health
```

Expected response:
```json
{"status": "ok"}
```

✅ **Backend is now running!**

---

## Flutter Setup

### Step 1: Install Dependencies

In a new terminal, navigate to the project root:

```bash
# Make sure you're in the eduscan_ai directory, not eduscan_backend
cd ..

# Install Flutter dependencies
flutter pub get
```

This downloads all Flutter packages specified in `pubspec.yaml`.

### Step 2: Verify Flutter Setup

```bash
flutter doctor
```

Ensure:
- ✅ Flutter SDK is installed
- ✅ Android toolchain is configured (for Android)
- ✅ Xcode is configured (for iOS/macOS)
- ✅ Connected device or emulator is available

### Step 3: Configure Backend URL

The app needs to know where your backend is running. By default, it looks for the backend at `http://127.0.0.1:5000`.

For local development:
```bash
flutter run --dart-define=EDUSCAN_BACKEND_URL=http://127.0.0.1:5000
```

**For physical Android devices:**

If testing on a physical Android device, use your computer's local IP instead of `127.0.0.1`:

```bash
# Find your IP address first:
# Windows: ipconfig
# macOS/Linux: ifconfig or ip addr

# Then run with your actual IP:
flutter run --dart-define=EDUSCAN_BACKEND_URL=http://192.168.1.100:5000
```

### Step 4: Run the App

**Option A: With hot reload (development)**
```bash
flutter run --dart-define=EDUSCAN_BACKEND_URL=http://127.0.0.1:5000
```

**Option B: Build and install (Android)**
```bash
flutter build apk --debug --dart-define=EDUSCAN_BACKEND_URL=http://127.0.0.1:5000
```

The app should launch on your device/emulator with:
- Login screen with Google Sign-In button
- Home dashboard
- Add Notes functionality

---

## Firebase Setup (Optional)

Firebase is **optional** for local development but **recommended** for:
- User authentication
- Cloud storage of note metadata
- Cross-device sync

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Create a project"**
3. Enter project name (e.g., `eduscan-ai-dev`)
4. Choose whether to enable Google Analytics (optional)
5. Click **"Create project"**

### Step 2: Add Android App

1. In Firebase Console, click the Android icon (**</>**)
2. Enter package name: `com.example.eduscan_ai`
3. Enter app nickname: `EduScan AI Android`
4. Click **"Register app"**
5. Download `google-services.json`

### Step 3: Configure Firebase in Project

1. Place the downloaded `google-services.json` in:
   ```
   android/app/google-services.json
   ```

2. **⚠️ IMPORTANT**: This file contains sensitive API keys. It should already be ignored by `.gitignore`.

3. Verify `.gitignore` includes:
   ```
   android/app/google-services.json
   ```

### Step 4: Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click **"Get started"**
3. Enable **Google** sign-in method
4. Configure OAuth consent screen (follow prompts)

### Step 5: Enable Firestore

1. Go to **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
4. Select a location closest to you
5. Click **"Enable"**

### Step 6: Set Up Firestore Security Rules

Replace default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own notes
    match /notes/{noteId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## Verification

After completing all setup steps, verify everything works:

### 1. Backend Verification

```bash
curl http://127.0.0.1:5000/health
# Expected: {"status": "ok"}
```

### 2. Test PDF Upload (Optional)

You can test the backend API directly:

```bash
# Create a simple test PDF or use an existing one
curl -X POST -F "pdf=@test.pdf" http://127.0.0.1:5000/summarize-pdf
```

Expected: JSON response with summary, flashcards, etc.

### 3. Flutter App Verification

1. Launch the app
2. Sign in with Google (if Firebase configured)
3. Navigate to "Add Notes"
4. Upload a small PDF file
5. You should see the Loading screen with animation
6. After processing, see the AI Summary screen with:
   - Generated summary
   - Concept map button
   - Flashcards button
   - Related YouTube videos

### 4. Check Logs

**Backend logs** should show:
- File received
- OCR processing
- AI API call
- Response sent

**Flutter logs** should show:
- No errors
- Successful HTTP requests
- JSON parsing successful

---

## Troubleshooting

### OpenRouter Issues

#### "AI service is not configured" error
**Cause**: `OPENROUTER_API_KEY` not set or invalid

**Solution**:
1. Check `.env` file exists in `eduscan_backend/`
2. Verify key starts with `sk-or-v1-`
3. Restart backend after editing `.env`
4. Test with curl: `curl http://localhost:5000/health`

#### "Failed to connect to AI service" error
**Cause**: Network issues or OpenRouter down

**Solution**:
1. Check internet connection
2. Visit [OpenRouter status](https://openrouter.ai/)
3. Try again in a few minutes

#### "503 Service Unavailable" error
**Cause**: OpenRouter service temporarily down

**Solution**:
1. Check [OpenRouter Discord](https://discord.gg/openrouter) for status updates
2. Wait and retry
3. Consider switching to a different model

#### Rate limit exceeded
**Cause**: Free tier has rate limits

**Solution**:
1. Wait for rate limit reset (usually 1 minute)
2. Upgrade to paid tier for higher limits
3. Switch to a different free model

### Backend Issues

#### OCR failures
**Cause**: Tesseract or Ghostscript not installed

**Solution**:
- **Windows**: Reinstall Tesseract and add to PATH
- **macOS**: `brew install tesseract ghostscript`
- **Linux**: `sudo apt-get install tesseract-ocr ghostscript`

#### "No module named 'xxx'" errors
**Cause**: Dependencies not installed

**Solution**:
```bash
cd eduscan_backend
pip install -r requirements.txt
```

#### Port already in use
**Cause**: Another service using port 5000

**Solution**:
```bash
# Option 1: Use different port
PORT=5001 python app.py

# Option 2: Kill existing process (Linux/macOS)
lsof -ti:5000 | xargs kill -9
```

### Flutter Issues

#### "Failed to connect to backend"
**Cause**: Backend not running or wrong URL

**Solution**:
1. Verify backend is running on port 5000
2. Check firewall/antivirus isn't blocking connections
3. For physical devices, use your computer's IP, not `127.0.0.1`

#### Build errors
**Cause**: Outdated Flutter or missing dependencies

**Solution**:
```bash
flutter clean
flutter pub get
flutter doctor  # Fix any issues
```

#### Firebase configuration errors
**Cause**: Missing or invalid `google-services.json`

**Solution**:
1. Download fresh `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`
3. Clean and rebuild:
   ```bash
   cd android
   ./gradlew clean  # macOS/Linux
   gradlew clean    # Windows
   cd ..
   flutter clean
   flutter pub get
   ```

### Platform-Specific Issues

#### Windows: "python" not recognized
**Solution**: Use `python` instead of `python3`, or add Python to PATH

#### macOS: Permission denied errors
**Solution**: Use `sudo` for system-wide installs, or use `--user` flag:
```bash
pip install --user -r requirements.txt
```

#### Linux: Tesseract not found
**Solution**:
```bash
sudo apt-get install tesseract-ocr
sudo apt-get install tesseract-ocr-eng  # English language pack
```

---

## Next Steps

Once everything is working:

1. **Explore the features**:
   - Upload PDFs and images
   - Generate study packs
   - Use Sakhi AI chat
   - Create timetable
   - Set up notifications

2. **Customize the app**:
   - Modify themes in `lib/utils/constants.dart`
   - Add custom fonts to `pubspec.yaml`
   - Configure notification timing

3. **Deploy the backend**:
   - See [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment

4. **Contribute**:
   - Read [CONTRIBUTING.md](CONTRIBUTING.md)
   - Check out [ARCHITECTURE.md](ARCHITECTURE.md) for code structure

---

## Getting Help

If you encounter issues not covered here:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) (if available)
2. Search [existing issues](https://github.com/yourusername/eduscan_ai/issues)
3. Open a new issue with:
   - Your operating system
   - Flutter/Python versions
   - Error messages
   - Steps to reproduce

---

**You're all set! Happy studying with EduScan AI! 📚✨**
