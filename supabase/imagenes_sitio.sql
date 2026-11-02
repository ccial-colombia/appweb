-- =============================================================
-- Imágenes del sitio administrables
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Crea la tabla public.imagenes_sitio: una fila por cada imagen fija
-- de las páginas (logo, favicon, portadas, galería, tomos, normas,
-- valores y fondos). Se administra desde admin.html, en la pestaña
-- "Imágenes del sitio".
--
--   clave      -> identificador que lleva el HTML en data-imagen="..."
--   pagina     -> archivo html donde está la imagen (null = todas)
--   titulo     -> qué imagen es, tal como se ve en el panel
--   imagen_url -> imagen a mostrar. Puede ser una ruta del sitio
--                 (assets/images/...) o la URL pública de una imagen
--                 subida desde el panel al bucket "contenido".
--                 Vacío = se muestra la imagen original del HTML.
--   alt        -> texto alternativo (lectores de pantalla).
--                 Vacío = se deja el texto original del HTML.
--   orden      -> orden dentro de la página en el panel
--
-- assets/js/secciones.js busca los elementos con data-imagen y les
-- pone la imagen guardada aquí antes de mostrar la página:
--   <img>             -> cambia la imagen (src) y el texto alternativo
--   <link rel="icon"> -> cambia el ícono de la pestaña
--   <section>         -> cambia la imagen de fondo
--
-- Las imágenes que ya se administran en otras pestañas del panel
-- (cursos, talleres, testimonios y productos de CampaTienda) no
-- están aquí.
--
-- Se puede ejecutar más de una vez: no borra las imágenes ni los
-- textos alternativos que se hayan cambiado desde el panel.
-- =============================================================

create table if not exists public.imagenes_sitio (
  id serial primary key,
  clave text not null unique,
  pagina text,
  titulo text not null,
  imagen_url text,
  alt text,
  orden int not null default 0
);

-- ---------- Seguridad ----------
-- La web (anon key) solo lee. Los administradores (usuarios
-- autenticados) pueden hacer todo.

alter table public.imagenes_sitio enable row level security;

drop policy if exists "lectura publica" on public.imagenes_sitio;
create policy "lectura publica" on public.imagenes_sitio
  for select using (true);

drop policy if exists "admin total" on public.imagenes_sitio;
create policy "admin total" on public.imagenes_sitio
  for all to authenticated using (true) with check (true);

-- ---------- Imágenes subidas desde el panel ----------
-- Se guardan en el bucket público "contenido", carpeta "imagenes_sitio/"
-- (el mismo bucket de cursos, talleres y productos).

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

-- ---------- Catálogo de imágenes ----------
-- Si la clave ya existe solo se actualizan página, título y orden;
-- la imagen y el texto alternativo elegidos en el panel se respetan.

