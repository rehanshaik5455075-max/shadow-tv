-- Run in Supabase SQL Editor. Review before applying to a production project.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text,
 role text not null default 'user' check (role in ('user','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.anime (
 id uuid primary key default gen_random_uuid(),
 slug text unique not null,
 title text not null,
 synopsis text,
 release_year integer,
 status text not null default 'ongoing',
 poster_url text,
 cover_url text,
 is_published boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.genres (
 id uuid primary key default gen_random_uuid(),
 name text unique not null
);
create table if not exists public.anime_genres (
 anime_id uuid references public.anime(id) on delete cascade,
 genre_id uuid references public.genres(id) on delete cascade,
 primary key(anime_id,genre_id)
);
create table if not exists public.seasons (
 id uuid primary key default gen_random_uuid(),
 anime_id uuid not null references public.anime(id) on delete cascade,
 season_number integer not null,
 title text,
 unique(anime_id,season_number)
);
create table if not exists public.episodes (
 id uuid primary key default gen_random_uuid(),
 season_id uuid references public.seasons(id) on delete cascade,
 title text not null,
 description text,
 episode_number integer,
 duration_seconds integer,
 is_published boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.video_assets (
 id uuid primary key default gen_random_uuid(),
 episode_id uuid not null references public.episodes(id) on delete cascade,
 provider text not null check(provider in ('cloudflare_stream','mux')),
 provider_asset_id text not null,
 status text not null default 'processing',
 created_at timestamptz not null default now()
);
create table if not exists public.watchlists (
 user_id uuid references auth.users(id) on delete cascade,
 anime_id uuid references public.anime(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_id,anime_id)
);
create table if not exists public.watch_progress (
 user_id uuid references auth.users(id) on delete cascade,
 episode_id uuid references public.episodes(id) on delete cascade,
 position_seconds integer not null default 0,
 updated_at timestamptz not null default now(),
 primary key(user_id,episode_id)
);
alter table public.profiles enable row level security;
alter table public.anime enable row level security;
alter table public.genres enable row level security;
alter table public.anime_genres enable row level security;
alter table public.seasons enable row level security;
alter table public.episodes enable row level security;
alter table public.video_assets enable row level security;
alter table public.watchlists enable row level security;
alter table public.watch_progress enable row level security;
create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role='admin') $$;
create policy "read own profile" on public.profiles for select using (id=auth.uid() or public.is_admin());
create policy "update own profile" on public.profiles for update using (id=auth.uid()) with check (id=auth.uid() and role='user');
create policy "published anime visible" on public.anime for select using (is_published or public.is_admin());
create policy "admins manage anime" on public.anime for all using (public.is_admin()) with check (public.is_admin());
create policy "genres readable" on public.genres for select using (true);
create policy "admins manage genres" on public.genres for all using (public.is_admin()) with check (public.is_admin());
create policy "anime genre readable" on public.anime_genres for select using (true);
create policy "admins manage anime genres" on public.anime_genres for all using (public.is_admin()) with check (public.is_admin());
create policy "published seasons visible" on public.seasons for select using (public.is_admin() or exists(select 1 from public.anime a where a.id=anime_id and a.is_published));
create policy "admins manage seasons" on public.seasons for all using (public.is_admin()) with check (public.is_admin());
create policy "published episodes visible" on public.episodes for select using (is_published or public.is_admin());
create policy "admins manage episodes" on public.episodes for all using (public.is_admin()) with check (public.is_admin());
create policy "video metadata visible for published episodes" on public.video_assets for select using (public.is_admin() or exists(select 1 from public.episodes e where e.id=episode_id and e.is_published));
create policy "admins manage video assets" on public.video_assets for all using (public.is_admin()) with check (public.is_admin());
create policy "users manage own watchlist" on public.watchlists for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy "users manage own progress" on public.watch_progress for all using (user_id=auth.uid()) with check (user_id=auth.uid());
-- Create the first admin safely: sign up normally, then run this as project owner
-- after substituting the verified auth user's UUID:
-- update public.profiles set role='admin' where id='YOUR-AUTH-USER-UUID';
-- Add profile row trigger:
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,display_name) values(new.id, coalesce(new.raw_user_meta_data->>'display_name','')); return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();