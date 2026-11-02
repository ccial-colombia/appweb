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

-- 4. Las contraseñas NO se guardan en este repositorio (es público).
--    Cárgalas desde el panel (admin.html > Contraseñas de acceso) o
--    directamente en el SQL Editor de Supabase.

-- =============================================================
-- Para cambiar la contraseña en el futuro, solo inserta una fila:
--   insert into public.psw_change (fecha, contrasenia)
--   values ('AAAA-MM-DD', '<nueva_contrasenia>');
-- La nueva contraseña entra en vigor automáticamente en esa fecha.
-- =============================================================
