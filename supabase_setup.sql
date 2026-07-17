-- =============================================================
-- Configuración de Supabase para CCI AL/Colombia
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
-- =============================================================

-- 1. Tabla de contraseñas (reemplaza a psw_change.csv)
create table if not exists public.psw_change (
  correlativo serial primary key,
  fecha date not null,
  contrasenia text not null
);

-- 2. RLS activado y sin políticas de lectura:
--    nadie puede leer la tabla desde el navegador con la anon key.
alter table public.psw_change enable row level security;

-- 3. Función de validación: compara la contraseña ingresada con la vigente
--    (la de fecha más reciente que no sea futura). Solo devuelve true/false,
--    la contraseña nunca viaja al navegador.
create or replace function public.validar_password(pass text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce(
    (
      select contrasenia = pass
      from psw_change
      where fecha <= current_date
      order by fecha desc, correlativo desc
      limit 1
    ),
    false
  );
$$;

-- 4. Datos migrados desde psw_change.csv
insert into public.psw_change (fecha, contrasenia) values
  ('2026-01-01', 'colombia2026'),
  ('2026-04-01', 'ccialcol2026'),
  ('2026-04-07', 'ccialcol2026'),
  ('2026-04-08', 'ccialcol2026'),
  ('2026-07-01', '2026ccialcol'),
  ('2027-01-01', 'ccial2027col'),
  ('2027-07-01', 'col2027ccial'),
  ('2028-01-01', 'ccialcol2028');

-- =============================================================
-- Para cambiar la contraseña en el futuro, solo inserta una fila:
--   insert into public.psw_change (fecha, contrasenia)
--   values ('2028-07-01', 'nueva_contrasenia');
-- La nueva contraseña entra en vigor automáticamente en esa fecha.
-- =============================================================
