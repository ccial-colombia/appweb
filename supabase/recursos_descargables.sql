-- =============================================================
-- Equipados: 3. Recursos descargables (PDF)
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
-- Requiere: secciones_visibilidad.sql y contenido_secciones.sql
--
-- Crea la tabla public.descargables. equipados.html la muestra en la
-- sección "3. Recursos descargables" y se administra desde admin.html,
-- en la pestaña "Recursos descargables".
--
--   categoria    -> grupo en el que aparece en la página:
--                     'isl'    = ISL (Ideas Sin Límite)
--                     'juegos' = Enciclopedia de Juegos Creadores de Ambiente
--   titulo       -> nombre del recurso
--   descripcion  -> texto corto; los saltos de línea se respetan
--   archivo_url  -> URL pública del PDF. El panel lo sube al bucket
--                   "descargables"; también sirve una ruta del sitio.
--   tamano_bytes -> tamaño del PDF (lo guarda el panel al subirlo)
--   imagen_url   -> portada opcional (bucket "contenido", carpeta
--                   descargables/). Sin portada se muestra un ícono de PDF.
--   orden        -> orden dentro de su grupo (menor primero)
--   visible      -> false = el recurso no aparece en la web
--
-- Para agregar otra categoría hay que cambiar el CHECK de esta tabla,
-- las opciones del campo "Tipo" en admin.html y agregar su grupo
-- (data-categoria) en equipados.html.
--
-- Se puede ejecutar más de una vez: no duplica la tabla, las políticas,
-- el bucket ni los textos, y no pisa lo que se haya editado en el panel.
-- =============================================================

create table if not exists public.descargables (
  id serial primary key,
  categoria text not null default 'isl'
    constraint descargables_categoria_check check (categoria in ('isl', 'juegos')),
  titulo text not null,
  descripcion text,
  archivo_url text not null,
  tamano_bytes integer check (tamano_bytes is null or tamano_bytes >= 0),
  imagen_url text,
  orden int not null default 0,
  visible boolean not null default true
);

-- ---------- Seguridad ----------
-- La web (anon key) solo lee los recursos visibles.
-- Los administradores (usuarios autenticados) pueden hacer todo.

alter table public.descargables enable row level security;

drop policy if exists "lectura publica" on public.descargables;
create policy "lectura publica" on public.descargables
  for select using (visible = true);

drop policy if exists "admin total" on public.descargables;
create policy "admin total" on public.descargables
  for all to authenticated using (true) with check (true);

-- ---------- Archivos PDF ----------
-- Bucket público "descargables", solo para PDF. El tamaño máximo de cada
-- archivo es el límite global del proyecto (50 MB en el plan gratuito;
-- se cambia en Storage > Settings).

insert into storage.buckets (id, name, public, allowed_mime_types)
values ('descargables', 'descargables', true, array['application/pdf'])
on conflict (id) do update set
  public = true,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "descargables lectura publica" on storage.objects;
create policy "descargables lectura publica"
  on storage.objects for select
  using (bucket_id = 'descargables');

drop policy if exists "descargables admin total" on storage.objects;
create policy "descargables admin total"
  on storage.objects for all
  to authenticated
  using (bucket_id = 'descargables')
  with check (bucket_id = 'descargables');

-- ---------- Portadas ----------
-- Van al bucket público "contenido" (el de cursos, talleres y productos;
-- ver cursos_talleres.sql). Se repite aquí por si aún no existe.

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

-- ---------- Sección y textos de equipados.html ----------
-- La sección se puede ocultar desde "Secciones de la web" y sus textos se
-- editan en "Contenido de secciones". Si la clave ya existe solo se
-- actualizan página, título y orden (se respeta "visible").

insert into public.informacion_general (pagina, clave, titulo, orden, visible) values
  ('equipados.html', 'equipados.descargables', '3. Recursos descargables', 6, true),
  ('equipados.html', 'equipados.descargables_titulo', 'Recursos descargables · título', 6, true),
  ('equipados.html', 'equipados.descargables_texto', 'Recursos descargables · texto', 6, true),
  ('equipados.html', 'equipados.descargables_isl_titulo', 'Recursos descargables · título ISL', 6, true),
  ('equipados.html', 'equipados.descargables_juegos_titulo', 'Recursos descargables · título Enciclopedia de Juegos', 6, true)
on conflict (clave) do update set
  pagina = excluded.pagina,
  titulo = excluded.titulo,
  orden  = excluded.orden;

insert into public.contenido_secciones (seccion_clave, contenido) values
  ('equipados.descargables_titulo', '<p><strong>3. Recursos descargables</strong></p>'),
  ('equipados.descargables_texto', '<p>Aquí encontrarás diferentes recursos que puedes descargar, ISL (Ideas Sin Límite) que te ayudarán a tener actividades para diferentes circunstancias. También encontrarás algunos juegos de nuestra Enciclopedia de Juegos Creadores de Ambiente.</p>'),
  ('equipados.descargables_isl_titulo', '<p>ISL · Ideas Sin Límite</p>'),
  ('equipados.descargables_juegos_titulo', '<p>Enciclopedia de Juegos Creadores de Ambiente</p>')
on conflict (seccion_clave) do nothing;
