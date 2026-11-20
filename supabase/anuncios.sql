-- =============================================================
-- Anuncios (index.html e inicio.html)
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
-- Requiere: secciones_visibilidad.sql y contenido_secciones.sql
--
-- Crea la tabla public.anuncios. index.html muestra los anuncios
-- vigentes en un carrusel junto con la imagen de bienvenida
-- (index.portada), que siempre es la primera. inicio.html los muestra
-- en la sección "Anuncios", al final de la página, sin la imagen de
-- bienvenida (si no hay anuncios vigentes, la sección no aparece).
-- Se administran desde admin.html, en la pestaña "Anuncios".
--
--   imagen_url   -> imagen del anuncio (bucket "contenido", carpeta
--                   anuncios/). Conviene el mismo formato que la imagen
--                   de bienvenida (1600 x 753 px) para que llene el espacio.
--   titulo       -> nombre del anuncio; también es el texto alternativo
--                   de la imagen (no se muestra encima)
--   enlace       -> opcional: al hacer clic en el anuncio se abre este
--                   enlace en una pestaña nueva (https://... o mailto:...)
--   fecha_inicio -> primer día en que se muestra (desde las 00:00)
--   fecha_fin    -> último día en que se muestra (hasta las 23:59)
--   orden        -> orden en los carruseles (menor primero)
--   visible      -> false = no se muestra aunque esté en fechas
--
-- Las fechas se cuentan en hora de Colombia (America/Bogota). La propia
-- base solo entrega a la web los anuncios visibles y en fechas: un
-- anuncio vencido o futuro no llega al navegador, sin importar el reloj
-- del visitante.
--
-- Se puede ejecutar más de una vez: no duplica la tabla, las políticas
-- ni los textos, y no pisa lo que se haya editado en el panel.
-- =============================================================

create table if not exists public.anuncios (
  id serial primary key,
  imagen_url text not null,
  titulo text not null,
  enlace text,
  fecha_inicio date not null default ((now() at time zone 'America/Bogota')::date),
  fecha_fin date not null,
  orden int not null default 0,
  visible boolean not null default true,
  constraint anuncios_fechas_check check (fecha_fin >= fecha_inicio)
);

-- ---------- Seguridad ----------
-- La web (anon key) solo lee los anuncios visibles y vigentes hoy.
-- Los administradores (usuarios autenticados) pueden hacer todo.

alter table public.anuncios enable row level security;

drop policy if exists "lectura publica" on public.anuncios;
create policy "lectura publica" on public.anuncios
  for select using (
    visible = true
    and (now() at time zone 'America/Bogota')::date between fecha_inicio and fecha_fin
  );

drop policy if exists "admin total" on public.anuncios;
create policy "admin total" on public.anuncios
  for all to authenticated using (true) with check (true);

-- ---------- Imágenes ----------
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

-- ---------- Sección "Anuncios" de inicio.html ----------
-- La sección se puede ocultar desde "Secciones de la web" y su título se
-- edita en "Contenido de secciones". Si la clave ya existe solo se
-- actualizan página y título (se respetan "orden" y "visible").

insert into public.informacion_general (pagina, clave, titulo, orden, visible) values
  ('inicio.html', 'inicio.anuncios', 'Anuncios', 5, true),
  ('inicio.html', 'inicio.anuncios_titulo', 'Anuncios · título', 5, true)
on conflict (clave) do update set
  pagina = excluded.pagina,
  titulo = excluded.titulo;

insert into public.contenido_secciones (seccion_clave, contenido) values
  ('inicio.anuncios_titulo', '<p><strong>Anuncios</strong></p>')
on conflict (seccion_clave) do nothing;
