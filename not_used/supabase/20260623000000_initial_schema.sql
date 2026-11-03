-- Initial Supabase schema for CCI AL Colombia.
-- Source documents: documents/BaseDatos.md and documents/Plan for CCI AL Colombia.md.

create extension if not exists pgcrypto;

do $$
begin
    create type public.user_role as enum ('superadmin', 'admin', 'editor', 'member');
exception
    when duplicate_object then null;
end $$;

do $$
begin
    create type public.course_category as enum ('curso', 'taller', 'eventos');
exception
    when duplicate_object then null;
end $$;

do $$
begin
    create type public.community_category as enum ('finca', 'transporte', 'juego', 'cocina', 'grafico');
exception
    when duplicate_object then null;
end $$;

do $$
begin
    create type public.section_type as enum ('hero', 'text', 'gallery', 'video', 'cards', 'testimonials', 'custom');
exception
    when duplicate_object then null;
end $$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null default '',
    role public.user_role not null default 'member',
    avatar_url text,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.site_settings (
    id uuid primary key default gen_random_uuid(),
    key text not null unique,
    value text,
    updated_at timestamptz not null default now(),
    updated_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.nav_items (
    id uuid primary key default gen_random_uuid(),
    parent_id uuid references public.nav_items(id) on delete cascade,
    label text not null,
    url text not null,
    is_external boolean not null default false,
    display_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint nav_items_label_url_unique unique (label, url)
);

create table if not exists public.social_links (
    id uuid primary key default gen_random_uuid(),
    platform text not null,
    url text not null,
    icon text,
    display_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint social_links_platform_url_unique unique (platform, url)
);

create table if not exists public.pages (
    id uuid primary key default gen_random_uuid(),
    slug text not null unique,
    title text not null,
    meta_description text,
    source_path text,
    requires_auth boolean not null default true,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.page_sections (
    id uuid primary key default gen_random_uuid(),
    page_id uuid not null references public.pages(id) on delete cascade,
    section_key text not null,
    section_type public.section_type not null default 'custom',
    title text,
    content jsonb not null default '{}'::jsonb,
    image_url text,
    display_order integer not null default 0,
    is_visible boolean not null default true,
    updated_at timestamptz not null default now(),
    updated_by uuid references public.profiles(id) on delete set null,
    constraint page_sections_page_key_unique unique (page_id, section_key)
);

create table if not exists public.courses (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    subtitle text,
    description text,
    image_url text,
    category public.course_category not null default 'curso',
    display_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint courses_title_category_unique unique (title, category)
);

create table if not exists public.products (
    id uuid primary key default gen_random_uuid(),
    name text not null,
    description text,
    price numeric(12, 2),
    currency text not null default 'COP',
    image_url text,
    is_available boolean not null default true,
    display_order integer not null default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint products_currency_check check (currency in ('COP', 'USD'))
);

create table if not exists public.community_resources (
    id uuid primary key default gen_random_uuid(),
    category public.community_category not null,
    title text not null,
    content text,
    contact_info text,
    location text,
    file_url text,
    display_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint community_resources_category_title_unique unique (category, title)
);

create table if not exists public.testimonials (
    id uuid primary key default gen_random_uuid(),
    author_name text not null,
    quote text not null,
    author_photo_url text,
    display_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.gallery_images (
    id uuid primary key default gen_random_uuid(),
    page_id uuid not null references public.pages(id) on delete cascade,
    section_name text not null default 'default',
    image_url text not null,
    alt_text text,
    caption text,
    display_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint gallery_images_page_section_image_unique unique (page_id, section_name, image_url)
);

create table if not exists public.video_embeds (
    id uuid primary key default gen_random_uuid(),
    page_id uuid not null references public.pages(id) on delete cascade,
    youtube_url text not null,
    title text,
    description text,
    display_order integer not null default 0,
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint video_embeds_page_url_unique unique (page_id, youtube_url)
);

create index if not exists idx_site_settings_key on public.site_settings(key);
create index if not exists idx_nav_items_parent_order on public.nav_items(parent_id, display_order) where is_active = true;
create index if not exists idx_social_links_order on public.social_links(display_order) where is_active = true;
create index if not exists idx_pages_slug_active on public.pages(slug) where is_active = true;
create index if not exists idx_page_sections_page_order on public.page_sections(page_id, display_order);
create index if not exists idx_courses_category_order on public.courses(category, display_order) where is_active = true;
create index if not exists idx_products_order on public.products(display_order) where is_available = true;
create index if not exists idx_community_category_order on public.community_resources(category, display_order) where is_active = true;
create index if not exists idx_testimonials_order on public.testimonials(display_order) where is_active = true;
create index if not exists idx_gallery_page_order on public.gallery_images(page_id, display_order) where is_active = true;
create index if not exists idx_videos_page_order on public.video_embeds(page_id, display_order) where is_active = true;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, full_name, avatar_url, role)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'full_name', ''),
        new.raw_user_meta_data ->> 'avatar_url',
        'member'
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

create or replace function public.get_my_role()
returns public.user_role
language sql
security definer
stable
set search_path = public
as $$
    select p.role
    from public.profiles p
    where p.id = auth.uid()
      and p.is_active = true;
$$;

create or replace function public.has_role(minimum_role public.user_role)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
    select coalesce(
        case minimum_role
            when 'member' then r.role in ('member', 'editor', 'admin', 'superadmin')
            when 'editor' then r.role in ('editor', 'admin', 'superadmin')
            when 'admin' then r.role in ('admin', 'superadmin')
            when 'superadmin' then r.role = 'superadmin'
            else false
        end,
        false
    )
    from (select public.get_my_role() as role) r;
$$;

create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if new.role is distinct from old.role then
        if auth.role() = 'service_role'
            or current_user in ('postgres', 'supabase_admin') then
            return new;
        end if;

        if not public.has_role('admin'::public.user_role) then
            raise exception 'Insufficient permissions to change user roles';
        end if;

        if old.role = 'superadmin'
            and not public.has_role('superadmin'::public.user_role) then
            raise exception 'Only a superadmin can change another superadmin';
        end if;

        if new.role in ('admin', 'superadmin')
            and not public.has_role('superadmin'::public.user_role) then
            raise exception 'Only a superadmin can assign admin or superadmin roles';
        end if;
    end if;

    return new;
end;
$$;

create or replace function public.set_user_role(target_user_id uuid, new_role public.user_role)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
    updated_profile public.profiles;
begin
    if coalesce(auth.role(), '') <> 'service_role'
        and current_user not in ('postgres', 'supabase_admin') then
        if not public.has_role('admin'::public.user_role) then
            raise exception 'Insufficient permissions to change user roles';
        end if;

        if new_role in ('admin', 'superadmin')
            and not public.has_role('superadmin'::public.user_role) then
            raise exception 'Only a superadmin can assign admin or superadmin roles';
        end if;
    end if;

    update public.profiles
    set role = new_role
    where id = target_user_id
    returning * into updated_profile;

    if updated_profile.id is null then
        raise exception 'Profile not found';
    end if;

    return updated_profile;
end;
$$;

create or replace function public.reorder_items(table_name text, ordered_ids uuid[])
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    allowed_tables constant text[] := array[
        'nav_items',
        'social_links',
        'page_sections',
        'courses',
        'products',
        'community_resources',
        'testimonials',
        'gallery_images',
        'video_embeds'
    ];
    item_id uuid;
    item_index integer := 0;
begin
    if not public.has_role('editor'::public.user_role) then
        raise exception 'Insufficient permissions to reorder items';
    end if;

    if table_name is null or not (table_name = any (allowed_tables)) then
        raise exception 'Unsupported table for reorder: %', table_name;
    end if;

    if ordered_ids is null then
        return;
    end if;

    foreach item_id in array ordered_ids loop
        execute format(
            'update public.%I set display_order = $1, updated_at = now() where id = $2',
            table_name
        ) using item_index, item_id;

        item_index := item_index + 1;
    end loop;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
    before update on public.profiles
    for each row execute function public.set_updated_at();

drop trigger if exists profiles_prevent_role_escalation on public.profiles;
create trigger profiles_prevent_role_escalation
    before update of role on public.profiles
    for each row execute function public.prevent_profile_role_escalation();

drop trigger if exists site_settings_updated_at on public.site_settings;
create trigger site_settings_updated_at
    before update on public.site_settings
    for each row execute function public.set_updated_at();

drop trigger if exists nav_items_updated_at on public.nav_items;
create trigger nav_items_updated_at
    before update on public.nav_items
    for each row execute function public.set_updated_at();

drop trigger if exists social_links_updated_at on public.social_links;
create trigger social_links_updated_at
    before update on public.social_links
    for each row execute function public.set_updated_at();

drop trigger if exists pages_updated_at on public.pages;
create trigger pages_updated_at
    before update on public.pages
    for each row execute function public.set_updated_at();

drop trigger if exists page_sections_updated_at on public.page_sections;
create trigger page_sections_updated_at
    before update on public.page_sections
    for each row execute function public.set_updated_at();

drop trigger if exists courses_updated_at on public.courses;
create trigger courses_updated_at
    before update on public.courses
    for each row execute function public.set_updated_at();

drop trigger if exists products_updated_at on public.products;
create trigger products_updated_at
    before update on public.products
    for each row execute function public.set_updated_at();

drop trigger if exists community_resources_updated_at on public.community_resources;
create trigger community_resources_updated_at
    before update on public.community_resources
    for each row execute function public.set_updated_at();

drop trigger if exists testimonials_updated_at on public.testimonials;
create trigger testimonials_updated_at
    before update on public.testimonials
    for each row execute function public.set_updated_at();

drop trigger if exists gallery_images_updated_at on public.gallery_images;
create trigger gallery_images_updated_at
    before update on public.gallery_images
    for each row execute function public.set_updated_at();

drop trigger if exists video_embeds_updated_at on public.video_embeds;
create trigger video_embeds_updated_at
    before update on public.video_embeds
    for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.site_settings enable row level security;
alter table public.nav_items enable row level security;
alter table public.social_links enable row level security;
alter table public.pages enable row level security;
alter table public.page_sections enable row level security;
alter table public.courses enable row level security;
alter table public.products enable row level security;
alter table public.community_resources enable row level security;
alter table public.testimonials enable row level security;
alter table public.gallery_images enable row level security;
alter table public.video_embeds enable row level security;

drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_authenticated"
    on public.profiles for select
    to authenticated
    using (true);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
    on public.profiles for update
    to authenticated
    using (id = auth.uid())
    with check (id = auth.uid());

drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin"
    on public.profiles for update
    to authenticated
    using (public.has_role('admin'::public.user_role))
    with check (public.has_role('admin'::public.user_role));

drop policy if exists "settings_select_public" on public.site_settings;
create policy "settings_select_public"
    on public.site_settings for select
    using (true);

drop policy if exists "settings_write_admin" on public.site_settings;
create policy "settings_write_admin"
    on public.site_settings for all
    to authenticated
    using (public.has_role('admin'::public.user_role))
    with check (public.has_role('admin'::public.user_role));

drop policy if exists "nav_select_public" on public.nav_items;
create policy "nav_select_public"
    on public.nav_items for select
    using (is_active = true);

drop policy if exists "nav_write_admin" on public.nav_items;
create policy "nav_write_admin"
    on public.nav_items for all
    to authenticated
    using (public.has_role('admin'::public.user_role))
    with check (public.has_role('admin'::public.user_role));

drop policy if exists "social_select_public" on public.social_links;
create policy "social_select_public"
    on public.social_links for select
    using (is_active = true);

drop policy if exists "social_write_admin" on public.social_links;
create policy "social_write_admin"
    on public.social_links for all
    to authenticated
    using (public.has_role('admin'::public.user_role))
    with check (public.has_role('admin'::public.user_role));

drop policy if exists "pages_select_public" on public.pages;
create policy "pages_select_public"
    on public.pages for select
    using (is_active = true and requires_auth = false);

drop policy if exists "pages_select_authenticated" on public.pages;
create policy "pages_select_authenticated"
    on public.pages for select
    to authenticated
    using (is_active = true);

drop policy if exists "pages_write_editor" on public.pages;
create policy "pages_write_editor"
    on public.pages for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

drop policy if exists "sections_select_public" on public.page_sections;
create policy "sections_select_public"
    on public.page_sections for select
    using (
        is_visible = true
        and exists (
            select 1
            from public.pages p
            where p.id = page_sections.page_id
              and p.is_active = true
              and p.requires_auth = false
        )
    );

drop policy if exists "sections_select_authenticated" on public.page_sections;
create policy "sections_select_authenticated"
    on public.page_sections for select
    to authenticated
    using (
        is_visible = true
        and exists (
            select 1
            from public.pages p
            where p.id = page_sections.page_id
              and p.is_active = true
        )
    );

drop policy if exists "sections_write_editor" on public.page_sections;
create policy "sections_write_editor"
    on public.page_sections for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

drop policy if exists "courses_select_active" on public.courses;
create policy "courses_select_active"
    on public.courses for select
    to authenticated
    using (is_active = true);

drop policy if exists "courses_write_editor" on public.courses;
create policy "courses_write_editor"
    on public.courses for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

drop policy if exists "products_select_available" on public.products;
create policy "products_select_available"
    on public.products for select
    to authenticated
    using (is_available = true);

drop policy if exists "products_write_editor" on public.products;
create policy "products_write_editor"
    on public.products for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

drop policy if exists "community_select_active" on public.community_resources;
create policy "community_select_active"
    on public.community_resources for select
    to authenticated
    using (is_active = true);

drop policy if exists "community_write_editor" on public.community_resources;
create policy "community_write_editor"
    on public.community_resources for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

drop policy if exists "testimonials_select_active" on public.testimonials;
create policy "testimonials_select_active"
    on public.testimonials for select
    to authenticated
    using (is_active = true);

drop policy if exists "testimonials_write_editor" on public.testimonials;
create policy "testimonials_write_editor"
    on public.testimonials for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

drop policy if exists "gallery_select_active" on public.gallery_images;
create policy "gallery_select_active"
    on public.gallery_images for select
    to authenticated
    using (is_active = true);

drop policy if exists "gallery_write_editor" on public.gallery_images;
create policy "gallery_write_editor"
    on public.gallery_images for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

drop policy if exists "videos_select_active" on public.video_embeds;
create policy "videos_select_active"
    on public.video_embeds for select
    to authenticated
    using (is_active = true);

drop policy if exists "videos_write_editor" on public.video_embeds;
create policy "videos_write_editor"
    on public.video_embeds for all
    to authenticated
    using (public.has_role('editor'::public.user_role))
    with check (public.has_role('editor'::public.user_role));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    (
        'media',
        'media',
        false,
        5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf']
    ),
    (
        'avatars',
        'avatars',
        true,
        2097152,
        array['image/jpeg', 'image/png', 'image/webp']
    )
on conflict (id) do update
set
    name = excluded.name,
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

--alter table storage.objects enable row level security;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
    (
        'media',
        'media',
        false,
        5242880,
        array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf']
    ),
    (
        'avatars',
        'avatars',
        true,
        2097152,
        array['image/jpeg', 'image/png', 'image/webp']
    )
on conflict (id) do update
set
    name = excluded.name,
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "media_read_authenticated" on storage.objects;

create policy "media_read_authenticated"
    on storage.objects for select
    to authenticated
    using (bucket_id = 'media');

drop policy if exists "media_upload_editor" on storage.objects;
create policy "media_upload_editor"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'media'
        and public.has_role('editor'::public.user_role)
    );

