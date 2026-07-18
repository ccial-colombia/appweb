-- =============================================================
-- Tablas de contenido para la página Comunidad (comunidad.html)
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- Cada sección de la página lee de su propia tabla:
--   Fincas               -> public.fincas
--   Transporte           -> public.transporte
--   Juegos con propósito -> public.juegos
--   Cocina               -> public.cocina
--   Graficos             -> public.graficos
--   Testimonios          -> public.testimonios
--
-- Para administrar el contenido: Table Editor en el panel de
-- Supabase. Las filas con visible = false no se muestran en la web.
-- El campo "orden" controla el orden de aparición (menor primero).
-- =============================================================

-- ---------- Tablas de recursos (Nombre / Lugar / Contacto) ----------

create table if not exists public.fincas (
  id serial primary key,
  nombre text not null,
  lugar text,
  contacto text,
  orden int default 0,
  visible boolean default true
);

create table if not exists public.transporte (
  id serial primary key,
  nombre text not null,
  lugar text,
  contacto text,
  orden int default 0,
  visible boolean default true
);

create table if not exists public.juegos (
  id serial primary key,
  nombre text not null,
  lugar text,
  contacto text,
  orden int default 0,
  visible boolean default true
);

create table if not exists public.cocina (
  id serial primary key,
  nombre text not null,
  lugar text,
  contacto text,
  orden int default 0,
  visible boolean default true
);

create table if not exists public.graficos (
  id serial primary key,
  nombre text not null,
  lugar text,
  contacto text,
  orden int default 0,
  visible boolean default true
);

-- ---------- Testimonios ----------

create table if not exists public.testimonios (
  id serial primary key,
  nombre text not null,          -- quién da el testimonio
  rol text,                      -- iglesia, ministerio o cargo (opcional)
  mensaje text not null,         -- el testimonio
  orden int default 0,
  visible boolean default true
);

-- ---------- Seguridad: lectura pública, escritura bloqueada ----------
-- La anon key solo puede LEER. Insertar/editar/borrar únicamente
-- desde el panel de Supabase (o con la service_role key).

alter table public.fincas       enable row level security;
alter table public.transporte   enable row level security;
alter table public.juegos       enable row level security;
alter table public.cocina       enable row level security;
alter table public.graficos     enable row level security;
alter table public.testimonios  enable row level security;

create policy "lectura publica" on public.fincas      for select using (true);
create policy "lectura publica" on public.transporte  for select using (true);
create policy "lectura publica" on public.juegos      for select using (true);
create policy "lectura publica" on public.cocina      for select using (true);
create policy "lectura publica" on public.graficos    for select using (true);
create policy "lectura publica" on public.testimonios for select using (true);

-- ---------- Datos de ejemplo (reemplázalos con los reales) ----------

insert into public.fincas (nombre, lugar, contacto, orden) values
  ('Finca El Refugio (ejemplo)', 'La Mesa, Cundinamarca', '300 000 0000', 1),
  ('Finca Monteverde (ejemplo)', 'Silvania, Cundinamarca', 'correo@ejemplo.com', 2);

insert into public.transporte (nombre, lugar, contacto, orden) values
  ('Transportes El Camino (ejemplo)', 'Bogotá', '310 000 0000', 1);

insert into public.juegos (nombre, lugar, contacto, orden) values
  ('Búsqueda del tesoro bíblica (ejemplo)', 'Cualquier locación', 'coordinacion@ejemplo.com', 1);

insert into public.cocina (nombre, lugar, contacto, orden) values
  ('Servicio de alimentación Sabor y Fe (ejemplo)', 'Bogotá', '320 000 0000', 1);

insert into public.graficos (nombre, lugar, contacto, orden) values
  ('Plantillas EBC 2026 (ejemplo)', 'Google Drive', 'comunicacionesccialcol@gmail.com', 1);

insert into public.testimonios (nombre, rol, mensaje, orden) values
  ('María G. (ejemplo)', 'Líder de campamento', 'El campamento transformó la vida de nuestros jóvenes. La comunidad CCI nos acompañó en cada paso.', 1),
  ('Carlos R. (ejemplo)', 'Pastor de jóvenes', 'Gracias a los recursos compartidos pudimos organizar nuestro primer campamento sin contratiempos.', 2);
