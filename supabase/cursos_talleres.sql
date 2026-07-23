-- ============================================================
-- Cursos y Talleres: nueva estructura
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Campos finales de public.cursos y public.talleres:
--   imagen_url        -> imagen del curso/taller (se sube desde el panel)
--   nombre            -> antes se llamaba "titulo"
--   descripcion_corta -> frase breve que acompaña al nombre
--   descripcion       -> texto completo
--   orden             -> orden en que se muestra
--   visible           -> true = se muestra en la web
--
-- OJO: se eliminan las columnas "enlace" y "fecha"; si tienen datos
-- que quieras conservar, cópialos antes de ejecutar este script.
-- ============================================================

do $$
declare
  tabla text;
begin
  foreach tabla in array array['cursos', 'talleres'] loop

    -- "titulo" pasa a llamarse "nombre" (conserva los datos existentes)
    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = tabla and column_name = 'titulo'
    ) and not exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = tabla and column_name = 'nombre'
    ) then
      execute format('alter table public.%I rename column titulo to nombre', tabla);
    end if;

    execute format('alter table public.%I add column if not exists nombre text', tabla);
    execute format('alter table public.%I add column if not exists imagen_url text', tabla);
    execute format('alter table public.%I add column if not exists descripcion_corta text', tabla);
    execute format('alter table public.%I add column if not exists descripcion text', tabla);
    execute format('alter table public.%I add column if not exists orden int default 0', tabla);
    execute format('alter table public.%I add column if not exists visible boolean default true', tabla);

    execute format('alter table public.%I drop column if exists enlace', tabla);
    execute format('alter table public.%I drop column if exists fecha', tabla);

    execute format('alter table public.%I alter column nombre set not null', tabla);

  end loop;
end $$;

-- ---------- Imágenes de cursos y talleres ----------
-- Bucket público donde el panel sube las imágenes, en las carpetas
-- "cursos/" y "talleres/". Si prefieres crearlo desde el dashboard:
-- Storage > New bucket > nombre "contenido" > Public.

insert into storage.buckets (id, name, public)
values ('contenido', 'contenido', true)
on conflict (id) do update set public = true;

drop policy if exists "contenido lectura publica" on storage.objects;
create policy "contenido lectura publica"
  on storage.objects for select
  using (bucket_id = 'contenido');

drop policy if exists "contenido admin total" on storage.objects;
create policy "contenido admin total"
  on storage.objects for all
  to authenticated
  using (bucket_id = 'contenido')
  with check (bucket_id = 'contenido');
