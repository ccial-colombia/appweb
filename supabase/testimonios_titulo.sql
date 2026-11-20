-- =============================================================
-- Migración: título opcional en testimonios
-- Ejecutar en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
-- Requiere: supabase_contenido.sql (tabla testimonios)
--
-- Agrega la columna "titulo" a public.testimonios. Es opcional: si queda
-- vacía, el testimonio se muestra como hasta ahora (con el nombre de
-- quien lo da como título). Con título, la tarjeta de comunidad.html y
-- testimonio.html lo muestran como el título de un artículo de El Punto.
-- Se edita en admin.html, pestaña "Testimonios".
--
-- No cambia las políticas: la lectura pública y el acceso de los
-- administradores ya cubren la columna nueva.
-- Se puede ejecutar más de una vez.
-- =============================================================

alter table public.testimonios
  add column if not exists titulo text;
