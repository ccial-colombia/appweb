-- ============================================================
-- Secciones visuales administrables
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Convierte "informacion_general" en el catálogo de partes visuales
-- del sitio: cada fila es un bloque de una página y se puede habilitar
-- o deshabilitar desde admin.html.
--
--   pagina    -> archivo html donde está el bloque (ej: 'comunidad.html')
--   clave     -> identificador que lleva el HTML en data-seccion
--   titulo    -> nombre del bloque tal como se ve en el panel
--   contenido -> texto opcional (se conserva de la versión anterior)
--   orden     -> orden en que aparece el bloque dentro de la página
--   visible   -> true = habilitado, false = oculto en la web
-- ============================================================

alter table public.informacion_general add column if not exists pagina  text;
alter table public.informacion_general add column if not exists orden   int default 0;
alter table public.informacion_general add column if not exists visible boolean not null default true;

create index if not exists idx_informacion_general_pagina
  on public.informacion_general (pagina, orden);

-- ---------- Catálogo de secciones ----------
-- Vuelve a ejecutarse sin problema: si la clave ya existe solo actualiza
-- página, título y orden, y respeta el valor de "visible" que ya tenga.

insert into public.informacion_general (pagina, clave, titulo, orden, visible) values
  ('index.html', 'index.bienvenida', 'Bienvenida y acceso', 1, true),
  ('index.html', 'index.widgets', 'Widgets informativos', 2, true),
  ('index.html', 'index.widget_divisas', 'Widget de divisas', 3, true),
  ('index.html', 'index.widget_clima', 'Widget del clima', 4, true),

  ('inicio.html', 'inicio.galeria', 'Galería de fotos', 1, true),
  ('inicio.html', 'inicio.encabezado', 'Equipando a quienes impactan vidas', 2, true),
  ('inicio.html', 'inicio.vision_mision', 'Visión y misión', 3, true),
  ('inicio.html', 'inicio.quienes_somos', 'Quiénes somos', 4, true),

  ('comunidad.html', 'comunidad.somos_familia', 'Somos familia', 1, true),
  ('comunidad.html', 'comunidad.fincas', 'Fincas', 2, true),
  ('comunidad.html', 'comunidad.transporte', 'Transporte', 3, true),
  ('comunidad.html', 'comunidad.juegos', 'Juegos con propósito', 4, true),
  ('comunidad.html', 'comunidad.cocina', 'Cocina', 5, true),
  ('comunidad.html', 'comunidad.graficos', 'Gráficos', 6, true),
  ('comunidad.html', 'comunidad.testimonios', 'Testimonios', 7, true),

  ('equipados.html', 'equipados.imagen', 'Imagen de portada', 1, true),
  ('equipados.html', 'equipados.introduccion', 'Introducción para miembros', 2, true),
  ('equipados.html', 'equipados.recursos', 'Recursos', 3, true),
  ('equipados.html', 'equipados.asesoria', '1. Déjanos ayudarte (Asesoría)', 4, true),
  ('equipados.html', 'equipados.videos', '2. Videos exclusivos', 5, true),

  ('exclusivo.html', 'exclusivo.introduccion', 'Introducción', 1, true),
  ('exclusivo.html', 'exclusivo.imagen', 'Imagen de portada', 2, true),
  ('exclusivo.html', 'exclusivo.beneficios', 'Beneficios para miembros', 3, true),
  ('exclusivo.html', 'exclusivo.cursos', 'Cursos', 4, true),
  ('exclusivo.html', 'exclusivo.talleres', 'Talleres', 5, true),
  ('exclusivo.html', 'exclusivo.eventos', 'Eventos exclusivos', 6, true),

  ('campatienda.html', 'campatienda.bienvenida', 'Bienvenida a CampaTienda', 1, true),
  ('campatienda.html', 'campatienda.galeria', 'Galería de productos', 2, true),

  ('enciclopedia.html', 'enciclopedia.encabezado', 'Encabezado', 1, true),
  ('enciclopedia.html', 'enciclopedia.introduccion', 'Introducción', 2, true),
  ('enciclopedia.html', 'enciclopedia.grupo1', 'Nombres, rompehielos y de dos en dos', 3, true),
  ('enciclopedia.html', 'enciclopedia.grupo2', 'Grupos pequeños, medianos y multitud', 4, true),
  ('enciclopedia.html', 'enciclopedia.grupo3', 'Persecución, formar grupos y trabajo en equipo', 5, true),
  ('enciclopedia.html', 'enciclopedia.grupo4', 'Nocturnos, piscina y playa, retos', 6, true),
  ('enciclopedia.html', 'enciclopedia.grupo5', 'Deportes modificados, paracaídas e imaginación', 7, true),
  ('enciclopedia.html', 'enciclopedia.grupo6', 'Estrategias, comunicación y afirmación', 8, true),
  ('enciclopedia.html', 'enciclopedia.grupo7', 'Frisbee y dinámicas de capacitación', 9, true),

  ('normas.html', 'normas.encabezado', 'Título e introducción', 1, true),
  ('normas.html', 'normas.grupo1', 'Normas 1 a 3', 2, true),
  ('normas.html', 'normas.grupo2', 'Normas 4 y 5', 3, true),
  ('normas.html', 'normas.grupo3', 'Normas 6 y 7', 4, true),
  ('normas.html', 'normas.grupo4', 'Normas 8 a 10', 5, true),

  ('valores.html', 'valores.encabezado', 'Título e introducción', 1, true),
  ('valores.html', 'valores.grupo1', 'Valores 1 a 3', 2, true),
  ('valores.html', 'valores.grupo2', 'Valores 4 y 5', 3, true),
  ('valores.html', 'valores.grupo3', 'Valores 6 y 7', 4, true),
  ('valores.html', 'valores.grupo4', 'Valores 8 a 10', 5, true)
on conflict (clave) do update set
  pagina = excluded.pagina,
  titulo = excluded.titulo,
  orden  = excluded.orden;

-- Las filas de texto que ya existieran (sin página asignada) quedan
-- siempre visibles para que nada desaparezca por accidente.
update public.informacion_general set visible = true where pagina is null;
