# Vercel Deployment Guide for Campus Docs

## Overview

Campus Docs is now configured for deployment on Vercel. This guide covers the setup and deployment process.

## What's Been Set Up

1. **vercel.json** - Build configuration for Flutter web
2. **.vercelignore** - Excludes unnecessary files (native builds, etc.)
3. **api/assign-admin.js** - Vercel Serverless Function for admin role assignment
4. **.env.example** - Environment variables template

## Prerequisites

- Flutter installed and configured
- Vercel account ([vercel.com](https://vercel.com))
- Supabase project with URL and API keys
- Git repository

## Deployment Steps

### 1. Prepare Environment Variables

Set up the following environment variables in your Vercel project:

**In Vercel Dashboard:**
- Go to Project Settings → Environment Variables
- Add the following:
  - `SUPABASE_URL`: Your Supabase project URL
  - `SUPABASE_ANON_KEY`: Your Supabase anon key
  - `SERVICE_ROLE_KEY`: Your Supabase service role key (for serverless functions only)

### 2. Deploy to Vercel

**Option A: Using Vercel Dashboard**
1. Push your code to a Git repository (GitHub, GitLab, Bitbucket)
2. Go to [vercel.com](https://vercel.com) and click "New Project"
3. Select your repository
4. Set the following in Build settings:
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`
5. Add environment variables from Step 1
6. Click "Deploy"

**Option B: Using Vercel CLI**
```bash
# Install Vercel CLI
npm i -g vercel

# Login to Vercel
vercel login

# Deploy
vercel --prod
```

### 3. Configure API Routes

The serverless function is available at:
```
https://your-domain.vercel.app/api/assign-admin
```

**Usage Example:**
```bash
curl -X POST https://your-domain.vercel.app/api/assign-admin \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user-uuid-here"}'
```

### 4. Update Flutter App

Update your Flutter app to point to the new API endpoint:

```dart
// In your Flutter code
final response = await http.post(
  Uri.parse('https://your-domain.vercel.app/api/assign-admin'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'user_id': userId}),
);
```

## Important Notes

### Requirements

- **Node.js**: Vercel requires Node.js 18+ for serverless functions
- **Flutter**: The build process requires Flutter to be available (Vercel provides this in their build environment)
- **Supabase**: This project uses Supabase for backend, ensure your Supabase project is properly configured

### File Structure

```
Campus-Docs-main/
├── vercel.json          # Vercel configuration
├── .vercelignore        # Files to exclude from deployment
├── .env.example         # Environment variables template
├── api/
│   └── assign-admin.js  # Serverless function
├── web/                 # Flutter web build target
├── lib/                 # Flutter Dart code
├── pubspec.yaml         # Flutter dependencies
└── build/web/           # (Generated during build)
```

### Build Time

The initial deployment may take 10-15 minutes because:
- Flutter SDK needs to be downloaded
- Dependencies need to be resolved
- Web assets need to be compiled

Subsequent deployments will be faster due to caching.

## Troubleshooting

### Build Fails - Flutter Not Found
- Vercel automatically provides Flutter, but ensure your build command is correct
- The `vercel.json` has the correct build command configured

### API Function Returns 500 Error
- Check that `SERVICE_ROLE_KEY` environment variable is set
- Verify Supabase connection and credentials
- Check Vercel function logs for detailed error messages

### Static Files Not Loading
- Ensure the output directory in `vercel.json` is set to `build/web`
- The rewrite rule should handle SPA routing correctly

## Security

- **Never commit `.env.local`** - Use Vercel's environment variables
- Use Supabase's **Service Role Key** only for serverless functions
- Keep **Anon Key** for client-side operations only
- Restrict RLS (Row Level Security) policies in Supabase appropriately

## Useful Links

- [Vercel Docs](https://vercel.com/docs)
- [Flutter Web on Vercel](https://vercel.com/guides/deploying-flutter-with-vercel)
- [Supabase Documentation](https://supabase.com/docs)
- [Vercel CLI Reference](https://vercel.com/docs/cli)

## Next Steps

1. Push changes to your Git repository
2. Connect repository to Vercel
3. Set environment variables in Vercel dashboard
4. Deploy and test
5. Update Flutter app with the new API endpoint
6. Monitor logs and test all features

---

For issues or questions, check Vercel's dashboard logs or contact support.
