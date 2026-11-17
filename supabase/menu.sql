-- =============================================================
-- Menú superior administrable
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Crea la tabla public.menu con las opciones del menú superior de
-- las páginas (inicio, equipados, exclusivo, comunidad, campatienda
-- y elpunto). Se administra desde admin.html, en la pestaña "Menú":
-- ahí se cambia el orden (con las flechas o el campo "Orden"), el
-- texto, el enlace, y se agregan u ocultan opciones.
--
--   etiqueta      -> texto que se ve en el menú
--   enlace        -> página del sitio (ej: 'elpunto.html') o dirección
--                    completa ('https://...' o 'mailto:...')
--   nueva_pestana -> true = se abre en una pestaña nueva (sitios externos)
--   orden         -> posición en el menú (menor primero)
--   visible       -> false = la opción no aparece en el menú
--
-- assets/js/secciones.js arma el menú (la lista con data-menu en el
-- HTML) con las opciones visibles, en este orden. Si la tabla está
-- vacía o no se puede leer, se deja el menú escrito en el HTML.
--
-- Se puede ejecutar más de una vez: las opciones iniciales solo se
-- cargan si la tabla está vacía, así no se pierden los cambios hechos
-- en el panel.
-- =============================================================

create table if not exists public.menu (
  id serial primary key,
  etiqueta text not null,
  enlace text not null,
  nueva_pestana boolean not null default false,
  orden int not null default 0,
  visible boolean not null default true
);

-- ---------- Seguridad ----------
-- La web (anon key) solo lee las opciones visibles.
-- Los administradores (usuarios autenticados) pueden hacer todo.

alter table public.menu enable row level security;

drop policy if exists "lectura publica" on public.menu;
create policy "lectura publica" on public.menu
  for select using (visible = true);

drop policy if exists "admin total" on public.menu;
create policy "admin total" on public.menu
  for all to authenticated using (true) with check (true);

-- ---------- Opciones iniciales (el menú actual) ----------

insert into public.menu (etiqueta, enlace, nueva_pestana, orden)
select v.etiqueta, v.enlace, v.nueva_pestana, v.orden
from (values
  ('Inicio',      'inicio.html',        false, 1),
  ('CCI AL',      'https://ccial.org/', true,  2),
  ('Equipados',   'equipados.html',     false, 3),
  ('Exclusivo',   'exclusivo.html',     false, 4),
  ('Comunidad',   'comunidad.html',     false, 5),
  ('CampaTienda', 'campatienda.html',   false, 6),
  ('El Punto',    'elpunto.html',       false, 7)
) as v(etiqueta, enlace, nueva_pestana, orden)
where not exists (select 1 from public.menu);