insert into public.imagenes_sitio (pagina, clave, titulo, imagen_url, alt, orden) values
  (null, 'global.logo', 'Logo del menú superior', 'assets/images/logo-blan-1-299x95.png', 'CCI AL/Colombia', 1),
  (null, 'global.favicon', 'Ícono de la pestaña del navegador (favicon)', 'assets/images/favicon-192x192.png', null, 2),
  ('index.html', 'index.portada', 'Imagen de bienvenida', 'assets/images/inicio-1600x753.jpeg', 'Bienvenido a CCI AL/Colombia', 1),
  ('inicio.html', 'inicio.galeria_1', 'Galería de fotos · foto 1', 'assets/images/galeria2001-377x251.jpeg', 'Galería de CCI AL/Colombia: foto 1', 1),
  ('inicio.html', 'inicio.galeria_2', 'Galería de fotos · foto 2', 'assets/images/galeria2002-377x251.jpeg', 'Galería de CCI AL/Colombia: foto 2', 2),
  ('inicio.html', 'inicio.galeria_3', 'Galería de fotos · foto 3', 'assets/images/galeria2003-377x251.jpeg', 'Galería de CCI AL/Colombia: foto 3', 3),
  ('inicio.html', 'inicio.galeria_4', 'Galería de fotos · foto 4', 'assets/images/galeria2004-377x251.jpeg', 'Galería de CCI AL/Colombia: foto 4', 4),
  ('inicio.html', 'inicio.galeria_5', 'Galería de fotos · foto 5', 'assets/images/galeria2005-377x251.jpeg', 'Galería de CCI AL/Colombia: foto 5', 5),
  ('inicio.html', 'inicio.galeria_6', 'Galería de fotos · foto 6', 'assets/images/galeria2006-377x251.jpeg', 'Galería de CCI AL/Colombia: foto 6', 6),
  ('inicio.html', 'inicio.vision_mision', 'Imagen de Visión y misión', 'assets/images/vision20y20mision-1101x734.jpeg', 'Visión y misión de CCI AL/Colombia', 7),
  ('equipados.html', 'equipados.portada', 'Imagen de portada', 'assets/images/mochila-1920x1280.jpeg', 'Equipados', 1),
  ('exclusivo.html', 'exclusivo.portada', 'Imagen de portada', 'assets/images/exclusivos-2394x1596.jpeg', 'Exclusivos', 1),
  ('exclusivo.html', 'exclusivo.zoom', 'Eventos exclusivos · Zoom de miembros', 'assets/images/zoom-1-300x168.jpeg', 'Zoom de miembros', 2),
  ('exclusivo.html', 'exclusivo.taller', 'Eventos exclusivos · Taller exclusivo', 'assets/images/taller20exclusivo-712x475.jpeg', 'Taller exclusivo', 3),
  ('exclusivo.html', 'exclusivo.encuentro', 'Eventos exclusivos · Encuentro nacional de miembros', 'assets/images/encuentro-1-712x949.jpeg', 'Encuentro Nacional de Miembros', 4),
  ('comunidad.html', 'comunidad.somos_familia', 'Imagen de Somos familia', 'assets/images/comunidad-1076x1614.jpeg', 'Comunidad', 1),
  ('campatienda.html', 'campatienda.portada', 'Logo de CampaTienda', 'assets/images/CampaTienda.jpg', 'CampaTienda', 1),
  ('enciclopedia.html', 'enciclopedia.fondo', 'Fondo del encabezado', 'assets/images/background1.jpg', null, 1),
  ('enciclopedia.html', 'enciclopedia.logo_ejca', 'Logo EJCA', 'assets/images/ejca-logo-1076x628.png', 'EJCA', 2),
  ('enciclopedia.html', 'enciclopedia.tomo_01', 'Portada del tomo 1', 'assets/images/ejcaportada01-695x878.jpg', 'Tomo 1', 3),
  ('enciclopedia.html', 'enciclopedia.tomo_02', 'Portada del tomo 2', 'assets/images/ejcaportada02-695x878.jpg', 'Tomo 2', 4),
  ('enciclopedia.html', 'enciclopedia.tomo_03', 'Portada del tomo 3', 'assets/images/ejcaportada03-695x878.jpg', 'Tomo 3', 5),
  ('enciclopedia.html', 'enciclopedia.tomo_04', 'Portada del tomo 4', 'assets/images/ejcaportada04-695x878.jpg', 'Tomo 4', 6),
  ('enciclopedia.html', 'enciclopedia.tomo_05', 'Portada del tomo 5', 'assets/images/ejcaportada05-695x878.jpg', 'Tomo 5', 7),
  ('enciclopedia.html', 'enciclopedia.tomo_06', 'Portada del tomo 6', 'assets/images/ejcaportada06-695x878.jpg', 'Tomo 6', 8),
  ('enciclopedia.html', 'enciclopedia.tomo_07', 'Portada del tomo 7', 'assets/images/ejcaportada07-695x878.jpg', 'Tomo 7', 9),
  ('enciclopedia.html', 'enciclopedia.tomo_08', 'Portada del tomo 8', 'assets/images/ejcaportada08-695x878.jpg', 'Tomo 8', 10),
  ('enciclopedia.html', 'enciclopedia.tomo_09', 'Portada del tomo 9', 'assets/images/ejcaportada09-695x878.jpg', 'Tomo 9', 11),
  ('enciclopedia.html', 'enciclopedia.tomo_10', 'Portada del tomo 10', 'assets/images/ejcaportada10-695x878.jpg', 'Tomo 10', 12),
  ('enciclopedia.html', 'enciclopedia.tomo_11', 'Portada del tomo 11', 'assets/images/ejcaportada11-695x878.jpg', 'Tomo 11', 13),
  ('enciclopedia.html', 'enciclopedia.tomo_12', 'Portada del tomo 12', 'assets/images/ejcaportada12-695x878.jpg', 'Tomo 12', 14),
  ('enciclopedia.html', 'enciclopedia.tomo_13', 'Portada del tomo 13', 'assets/images/ejcaportada13-695x878.jpg', 'Tomo 13', 15),
  ('enciclopedia.html', 'enciclopedia.tomo_14', 'Portada del tomo 14', 'assets/images/ejcaportada14-695x878.jpg', 'Tomo 14', 16),
  ('enciclopedia.html', 'enciclopedia.tomo_15', 'Portada del tomo 15', 'assets/images/ejcaportada15-695x878.jpg', 'Tomo 15', 17),
  ('enciclopedia.html', 'enciclopedia.tomo_16', 'Portada del tomo 16', 'assets/images/ejcaportada16-695x878.jpg', 'Tomo 16', 18),
  ('enciclopedia.html', 'enciclopedia.tomo_17', 'Portada del tomo 17', 'assets/images/ejcaportada17-695x878.jpg', 'Tomo 17', 19),
  ('enciclopedia.html', 'enciclopedia.tomo_18', 'Portada del tomo 18', 'assets/images/ejcaportada18-695x878.jpg', 'Tomo 18', 20),
  ('enciclopedia.html', 'enciclopedia.tomo_19', 'Portada del tomo 19', 'assets/images/ejcaportada19-695x878.jpg', 'Tomo 19', 21),
  ('enciclopedia.html', 'enciclopedia.tomo_20', 'Portada del tomo 20', 'assets/images/ejcaportada20-695x878.jpg', 'Tomo 20', 22),
  ('normas.html', 'normas.fondo', 'Fondo del encabezado', 'assets/images/background1.jpg', null, 1),
  ('normas.html', 'normas.norma_01', 'Norma 1 · Fomentar un ambiente de amor y camaradería', 'assets/images/norma-01-816x615.png', 'Norma 1: Fomentar un ambiente de amor y camaradería', 2),
  ('normas.html', 'normas.norma_02', 'Norma 2 · Establecer participación máxima con propósito', 'assets/images/norma-02-816x615.png', 'Norma 2: Establecer participación máxima con propósito', 3),
  ('normas.html', 'normas.norma_03', 'Norma 3 · Enfatizar la cooperación en vez de la competencia', 'assets/images/norma-03-816x615.png', 'Norma 3: Enfatizar la cooperación en vez de la competencia', 4),
  ('normas.html', 'normas.norma_04', 'Norma 4 · Reflejar la ética cristiana en el campamento', 'assets/images/norma-04-816x615.png', 'Norma 4: Reflejar la ética cristiana en el campamento', 5),
  ('normas.html', 'normas.norma_05', 'Norma 5 · Explorar la naturaleza', 'assets/images/norma-05-816x615.png', 'Norma 5: Explorar la naturaleza', 6),
  ('normas.html', 'normas.norma_06', 'Norma 6 · Reflexionar y evaluar', 'assets/images/norma-06-816x615.png', 'Norma 6: Reflexionar y evaluar', 7),
  ('normas.html', 'normas.norma_07', 'Norma 7 · Buscar lo novedoso o diferente de lo cotidiano', 'assets/images/norma-07-816x615.png', 'Norma 7: Buscar lo novedoso o diferente de lo cotidiano', 8),
  ('normas.html', 'normas.norma_08', 'Norma 8 · Estimular la creatividad y la imaginación', 'assets/images/norma-08-816x615.png', 'Norma 8: Estimular la creatividad y la imaginación', 9),
  ('normas.html', 'normas.norma_09', 'Norma 9 · Desarrollar habilidades', 'assets/images/norma-09-816x615.png', 'Norma 9: Desarrollar habilidades', 10),
  ('normas.html', 'normas.norma_10', 'Norma 10 · Velar por la salud y la seguridad de los acampantes', 'assets/images/norma-10-816x615.png', 'Norma 10: Velar por la salud y la seguridad de los acampantes', 11),
  ('valores.html', 'valores.fondo', 'Fondo del encabezado', 'assets/images/background1.jpg', null, 1),
  ('valores.html', 'valores.valor_01', 'Valor 1 · Dependencia de Dios', 'assets/images/vm-01-695x524.png', 'Valor 1: Dependencia de Dios', 2),
  ('valores.html', 'valores.valor_02', 'Valor 2 · Amor por los que no conocen a Cristo', 'assets/images/vm-02-695x524.png', 'Valor 2: Amor por los que no conocen a Cristo', 3),
  ('valores.html', 'valores.valor_03', 'Valor 3 · Comunidad bíblica temporal', 'assets/images/vm-03-695x524.png', 'Valor 3: Comunidad bíblica temporal', 4),
  ('valores.html', 'valores.valor_04', 'Valor 4 · Formación de líderes', 'assets/images/vm-04-695x524.png', 'Valor 4: Formación de líderes', 5),
  ('valores.html', 'valores.valor_05', 'Valor 5 · Servicio voluntario', 'assets/images/vm-05-695x524.png', 'Valor 5: Servicio voluntario', 6),
  ('valores.html', 'valores.valor_06', 'Valor 6 · Búsqueda de Excelencia', 'assets/images/vm-06-695x524.png', 'Valor 6: Búsqueda de Excelencia', 7),
  ('valores.html', 'valores.valor_07', 'Valor 7 · Somos una familia', 'assets/images/vm-07-695x524.png', 'Valor 7: Somos una familia', 8),
  ('valores.html', 'valores.valor_08', 'Valor 8 · El espíritu de compartir', 'assets/images/vm-08-695x524.png', 'Valor 8: El espíritu de compartir', 9),
  ('valores.html', 'valores.valor_09', 'Valor 9 · Mayordomía de la creación de Dios', 'assets/images/vm-09-695x524.png', 'Valor 9: Mayordomía de la creación de Dios', 10),
  ('valores.html', 'valores.valor_10', 'Valor 10 · Recreación con propósito', 'assets/images/vm-10-695x524.png', 'Valor 10: Recreación con propósito', 11)
on conflict (clave) do update set
  pagina = excluded.pagina,
  titulo = excluded.titulo,
  orden  = excluded.orden;

-- =============================================================
-- Para hacer administrable una imagen nueva:
--   1) En el HTML agrega data-imagen="pagina.nombre" a la etiqueta
--      <img> (o a la <section> si es una imagen de fondo).
--   2) Inserta su fila:
--      insert into public.imagenes_sitio (pagina, clave, titulo, imagen_url, alt, orden)
--      values ('pagina.html', 'pagina.nombre', 'Descripción', 'assets/images/archivo.jpg', 'Texto alternativo', 99);
-- =============================================================
