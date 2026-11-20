-- =============================================================
-- El Punto: revista virtual con artículos (elpunto.html y articulo.html)
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
-- Requiere: secciones_visibilidad.sql, contenido_secciones.sql e
--           imagenes_sitio.sql
--
-- Crea la tabla public.articulos, con una estructura parecida a la de
-- testimonios. elpunto.html muestra los artículos en tarjetas, del más
-- nuevo al más viejo según la fecha de ingreso, y articulo.html?id=...
-- muestra un artículo completo. Se administran desde admin.html, en la
-- pestaña "El Punto".
--
--   titulo        -> título del artículo
--   autor         -> quién lo escribe (opcional)
--   rol           -> iglesia, ministerio o cargo del autor (opcional)
--   foto_url      -> foto del autor (bucket "contenido", carpeta
--                    articulos/). Opcional.
--   contenido     -> el artículo, con formato (editor del panel)
--   fecha_ingreso -> fecha del artículo. Se muestra en la página y
--                    define el orden: el más nuevo primero. Por defecto,
--                    el día en que se crea (hora de Colombia).
--   visible       -> false = el artículo no aparece en la web
--
-- A diferencia de testimonios no hay columna "orden": el orden lo da la
-- fecha de ingreso (si dos artículos tienen la misma fecha, primero el
-- último que se agregó).
--
-- También registra la página elpunto.html en "Secciones de la web",
-- sus textos en "Contenido de secciones" y el logo de la revista en
-- "Imágenes del sitio".
--
-- Se puede ejecutar más de una vez: no duplica la tabla, las políticas
-- ni los textos, y no pisa lo que se haya editado en el panel.
-- =============================================================

create table if not exists public.articulos (
  id serial primary key,
  titulo text not null,
  autor text,
  rol text,
  foto_url text,
  contenido text not null,
  fecha_ingreso date not null default ((now() at time zone 'America/Bogota')::date),
  visible boolean not null default true
);

create index if not exists idx_articulos_fecha_ingreso
  on public.articulos (fecha_ingreso desc, id desc);

-- ---------- Seguridad ----------
-- La web (anon key) solo lee los artículos visibles.
-- Los administradores (usuarios autenticados) pueden hacer todo.

alter table public.articulos enable row level security;

drop policy if exists "lectura publica" on public.articulos;
create policy "lectura publica" on public.articulos
  for select using (visible = true);

drop policy if exists "admin total" on public.articulos;
create policy "admin total" on public.articulos
  for all to authenticated using (true) with check (true);

-- ---------- Fotos de los autores ----------
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

-- ---------- Secciones y textos de elpunto.html ----------
-- Las secciones se pueden ocultar desde "Secciones de la web" y los
-- textos se editan en "Contenido de secciones". Si la clave ya existe
-- solo se actualizan página y título (se respetan "orden" y "visible").

insert into public.informacion_general (pagina, clave, titulo, orden, visible) values
  ('elpunto.html', 'elpunto.encabezado', 'Logo e introducción', 1, true),
  ('elpunto.html', 'elpunto.introduccion', 'Introducción (texto)', 1, true),
  ('elpunto.html', 'elpunto.articulos', 'Artículos', 2, true),
  ('elpunto.html', 'elpunto.articulos_titulo', 'Artículos · título', 2, true)
on conflict (clave) do update set
  pagina = excluded.pagina,
  titulo = excluded.titulo;

insert into public.contenido_secciones (seccion_clave, contenido) values
  ('elpunto.introduccion', '<p>El Punto es la revista virtual de CCI AL/Colombia. Aquí encontrarás artículos, reflexiones y experiencias para quienes sirven en el ministerio de campamentos.</p>'),
  ('elpunto.articulos_titulo', '<p><strong>Artículos</strong></p>')
on conflict (seccion_clave) do nothing;

-- ---------- Logo de la revista ----------
-- Se cambia desde "Imágenes del sitio". Mientras no se suba uno, la
-- página muestra assets/images/elpunto-logo.svg.

insert into public.imagenes_sitio (pagina, clave, titulo, imagen_url, alt, orden) values
  ('elpunto.html', 'elpunto.logo', 'Logo de El Punto', 'assets/images/elpunto-logo.svg', 'El Punto, revista virtual de CCI AL/Colombia', 1)
on conflict (clave) do update set
  pagina = excluded.pagina,
  titulo = excluded.titulo,
  orden  = excluded.orden;
