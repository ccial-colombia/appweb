-- =============================================================
-- Migración: foto en testimonios
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- 1) Agrega la columna foto_url a la tabla testimonios.
-- 2) Crea un bucket de almacenamiento público llamado "testimonios"
--    donde se guardarán las fotos subidas desde admin.html.
-- 3) Da permiso de lectura pública (para que la web las muestre) y
--    de escritura solo a usuarios autenticados (los administradores).
-- =============================================================

alter table public.testimonios
  add column if not exists foto_url text;

insert into storage.buckets (id, name, public)
values ('testimonios', 'testimonios', true)
on conflict (id) do nothing;

create policy "lectura publica fotos testimonios"
  on storage.objects for select
  using (bucket_id = 'testimonios');

create policy "admin sube fotos testimonios"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'testimonios');

create policy "admin actualiza fotos testimonios"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'testimonios')
  with check (bucket_id = 'testimonios');

create policy "admin elimina fotos testimonios"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'testimonios');