drop policy if exists "media_update_editor" on storage.objects;
create policy "media_update_editor"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'media'
        and public.has_role('editor'::public.user_role)
    )
    with check (
        bucket_id = 'media'
        and public.has_role('editor'::public.user_role)
    );

drop policy if exists "media_delete_admin" on storage.objects;
create policy "media_delete_admin"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'media'
        and public.has_role('admin'::public.user_role)
    );

drop policy if exists "avatars_read_public" on storage.objects;
create policy "avatars_read_public"
    on storage.objects for select
    to anon, authenticated
    using (bucket_id = 'avatars');

drop policy if exists "avatars_upload_own" on storage.objects;
create policy "avatars_upload_own"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own"
    on storage.objects for update
    to authenticated
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    )
    with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

drop policy if exists "avatars_delete_own" on storage.objects;
create policy "avatars_delete_own"
    on storage.objects for delete
    to authenticated
    using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

grant usage on schema public to anon, authenticated, service_role;
grant select on
    public.site_settings,
    public.nav_items,
    public.social_links,
    public.pages,
    public.page_sections
to anon;

grant select, insert, update, delete on all tables in schema public to authenticated;
grant all on all tables in schema public to service_role;

revoke execute on function public.set_user_role(uuid, public.user_role) from public, anon;
grant execute on function public.set_user_role(uuid, public.user_role) to authenticated, service_role;

revoke execute on function public.reorder_items(text, uuid[]) from public, anon;
grant execute on function public.reorder_items(text, uuid[]) to authenticated;
