-- =============================================================
-- Limpieza: elimina las tablas que la aplicación NO usa
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Estas tablas vienen de un esquema inicial que nunca se conectó
-- (ahora en not_used/supabase/: 20260623000000_initial_schema.sql y
-- seed.sql). Ni las páginas ni admin.html las leen ni las escriben:
--
--   profiles, site_settings, social_links, pages, products,
--   testimonials, video_embeds
--   (y nav_items, page_sections, courses, community_resources,
--    gallery_images, que ya no existen pero se incluyen por si acaso)
--
-- Con ellas se eliminan también sus funciones (has_role, get_my_role,
-- set_user_role, reorder_items, handle_new_user, ...), sus tipos
-- (user_role, course_category, community_category, section_type) y
-- el trigger on_auth_user_created de auth.users, que escribía en
-- "profiles": si se borrara la tabla y quedara el trigger, crear un
-- usuario administrador nuevo fallaría.
--
-- Datos que se pierden: site_settings (9 filas), social_links (4) y
-- pages (1) son copias de textos y enlaces que ya están en el HTML.
-- Si quieres guardarlos, ejecuta antes el bloque "Respaldo".
--
-- Tablas que la aplicación SÍ usa (no se tocan):
--   psw_change (+ función validar_password), informacion_general,
--   contenido_secciones, imagenes_sitio, productos, fincas,
--   transporte, juegos, cocina, graficos, testimonios, cursos,
--   talleres, videos
-- =============================================================

-- ---------- Respaldo (opcional) ----------
-- Ejecútalo solo y copia el resultado antes de borrar:
--
-- select 'site_settings' as tabla, to_jsonb(t) as fila from public.site_settings t
-- union all select 'social_links', to_jsonb(t) from public.social_links t
-- union all select 'pages', to_jsonb(t) from public.pages t
-- union all select 'profiles', to_jsonb(t) from public.profiles t;

begin;

-- 1) Trigger de auth.users que creaba una fila en profiles por usuario.
drop trigger if exists on_auth_user_created on auth.users;

-- 2) Tablas sin uso. "cascade" borra también sus políticas, triggers,
--    índices y las referencias entre ellas.
drop table if exists
  public.video_embeds,
  public.gallery_images,
  public.page_sections,
  public.nav_items,
  public.pages,
  public.site_settings,
  public.social_links,
  public.products,
  public.testimonials,
  public.courses,
  public.community_resources,
  public.profiles
cascade;

-- 3) Políticas de Storage de los buckets "media" y "avatars" (usaban has_role).
drop policy if exists "media_read_authenticated" on storage.objects;
drop policy if exists "media_upload_editor"      on storage.objects;
drop policy if exists "media_update_editor"      on storage.objects;
drop policy if exists "media_delete_admin"       on storage.objects;
drop policy if exists "avatars_read_public"      on storage.objects;
drop policy if exists "avatars_upload_own"       on storage.objects;
drop policy if exists "avatars_update_own"       on storage.objects;
drop policy if exists "avatars_delete_own"       on storage.objects;

-- 4) Funciones y tipos del esquema inicial. Cada uno se borra por
--    separado: si algo inesperado aún depende de él, se avisa con un
--    NOTICE y se deja, en vez de cancelar toda la limpieza.
do $$
declare
  objeto record;
begin
  for objeto in
    select * from (values
      ('function', 'public.handle_new_user()'),
      ('function', 'public.set_user_role(uuid, public.user_role)'),
      ('function', 'public.reorder_items(text, uuid[])'),
      ('function', 'public.prevent_profile_role_escalation()'),
      ('function', 'public.has_role(public.user_role)'),
      ('function', 'public.get_my_role()'),
      ('function', 'public.set_updated_at()'),
      ('type',     'public.user_role'),
      ('type',     'public.course_category'),
      ('type',     'public.community_category'),
      ('type',     'public.section_type')
    ) as t(tipo, nombre)
  loop
    begin
      execute format('drop %s if exists %s', objeto.tipo, objeto.nombre);
    exception
      when undefined_object or undefined_function then
        null; -- ya no existía
      when dependent_objects_still_exist then
        raise notice 'No se borró % % porque otro objeto lo usa.', objeto.tipo, objeto.nombre;
    end;
  end loop;
end $$;

commit;

-- 5) Buckets "media" y "avatars" (no los usa la aplicación). Supabase
--    no siempre permite borrarlos con SQL; si aparece el aviso, bórralos
--    en Storage desde el Dashboard (deben estar vacíos).
do $$
begin
  delete from storage.buckets b
  where b.id in ('media', 'avatars')
    and not exists (select 1 from storage.objects o where o.bucket_id = b.id);
exception
  when others then
    raise notice 'Borra los buckets media y avatars desde Storage en el Dashboard (%).', sqlerrm;
end $$;

-- ---------- Comprobación ----------
-- Debe devolver solo las 14 tablas que usa la aplicación.
select table_name
from information_schema.tables
where table_schema = 'public' and table_type = 'BASE TABLE'
order by table_name;
