-- =============================================================
-- Estilos de títulos: tipo de letra, tamaño y color de los títulos y
-- subtítulos de todas las páginas
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Crea la tabla public.estilos_titulos con una fila por grupo de títulos.
-- assets/js/secciones.js la lee en cada página y aplica los estilos a
-- todos los elementos del grupo (también a los que se crean después,
-- como las tarjetas de El Punto o de CampaTienda). Se edita desde
-- admin.html > Configuración > Estilos de títulos.
--
--   clave       -> grupo (secciones.js sabe qué clases de la página son
--                  de cada grupo):
--                    titulos    -> títulos de página y de sección
--                    subtitulos -> subtítulos
--                    tarjetas   -> títulos de tarjetas y elementos
--   nombre      -> nombre del grupo en el panel
--   descripcion -> dónde se aplica (se muestra en el panel)
--   fuente      -> tipo de letra (uno de la lista del panel). Vacío = el
--                  original de cada título
--   tamano      -> porcentaje del tamaño original de cada título (50 a
--                  200). Mantiene la proporción entre títulos y la
--                  adaptación a celulares. Vacío = 100 % (sin cambio)
--   color       -> color en formato #rrggbb. Vacío = el original
--   orden       -> orden en el panel
--
-- Las filas las crea este script; en el panel solo se editan.
-- Se puede ejecutar más de una vez: no duplica la tabla, las políticas
-- ni las filas, y no pisa los estilos elegidos en el panel.
-- =============================================================

create table if not exists public.estilos_titulos (
  id serial primary key,
  clave text not null unique,
  nombre text not null,
  descripcion text,
  fuente text,
  tamano integer,
  color text,
  orden integer not null default 0,
  -- Valores que secciones.js puede poner en el CSS sin riesgo.
  constraint estilos_titulos_fuente check (fuente is null or fuente ~ '^[A-Za-z0-9 ]{1,60}$'),
  constraint estilos_titulos_tamano check (tamano is null or tamano between 50 and 200),
  constraint estilos_titulos_color check (color is null or color ~ '^#[0-9A-Fa-f]{6}$')
);

-- ---------- Seguridad ----------
-- La web (anon key) lee los estilos; los administradores (usuarios
-- autenticados) pueden hacer todo.

alter table public.estilos_titulos enable row level security;

drop policy if exists "lectura publica" on public.estilos_titulos;
create policy "lectura publica" on public.estilos_titulos
  for select using (true);

drop policy if exists "admin total" on public.estilos_titulos;
create policy "admin total" on public.estilos_titulos
  for all to authenticated using (true) with check (true);

-- ---------- Grupos ----------
-- Si la clave ya existe solo se actualizan nombre, descripción y orden
-- (se respetan fuente, tamaño y color elegidos en el panel).

insert into public.estilos_titulos (clave, nombre, descripcion, orden) values
  ('titulos', 'Títulos de página y de sección',
   'El título principal de cada página y los títulos de sus secciones (ej: "Bienvenido a CampaTienda", "Fincas", "Las 10 Normas", "Artículos").', 1),
  ('subtitulos', 'Subtítulos',
   'Los textos que acompañan a un título (ej: "¡Solo para nuestra familia CCI AL!", la descripción corta de cada curso y los grupos de Recursos descargables).', 2),
  ('tarjetas', 'Títulos de tarjetas',
   'Los títulos dentro de tarjetas y listas: Visión y Misión, normas, valores, juegos de la Enciclopedia, talleres, productos, videos, recursos descargables y artículos de El Punto.', 3)
on conflict (clave) do update set
  nombre      = excluded.nombre,
  descripcion = excluded.descripcion,
  orden       = excluded.orden;
