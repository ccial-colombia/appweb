-- ============================================================
-- Contenido de las secciones de la web
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Asocia cada sección del sitio (fila de informacion_general) con un
-- texto con formato que se edita desde el panel con un editor embebido.
--
--   seccion_clave -> clave de la sección (informacion_general.clave)
--   contenido     -> HTML con formato escrito en el editor del panel
--
-- Una sola fila de contenido por sección (seccion_clave es único).
-- Requiere que informacion_general ya exista y tenga la columna "clave".
-- ============================================================

create table if not exists public.contenido_secciones (
  id serial primary key,
  seccion_clave text not null unique
    references public.informacion_general(clave) on delete cascade,
  contenido text,
  updated_at timestamptz not null default now()
);

create index if not exists idx_contenido_secciones_clave
  on public.contenido_secciones (seccion_clave);

alter table public.contenido_secciones enable row level security;

drop policy if exists "lectura publica" on public.contenido_secciones;
create policy "lectura publica"
  on public.contenido_secciones for select
  using (true);

drop policy if exists "admin total" on public.contenido_secciones;
create policy "admin total"
  on public.contenido_secciones for all
  to authenticated
  using (true)
  with check (true);
