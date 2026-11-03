-- =============================================================
-- Comunidad: quitar "Juegos con propósito" y "Gráficos"
-- Ejecutar UNA VEZ en: Supabase Dashboard > SQL Editor > New query
-- Proyecto: gmcuzmsckwtdvurboobh
--
-- comunidad.html ya no tiene esas dos secciones y el panel ya no
-- tiene sus pestañas. Este script limpia la base actual:
--
-- 1) Borra las tablas public.juegos y public.graficos (con sus
--    políticas). Si ya se borraron a mano, no hace nada.
-- 2) Quita del catálogo de secciones (informacion_general) las
--    secciones y los títulos de esas dos partes de la página, y sus
--    textos guardados en contenido_secciones.
--
-- Solo hace falta en bases creadas antes de este cambio: los demás
-- scripts ya no crean esas tablas ni esas secciones.
-- Se puede ejecutar más de una vez.
-- =============================================================

drop table if exists public.juegos;
drop table if exists public.graficos;

delete from public.contenido_secciones
where seccion_clave in ('comunidad.juegos_titulo', 'comunidad.graficos_titulo');

delete from public.informacion_general
where clave in (
  'comunidad.juegos', 'comunidad.juegos_titulo',
  'comunidad.graficos', 'comunidad.graficos_titulo'
);
