-- ============================================================
-- Precarga del contenido actual de inicio.html
-- Ejecutar DESPUÉS de contenido_secciones.sql
-- Supabase Dashboard > SQL Editor > New query
--
-- Copia el texto que hoy está en inicio.html a contenido_secciones,
-- para que en el panel el editor aparezca ya con ese texto.
--
-- Visión y Misión se editan por separado (inicio.vision / inicio.mision)
-- para no tocar el diseño de las tarjetas ni la imagen.
--
-- Formato: el editor del panel (Quill) guarda cada línea como un <p> y las
-- líneas en blanco como <p><br></p>; los <br> sueltos dentro de un párrafo
-- los elimina al abrir el texto. Por eso "Quiénes somos" va un <p> por línea.
--
-- Se puede volver a ejecutar sin riesgo: no pisa textos ya editados.
-- ============================================================

-- Alta de las dos secciones de texto de Visión y Misión (por si aún
-- no se ejecutó secciones_visibilidad.sql actualizado).
insert into public.informacion_general (pagina, clave, titulo, orden, visible) values
  ('inicio.html', 'inicio.vision', 'Visión (texto)', 3, true),
  ('inicio.html', 'inicio.mision', 'Misión (texto)', 3, true)
on conflict (clave) do update set
  pagina = excluded.pagina, titulo = excluded.titulo, orden = excluded.orden;

insert into public.contenido_secciones (seccion_clave, contenido) values
  ('inicio.encabezado', '<h1 class="mbr-section-title mbr-fonts-style mb-3 titulo-cci-al"><strong>Equipando a quienes impactan vidas en campamentos</strong></h1>'),
  ('inicio.vision', '<p class="card-text mbr-fonts-style mt-0 mb-0 display-7">Que la iglesia en América Latina realice campamentos que transformen&nbsp;vidas en Cristo.</p>'),
  ('inicio.mision', '<p class="card-text mbr-fonts-style mt-0 mb-0 display-7">Gloriﬁcar a Dios vinculando el ministerio de campamentos con la obra de&nbsp;la iglesia local y ministerios aﬁnes para cumplir la Gran Comisión,&nbsp;capacitando líderes en el ministerio de campamentos.</p>'),
  ('inicio.quienes_somos', '<p>Pertenecemos a la Asociación de Campamentos Cristianos de América Latina (CCI AL).</p><p><br></p><p>CCI AL es una comunidad de creyentes impactados por el ministerio de campamentos, que se unen intencionalmente para servir a la iglesia local a través del ministerio de campamentos. Es una gran alianza que, a lo largo de Latinoamérica, está formando nuevos líderes que se reproducen en otros.</p><p><br></p><p><strong>No somos:</strong></p><p>Un movimiento de campamentos</p><p>Un sitio de campamento</p><p>Una iglesia</p><p>Una denominación</p><p><br></p><p><strong>Existimos para:</strong></p><p>Equipar a quienes impactan vidas en campamentos cristianos, glorificando a Dios y sirviendo a la iglesia local en el cumplimiento de la Gran Comisión.</p><p>"Equipando a quienes impactan vidas en campamentos"</p>')
on conflict (seccion_clave) do nothing;

-- Si ya estaba cargada la versión anterior de "Quiénes somos" (con <br>, que
-- el editor borra), se reemplaza por la nueva. Si ya se editó desde el panel,
-- no se toca.
update public.contenido_secciones
set contenido = '<p>Pertenecemos a la Asociación de Campamentos Cristianos de América Latina (CCI AL).</p><p><br></p><p>CCI AL es una comunidad de creyentes impactados por el ministerio de campamentos, que se unen intencionalmente para servir a la iglesia local a través del ministerio de campamentos. Es una gran alianza que, a lo largo de Latinoamérica, está formando nuevos líderes que se reproducen en otros.</p><p><br></p><p><strong>No somos:</strong></p><p>Un movimiento de campamentos</p><p>Un sitio de campamento</p><p>Una iglesia</p><p>Una denominación</p><p><br></p><p><strong>Existimos para:</strong></p><p>Equipar a quienes impactan vidas en campamentos cristianos, glorificando a Dios y sirviendo a la iglesia local en el cumplimiento de la Gran Comisión.</p><p>"Equipando a quienes impactan vidas en campamentos"</p>',
    updated_at = now()
where seccion_clave = 'inicio.quienes_somos'
  and contenido like '%<br><br>%';
