# Beastly Point Tap — Deployment Guide

## Get Supabase credentials
1. https://supabase.com/dashboard → your project
2. Project Settings → API
3. Copy **Project URL** and **anon public** (or `sb_publishable_...`) key

Never copy the service_role key.

## Apply schema
Run `beastly-schema.sql` in the Supabase SQL Editor.

## Deploy wallet-auth edge function
```bash
supabase functions deploy wallet-auth
```

## Configure front-end
Set before loading scripts:
```html
<script>
  window.SUPABASE_URL = 'https://YOUR_PROJECT.supabase.co';
  window.SUPABASE_ANON_KEY = 'your_anon_or_publishable_key';
</script>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="beastly-supabase-client.js"></script>
```

## Deploy to Vercel
Connect this repo in the Vercel dashboard for automatic deploys on push to main.

Current live URL: https://beastly-point-tap-kyariball2910-8168s-projects.vercel.app
