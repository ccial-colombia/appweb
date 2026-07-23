-- =============================================================
-- Backend de administración para CCI AL/Colombia
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- 1) Crea las tablas nuevas: cursos, talleres, videos e
--    informacion_general (todas con lectura pública).
-- 2) Da permiso TOTAL (crear/editar/eliminar) sobre TODAS las
--    tablas a los usuarios autenticados (los administradores que
--    crees en Authentication > Users).
--
-- IMPORTANTE después de ejecutar esto:
--   a) Authentication > Users > Add user: crea el usuario admin
--      (correo y contraseña) con "Auto Confirm User" activado.
--   b) Authentication > Sign In / Providers: DESACTIVA
--      "Allow new users to sign up" para que nadie más pueda
--      registrarse y obtener permisos de administración.
-- =============================================================

-- ---------- Tablas nuevas de contenido ----------

-- Ver también: cursos_talleres.sql (migración de la estructura anterior
-- y bucket "contenido" donde se guardan las imágenes).
create table if not exists public.cursos (
  id serial primary key,
  imagen_url text,           -- imagen subida desde el panel
  nombre text not null,
  descripcion_corta text,    -- frase breve que acompaña al nombre
  descripcion text,
  orden int default 0,
  visible boolean default true
);

create table if not exists public.talleres (
  id serial primary key,
  imagen_url text,
  nombre text not null,
  descripcion_corta text,
  descripcion text,
  orden int default 0,
  visible boolean default true
);

create table if not exists public.videos (
  id serial primary key,
  titulo text not null,
  url text not null,         -- enlace de YouTube o Vimeo
  descripcion text,
  orden int default 0,
  visible boolean default true
);

-- Secciones visuales de cada página (y textos generales editables).
-- Cada fila es una parte de una página que se puede habilitar o
-- deshabilitar desde el panel de administración.
-- Ver también: secciones_visibilidad.sql (catálogo de secciones).
create table if not exists public.informacion_general (
  id serial primary key,
  pagina text,                  -- archivo html, ej: 'comunidad.html'
  clave text unique not null,   -- identificador usado en data-seccion, ej: 'comunidad.fincas'
  titulo text,                  -- nombre de la sección en el panel
  contenido text,
  orden int default 0,
  visible boolean not null default true
);

alter table public.cursos               enable row level security;
alter table public.talleres             enable row level security;
alter table public.videos               enable row level security;
alter table public.informacion_general  enable row level security;

create policy "lectura publica" on public.cursos              for select using (true);
create policy "lectura publica" on public.talleres            for select using (true);
create policy "lectura publica" on public.videos              for select using (true);
create policy "lectura publica" on public.informacion_general for select using (true);

-- ---------- Permisos de administración ----------
-- Los usuarios autenticados pueden hacer TODO en todas las tablas.
-- El público (anon) conserva solo lectura, y en psw_change ni eso.

create policy "admin total" on public.fincas              for all to authenticated using (true) with check (true);
create policy "admin total" on public.transporte          for all to authenticated using (true) with check (true);
create policy "admin total" on public.juegos              for all to authenticated using (true) with check (true);
create policy "admin total" on public.cocina              for all to authenticated using (true) with check (true);
create policy "admin total" on public.graficos            for all to authenticated using (true) with check (true);
create policy "admin total" on public.testimonios         for all to authenticated using (true) with check (true);
create policy "admin total" on public.cursos              for all to authenticated using (true) with check (true);
create policy "admin total" on public.talleres            for all to authenticated using (true) with check (true);
create policy "admin total" on public.videos              for all to authenticated using (true) with check (true);
create policy "admin total" on public.informacion_general for all to authenticated using (true) with check (true);
create policy "admin total" on public.psw_change          for all to authenticated using (true) with check (true);
