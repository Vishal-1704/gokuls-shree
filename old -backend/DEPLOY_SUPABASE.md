# Supabase Deployment Guide

Deploy the Gokul Shree backend using **Supabase** - a powerful free alternative with PostgreSQL, Auth, and Edge Functions.

## 🎯 Why Supabase?

| Feature | Supabase Free Tier |
|---------|-------------------|
| **Database** | 500 MB PostgreSQL |
| **Auth** | Unlimited users |
| **Storage** | 1 GB |
| **Edge Functions** | 500K invocations/month |
| **Bandwidth** | 2 GB/month |
| **No Cold Starts** | Always-on database |

---

## 🚀 Option 1: Use Supabase as Database Only

Keep your Express backend (on Render) but use Supabase for the PostgreSQL database.

### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up with GitHub (free)
3. Click **"New Project"**
4. Fill in:
   - **Name**: `gokul-shree`
   - **Database Password**: Generate a strong password (save it!)
   - **Region**: Choose closest to your users
5. Wait for project to be created (~2 minutes)

### Step 2: Get Connection String

1. Go to **Settings** → **Database**
2. Scroll to **Connection string** → **URI**
3. Copy the connection string:
   ```
   postgresql://postgres:<YOUR_DATABASE_PASSWORD>@db.<YOUR_PROJECT_REF>.supabase.co:5432/postgres
   ```

### Step 3: Update Render Environment

Add this as `DATABASE_URL` in your Render dashboard.

---

## 🚀 Option 2: Full Supabase (Recommended)

Replace the Express backend entirely with Supabase's built-in features.

### Benefits:
- ✅ No server to deploy/maintain
- ✅ Built-in JWT authentication
- ✅ Real-time subscriptions
- ✅ Auto-generated REST API
- ✅ Row Level Security (RLS)

### Step 1: Create Tables via Supabase Dashboard

Go to **SQL Editor** and run:

```sql
-- Students table
CREATE TABLE students (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  registration_number VARCHAR(50) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(20),
  course_id INTEGER,
  session_year VARCHAR(20),
  photo_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable Supabase Auth connection
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

-- Courses table
CREATE TABLE courses (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL,
  duration VARCHAR(50),
  eligibility VARCHAR(255),
  description TEXT,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notices table
CREATE TABLE notices (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  category VARCHAR(50),
  attachment_url TEXT,
  is_active BOOLEAN DEFAULT true,
  published_at TIMESTAMP DEFAULT NOW()
);

-- Downloads table
CREATE TABLE downloads (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  file_type VARCHAR(50),
  file_size VARCHAR(20),
  download_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert sample courses
INSERT INTO courses (title, category, duration, eligibility) VALUES
('Advance Diploma In Computer Application (ADCA)', 'Diploma', '1 Year', '12th Pass'),
('Diploma In Computer Application (DCA)', 'Diploma', '6 Months', '10th Pass'),
('Certificate In Python (CIP)', 'Diploma', '3 Months', '12th Pass'),
('Diploma in Fashion Designing (DFD)', 'Vocational', '1 Year', '10th Pass'),
('Diploma In Yoga Teacher Training (DYTT)', 'Yoga', '1 Year', '12th Pass'),
('Bachelor of Computer Application (BCA)', 'University', '3 Years', '12th Pass');

-- Insert notices
INSERT INTO notices (title, category) VALUES
('CCC, BCC & O LEVEL - ADMISSION OPEN', 'admission'),
('New Session 2025-26 Registration Started', 'admission'),
('O-Level Examination Schedule Released', 'exam');
```

### Step 2: Update Flutter App for Supabase

Install Supabase Flutter SDK:

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.3.0
```

Initialize in `main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );
  
  runApp(const ProviderScope(child: MyApp()));
}
```

Create Supabase service:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final client = Supabase.instance.client;

  // Get courses
  Future<List<Map<String, dynamic>>> getCourses() async {
    final response = await client
        .from('courses')
        .select()
        .eq('is_active', true)
        .order('title');
    return List<Map<String, dynamic>>.from(response);
  }

  // Login with registration number
  Future<AuthResponse> login(String email, String password) {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Get notices
  Future<List<Map<String, dynamic>>> getNotices() async {
    final response = await client
        .from('notices')
        .select()
        .eq('is_active', true)
        .order('published_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}
```

---

## 🔧 Supabase Credentials

Find your credentials in Supabase Dashboard:

1. Go to **Settings** → **API**
2. Copy:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public** key: `eyJhbG...` (safe for client apps)

---

## 📊 Comparison: Express vs Supabase

| Feature | Express + Render | Supabase Only |
|---------|-----------------|---------------|
| **Setup Time** | 30 min | 10 min |
| **Cold Starts** | Yes (free tier) | No |
| **Custom Logic** | Full control | Edge Functions |
| **Auth** | Manual JWT | Built-in |
| **Real-time** | Manual (Socket.io) | Built-in |
| **Cost** | Free | Free |
| **Scalability** | Good | Excellent |

---

## 🎯 Recommended Approach

For **Gokul Shree School App**:

1. **Use Supabase as database** (replace Neon)
2. **Keep Express backend on Render** (for custom business logic)
3. **Later migrate to full Supabase** when comfortable

This gives you the reliability of Supabase's always-on database while keeping your custom API flexibility.
