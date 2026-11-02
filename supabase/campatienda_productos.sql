-- =============================================================
-- CampaTienda: catálogo de productos
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Crea la tabla public.productos. campatienda.html la muestra y se
-- administra desde admin.html, en la pestaña "CampaTienda".
--
--   imagen_url  -> foto del producto. Puede ser una ruta del sitio
--                  (assets/images/campatienda/...) o la URL pública de
--                  una foto subida desde el panel al bucket "contenido".
--   nombre      -> nombre del producto
--   descripcion -> texto corto; los saltos de línea se respetan
--   precio      -> en pesos colombianos, sin puntos (ej: 45000).
--                  Vacío = se muestra "Precio a consultar".
--   opciones    -> tallas, colores u otras opciones separadas por coma
--                  (ej: S, M, L, XL). Vacío = no se muestran opciones.
--   disponible  -> false = el producto aparece como "Agotado"
--   orden       -> orden de aparición (menor primero)
--   visible     -> false = el producto no aparece en la web
--
-- Se puede ejecutar más de una vez: no duplica la tabla, las
-- políticas ni los productos iniciales.
-- =============================================================

create table if not exists public.productos (
  id serial primary key,
  imagen_url text,
  nombre text not null,
  descripcion text,
  precio integer check (precio is null or precio >= 0),
  opciones text,
  disponible boolean not null default true,
  orden int not null default 0,
  visible boolean not null default true
);

-- ---------- Seguridad ----------
-- La web (anon key) solo lee los productos visibles.
-- Los administradores (usuarios autenticados) pueden hacer todo.

alter table public.productos enable row level security;

drop policy if exists "lectura publica" on public.productos;
create policy "lectura publica" on public.productos
  for select using (visible = true);

drop policy if exists "admin total" on public.productos;
create policy "admin total" on public.productos
  for all to authenticated using (true) with check (true);

-- ---------- Fotos subidas desde el panel ----------
-- Se guardan en el bucket público "contenido", carpeta "productos/"
-- (el mismo bucket de cursos y talleres; ver cursos_talleres.sql).

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

-- ---------- Productos iniciales ----------
-- Solo se cargan si la tabla está vacía. Precios y tallas quedan
-- vacíos para completarlos desde el panel.

insert into public.productos (imagen_url, nombre, descripcion, orden)
select v.imagen_url, v.nombre, v.descripcion, v.orden
from (values
  ('assets/images/campatienda/camiseta-verde-mar-camp.webp',
   'Camiseta verde mar CAMP',
   'Camiseta verde mar con el logo de CCI AL al frente y el gráfico CAMP en la espalda.', 1),
  ('assets/images/campatienda/camiseta-negra-camp-life.webp',
   'Camiseta negra Camp Life',
   'Camiseta negra con el logo de CCI AL al frente y el diseño Camp Life «Equipando vidas» a color en la espalda.', 2),
  ('assets/images/campatienda/camiseta-gris-raton-impacto.webp',
   'Camiseta gris ratón Impacto',
   'Camiseta gris ratón con el logo de CCI AL al frente y el diseño «Impactando vidas» en la espalda.', 3),
  ('assets/images/campatienda/camiseta-azul-equipando-vidas.webp',
   'Camiseta azul Equipando Vidas',
   'Camiseta azul oscuro con brújula y montañas al frente y «Equipando vidas» en la espalda.', 4),
  ('assets/images/campatienda/botella-ccial-verde-ambar.webp',
   'Botella CCI AL verde ámbar',
   'Botella en degradado verde y ámbar, con tapa naranja y el logo de CCI AL/Colombia.', 5),
  ('assets/images/campatienda/cuaderno-y-boligrafo-ccial.webp',
   'Cuaderno y bolígrafo ecológico',
   'Cuaderno argollado con portada de campamento y bolígrafo ecológico con el logo de CCI AL.', 6),
  ('assets/images/campatienda/toalla-y-bolsa-ccial.webp',
   'Toalla y bolsa verde CCI AL',
   'Toalla verde con el logo de CCI AL/Colombia y bolsa a juego para guardarla.', 7)
) as v(imagen_url, nombre, descripcion, orden)
where not exists (select 1 from public.productos);
