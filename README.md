# SHADOW TV — starter project

Responsive anime-catalog/PWA frontend with Supabase Auth, Postgres, RLS and private video storage.

## Important status
This is a deployable starter, not a live hosted service. You must connect a Supabase project, configure Google OAuth, run the SQL, and deploy the files. It intentionally ships with no anime videos. Upload only content and artwork you are legally authorized to distribute.

## 1. Create backend
1. Create a project at https://supabase.com/.
2. Open **SQL Editor** and run `supabase/schema.sql`.
3. In **Project Settings → API**, copy Project URL and anon/public key.
4. In `app.js`, replace `YOUR_SUPABASE_PROJECT_URL` and `YOUR_SUPABASE_ANON_KEY`. The anon key is intended for browser use with RLS enabled. Never use a service-role key in frontend code.
5. In Authentication → Providers, enable Google and configure the OAuth client in Google Cloud Console. Add the site URL and callback URL shown by Supabase to the authorized redirect URIs. Add your deployed site URL to Supabase Auth URL configuration.
6. Use the Google account `rehanshaik5455074@gmail.com` for the owner. Verify that account's email in Google/Supabase Auth. The owner check is exact-email plus verified-email, and RLS checks it again.

## 2. Deploy frontend
You can deploy this folder to Netlify, Vercel, or another static host. For Netlify, create a new site from the folder/repository; publish directory is the project root. HTTPS is required for production OAuth and PWA behavior. No build command is needed.

## 3. Test security before publishing
- Sign in as the owner and confirm upload works.
- Sign in with a different verified Google account; confirm it cannot insert/update/delete rows or upload/delete objects.
- Test direct REST calls, not only hidden buttons.
- Do not create any broad storage read policy. This starter uses short-lived signed URLs for browser playback; for public viewing, deploy the `episode-url` Edge Function and update `app.js` to request a URL from it rather than minting signed URLs directly from the client.
- Before real production use, move all video URL minting into the Edge Function, add rate limits and upload validation, and verify the `email_verified` claim for your Supabase Auth provider/version. Policies deliberately fail closed if the claim is absent.
- Test deletion cleanup and database/storage consistency. Consider a scheduled cleanup for orphaned objects.

## 4. Playback endpoint integration
In `app.js`, `openAnime()` currently calls `createSignedUrl` in the browser for a quick starter experience. For a production privacy boundary, replace that block with:
```js
const { data: { session } } = await supabase.auth.getSession();
const { data, error } = await supabase.functions.invoke('episode-url', {
  body: { anime_id: activeAnime.id },
  headers: { Authorization: `Bearer ${session.access_token}` }
});
videoUrl = error ? '' : (data?.url || '');
```
Deploy the function with `supabase functions deploy episode-url`. Anonymous viewing is not enabled by this endpoint; if anonymous playback is desired, adapt it deliberately using a server-side public-episode allowlist and abuse controls.

## Included
- Mobile responsive dark anime UI, search and category filters
- Google OAuth sign-in
- Owner dashboard form, episode metadata, upload and delete controls
- 1–5 star ratings for signed-in users
- Supabase SQL schema and RLS/storage restrictions
- PWA manifest and icon
- No payment, UPI, QR or subscription features

## Production caveat
A static frontend alone cannot securely enforce authorization. The database/storage policies are the security boundary; review and test them with your own project and provider claims before launching.
