-- =============================================================
-- Migración: columnas Ciudad y Capacidad en Fincas
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- La tabla fincas pasa de (Nombre, Lugar, Contacto) a:
-- (Nombre, Lugar, Ciudad, Contacto, Capacidad)
-- =============================================================

alter table public.fincas
  add column if not exists ciudad text,
  add column if not exists capacidad int;
