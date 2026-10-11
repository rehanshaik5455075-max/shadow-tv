# Shadow TV — Premium Anime Streaming Starter

A responsive Next.js + TypeScript starter for **Shadow TV — Enter the World of Anime**. It includes a bright cream/lavender visual system, home page, searchable catalog, detail pages, an MP4/HLS demo player, Supabase email authentication, SQL schema/RLS policies, and an admin upload flow using Cloudflare Stream direct uploads.

## Requirements
- Node.js 20+
- A Supabase project
- A Cloudflare account with Stream enabled for real video uploads
- Rights to distribute every video and image you publish

## Run locally
1. Extract this folder and run `npm install`.
2. Copy `.env.example` to `.env.local`.
3. Fill in the Supabase project URL and anon key. Keep `SUPABASE_SERVICE_ROLE_KEY` and `CLOUDFLARE_STREAM_TOKEN` server-only; never prefix them with `NEXT_PUBLIC_`.
4. In Supabase SQL Editor, run `supabase/schema.sql`.
5. In Supabase Auth settings, configure your local and production redirect URLs.
6. Run `npm run dev` and open `http://localhost:3000`.

The site can be explored without backend credentials. Authentication and protected uploads need the Supabase setup.

## Cloudflare Stream upload
The admin page requests a short-lived direct-upload URL from `/api/admin/stream-upload`. That server route checks the current Supabase user and their `profiles.role` before asking Cloudflare for an upload URL. The Cloudflare API token stays on the server. Direct uploads use the provider's resumable/direct upload workflow; check current Cloudflare Stream upload requirements and maximum duration/size limits for your account.

**Important production work before opening uploads to users:**
- Add rate limits and request-size limits at the edge.
- Enforce allowed MIME type, maximum file size and duration server-side/provider-side.
- Persist provider webhook status changes; verify webhook signatures before updating `video_assets.status`.
- Link each episode to a season and validate the episode relationship before accepting upload requests.
- Use signed/allowed-origin playback URLs or tokenized playback for private content.
- Add a dedicated server-side playback endpoint that checks subscription/entitlement before issuing playback tokens.
- Add robust upload progress UI and retry/resume behavior. Browser direct upload behavior varies by provider and account configuration.
- Add CSRF/origin checks and security monitoring appropriate to your deployment.
- Build complete CRUD screens for anime/seasons/episodes, poster and subtitle management, and audit logs.

## Demo data and media
Sample titles and remote landscape imagery are for layout demonstration. They are not a licensed streaming catalog, and the player intentionally starts without a video URL. Paste a stream URL you own or have permission to use. For production, use licensed artwork and a dedicated video host such as Cloudflare Stream or Mux.

## Admin setup
1. Create an account through `/signup`.
2. Find the matching user in Supabase Authentication and copy their UUID.
3. As project owner, run `update public.profiles set role='admin' where id='YOUR-AUTH-USER-UUID';` in SQL Editor.
4. Sign in and open `/admin`.

The browser page checks the user's profile for usability; the upload API independently verifies the same role server-side. Do not give admin roles to untrusted users.

## Deploy to Vercel
1. Push the project to a private/public Git repository you control.
2. Import it in Vercel as a Next.js project.
3. Add the environment variables from `.env.example` in Vercel Project Settings. Keep service-role and Cloudflare tokens server-only.
4. Add the Vercel production URL to Supabase Auth redirect settings.
5. Configure provider webhooks and production playback restrictions before publishing episodes.
6. Deploy and test auth, RLS, admin denial for normal users, upload processing, playback, mobile layout, and error states.

## Current scope
This is a functional **starter project**, not a fully production-hardened streaming service. Catalog records currently use local sample data; the Supabase schema is provided for migrating to database-backed catalog queries. My List, durable watch progress, subtitle tracks, pagination from the database, and complete content CRUD remain implementation tasks. The admin route includes a real authenticated upload URL request path but should not be exposed publicly until the production safeguards above are completed.
