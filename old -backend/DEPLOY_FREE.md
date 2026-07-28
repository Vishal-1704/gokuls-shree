# Free Hosting Deployment Guide

This guide shows how to deploy the Gokul Shree backend for **FREE** using:
- **Render.com** - Free Node.js hosting
- **Neon.tech** - Free PostgreSQL database

---

## 🗄️ Step 1: Create Free PostgreSQL Database (Neon)

1. Go to [https://neon.tech](https://neon.tech)
2. Sign up with GitHub (free)
3. Click **"Create a project"**
   - Project name: `gokul-shree`
   - Region: Choose closest to your users
4. After creation, copy the **Connection String**:
   ```
   postgresql://username:password@ep-xxx.region.aws.neon.tech/neondb?sslmode=require
   ```
5. Save this - you'll need it for Render!

---

## 🚀 Step 2: Deploy to Render (Free)

### Option A: Deploy via GitHub (Recommended)

1. Push your code to GitHub:
   ```bash
   cd backend
   git init
   git add .
   git commit -m "Initial backend"
   git remote add origin https://github.com/YOUR_USERNAME/gokul-shree-backend.git
   git push -u origin main
   ```

2. Go to [https://render.com](https://render.com)
3. Sign up with GitHub (free)
4. Click **"New +"** → **"Web Service"**
5. Connect your GitHub repository
6. Configure:
   - **Name**: `gokul-shree-api`
   - **Region**: Oregon (Free)
   - **Branch**: `main`
   - **Root Directory**: `backend` (if backend is in subfolder)
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Plan**: **Free**

7. Add Environment Variables:
   | Key | Value |
   |-----|-------|
   | `DATABASE_URL` | Your Neon connection string |
   | `JWT_SECRET` | Generate a random string (use: `openssl rand -hex 32`) |
   | `JWT_EXPIRES_IN` | `7d` |
   | `NODE_ENV` | `production` |
   | `API_VERSION` | `v1` |

8. Click **"Create Web Service"**

---

## 🔧 Step 3: Run Database Migrations

After deployment, open the **Shell** tab in Render dashboard and run:

```bash
npm run db:migrate
npm run db:seed
```

---

## 🌐 Step 4: Update Flutter App

After deployment, Render gives you a URL like:
```
https://gokul-shree-api.onrender.com
```

Update your Flutter app's API client:

**File: `lib/src/core/services/api_client.dart`**
```dart
class ApiConfig {
  // Production URL from Render
  static const String baseUrl = 'https://gokul-shree-api.onrender.com/api/v1';
  
  // ... rest of config
}
```

---

## ✅ Step 5: Test the API

Test your deployed API:

```bash
# Health check
curl https://gokul-shree-api.onrender.com/health

# Get courses
curl https://gokul-shree-api.onrender.com/api/v1/courses

# Login
curl -X POST https://gokul-shree-api.onrender.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"registrationNumber":"12345","password":"password"}'
```

---

## 💡 Free Tier Limits

### Render Free Tier:
- ✅ 750 hours/month (plenty for one service)
- ✅ Auto-deploy on git push
- ⚠️ Spins down after 15 min inactivity (cold start ~30s)
- ⚠️ No custom domains on free tier

### Neon Free Tier:
- ✅ 0.5 GB storage
- ✅ 3 GB data transfer/month
- ✅ Unlimited databases
- ⚠️ Auto-suspend after 5 min inactivity (resume ~1-2s)

---

## 🔄 Alternative Free Options

| Service | Type | Free Tier |
|---------|------|-----------|
| [Railway](https://railway.app) | Full Stack | $5 credit/month |
| [Fly.io](https://fly.io) | Containers | 3 VMs free |
| [Supabase](https://supabase.com) | PostgreSQL + Auth | 500MB DB |
| [PlanetScale](https://planetscale.com) | MySQL | 1 DB, 1GB |
| [Vercel](https://vercel.com) | Serverless | Unlimited |

---

## 🐛 Troubleshooting

### "Connection refused" error
- Check DATABASE_URL is correct
- Ensure `?sslmode=require` is in the connection string

### "Cold start" slow response
- Free tier spins down after inactivity
- First request after sleep takes 30-60 seconds
- Consider pinging the health endpoint periodically

### Database not seeded
- Open Render Shell and run `npm run db:seed`
