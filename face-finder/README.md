# FaceFinder — Free Face Search iOS App

Find anyone's social media profiles by taking their photo. Powered by Yandex, Google, and Bing reverse image search — all **completely free**, no paid APIs.

## Architecture

```
iOS App (SwiftUI) → Backend (Node.js) → Yandex + Google + Bing
       ↓                   ↓
  Camera/Gallery      Aggregates results
  Shows results       Filters social media URLs
```

## Setup

### 1. Backend (free on Render/Railway)

```bash
cd backend
npm install
npm start
```

The server starts on `http://localhost:3000`. No API keys are needed — Yandex and Google work for free. For Bing (optional), get a free key at https://portal.azure.com → Create Cognitive Services.

### 2. iOS App

Open in Xcode on macOS:

1. Open Xcode → File → New → Project → iOS → App (SwiftUI)
2. Name it **FaceFinder**, bundle ID `com.facefinder.app`
3. Replace all generated files with the files in `ios/SocialFinder/`
4. Add `Info.plist` to the project
5. Build to your iPhone (or use Sideloadly with the .ipa)

### 3. Configure

In the app, tap the gear icon and enter your backend server URL (e.g., `http://192.168.1.100:3000` for local, or your Render URL for production).

## Deploy Backend for Free

**Option A: Render.com (easiest)**

1. Push `backend/` to a GitHub repo
2. Go to https://dashboard.render.com → New Web Service
3. Connect repo, set start command: `npm start`
4. Free tier includes 512MB RAM, sleeps after inactivity

**Option B: Railway.app**

1. Push `backend/` to GitHub
2. Go to https://railway.app → New Project → Deploy from repo
3. Auto-detects Node.js, just set start command

## Sideloading with Sideloadly

1. Build the app in Xcode with a free Apple ID
2. Export as .ipa (Product → Archive → Distribute → Development)
3. Use Sideloadly on Windows to install the .ipa to your iPhone

## How It Works

| Engine   | Free? | API Key? | Searches |
|----------|-------|----------|----------|
| Yandex   | ✅    | ❌ None  | Unlimited |
| Google   | ✅    | ❌ None  | Unlimited |
| Bing     | ✅    | Optional | 1000/mo free tier |

## Tech Stack

- **iOS**: SwiftUI, URLSession, PHPicker, AVFoundation
- **Backend**: Node.js, Express, Cheerio, Axios
- **Search**: Yandex reverse image search, Google Images, Bing Visual Search
