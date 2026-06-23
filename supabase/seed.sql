-- Initial seed for CCI AL Colombia.
-- Run after supabase/migrations/20260623000000_initial_schema.sql.

insert into public.pages (slug, title, meta_description, source_path, requires_auth, is_active)
values
    (
        'landing',
        'CCI AL/Colombia',
        'Portal de CCI AL Colombia para miembros y comunidad del ministerio de campamentos.',
        'index.html',
        false,
        true
    ),
    (
        'inicio',
        'Inicio CCI AL/Colombia',
        'Panel de bienvenida para miembros de CCI AL Colombia.',
        'inicio.html',
        true,
        true
    ),
    (
        'equipados',
        'Equipados CCI AL/Colombia',
        'Recursos, asesorias y videos exclusivos para miembros.',
        'equipados.html',
        true,
        true
    ),
    (
        'exclusivo',
        'Exclusivo CCI AL/Colombia',
        'Cursos, talleres y eventos exclusivos para miembros.',
        'exclusivo.html',
        true,
        true
    ),
    (
        'comunidad',
        'Comunidad CCI AL/Colombia',
        'Recursos compartidos por la comunidad: fincas, transporte, juegos, cocina y graficos.',
        'comunidad.html',
        true,
        true
    ),
    (
        'campatienda',
        'CampaTienda CCI AL/Colombia',
        'Tienda oficial de CCI AL Colombia.',
        'campatienda.html',
        true,
        true
    )
    /*,
    (
        'enciclopedia',
        'Enciclopedia de Juegos',
        'Coleccion de juegos y actividades recreativas para el ministerio de campamentos.',
        'enciclopedia.html',
        false,
        true
    ),
    (
        'normas',
        '10 Normas para crecer',
        'Normas y principios para experiencias de campamento cristiano.',
        'normas.html',
        false,
        true
    ),
    (
        'valores',
        '10 Valores de CCI AL',
        'Valores institucionales de CCI America Latina.',
        'valores.html',
        false,
        true
    )*/
on conflict (slug) do update
set
    title = excluded.title,
    meta_description = excluded.meta_description,
    source_path = excluded.source_path,
    requires_auth = excluded.requires_auth,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.nav_items (label, url, is_external, display_order, is_active)
values
    ('Inicio', '/inicio', false, 0, true),
    ('CCI AL', 'https://ccial.org/', true, 1, true),
    ('Equipados', '/equipados', false, 2, true),
    ('Exclusivo', '/exclusivo', false, 3, true),
    ('Comunidad', '/comunidad', false, 4, true),
    ('CampaTienda', '/campatienda', false, 5, true)
    /*,
    ('Valores', '/valores', false, 6, false),
    ('Normas', '/normas', false, 7, false),
    ('Enciclopedia', '/enciclopedia', false, 8, false)*/
on conflict (label, url) do update
set
    is_external = excluded.is_external,
    display_order = excluded.display_order,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.site_settings (key, value)
values
    ('site_name', 'CCI AL Colombia'),
    ('site_short_name', 'CCI AL/Colombia'),
    ('contact_email', 'comunicacionesccialcol@gmail.com'),
    ('logo_url', 'assets/images/logo-blan-1-299x95.png'),
    ('favicon_url', 'assets/images/CCI%20AL.png'),
    ('copyright', 'Copyright 2026 - Todos los derechos reservados'),
    ('hero_headline', 'Bienvenido a CCI AL/Colombia'),
    ('hero_subtext', 'Nos alegra muchisimo tenerte aqui. Como parte de esta gran familia, queremos que te sientas en casa.'),
    ('official_domain', 'https://ccial.org/')
on conflict (key) do update
set
    value = excluded.value,
    updated_at = now();

insert into public.social_links (platform, url, icon, display_order, is_active)
values
    ('facebook', 'https://www.facebook.com/487429831785922', 'facebook', 0, true),
    ('instagram', 'https://www.instagram.com/ccial.colombia/', 'instagram', 1, true),
    ('youtube', 'https://www.youtube.com/@CCIALCOLOMBIA', 'youtube', 2, true),
    ('email', 'mailto:comunicacionesccialcol@gmail.com?subject=Consulta%20desde%20Pagina%20Web', 'mail', 3, true)
on conflict (platform, url) do update
set
    icon = excluded.icon,
    display_order = excluded.display_order,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.page_sections (
    page_id,
    section_key,
    section_type,
    title,
    content,
    image_url,
    display_order,
    is_visible
)
select
    p.id,
    'hero',
    'hero'::public.section_type,
    'Bienvenido a CCI AL/Colombia',
    jsonb_build_object(
        'headline', 'Bienvenido a CCI AL/Colombia',
        'body', 'Nos alegra muchisimo tenerte aqui. Como parte de esta gran familia, queremos que te sientas en casa y disfrutes de todos los beneficios que ser miembro de CCI AL/Colombia tiene para ti.',
        'highlight', 'Tu compromiso y amor por los campamentos nos inspiran cada dia.',
        'cta_text', 'Entrar',
        'cta_url', '/inicio'
    ),
    'assets/images/inicio-2266x1511.jpeg',
    0,
    true
from public.pages p
where p.slug = 'landing'
on conflict (page_id, section_key) do update
set
    section_type = excluded.section_type,
    title = excluded.title,
    content = excluded.content,
    image_url = excluded.image_url,
    display_order = excluded.display_order,
    is_visible = excluded.is_visible,
    updated_at = now();

insert into public.page_sections (
    page_id,
    section_key,
    section_type,
    title,
    content,
    image_url,
    display_order,
    is_visible
)
select
    p.id,
    'vision_mision',
    'cards'::public.section_type,
    'Vision y Mision',
    jsonb_build_object(
        'items',
        jsonb_build_array(
            jsonb_build_object(
                'title', 'Vision',
                'description', 'Que la iglesia en America Latina realice campamentos que transformen vidas en Cristo.'
            ),
            jsonb_build_object(
                'title', 'Mision',
                'description', 'Glorificar a Dios vinculando el ministerio de campamentos con la obra de la iglesia local y ministerios afines para cumplir la Gran Comision, capacitando lideres en el ministerio de campamentos.'
            )
        )
    ),
    'assets/images/vision20y20mision-1101x734.jpeg',
    1,
    true
from public.pages p
where p.slug = 'inicio'
on conflict (page_id, section_key) do update
set
    section_type = excluded.section_type,
    title = excluded.title,
    content = excluded.content,
    image_url = excluded.image_url,
    display_order = excluded.display_order,
    is_visible = excluded.is_visible,
    updated_at = now();

insert into public.page_sections (
    page_id,
    section_key,
    section_type,
    title,
    content,
    image_url,
    display_order,
    is_visible
)
select
    p.id,
    'comunidad_intro',
    'text'::public.section_type,
    'Somos familia',
    jsonb_build_object(
        'body', 'Somos una comunidad que se apoya mutuamente. Aqui compartimos experiencias, recomendaciones y recursos que ayudan a mejorar cada campamento.',
        'topics', jsonb_build_array('Fincas', 'Transporte', 'Juegos con Proposito', 'Cocina', 'Graficos', 'EBC')
    ),
    'assets/images/comunidad-1076x1614.jpeg',
    0,
    true
from public.pages p
where p.slug = 'comunidad'
on conflict (page_id, section_key) do update
set
    section_type = excluded.section_type,
    title = excluded.title,
    content = excluded.content,
    image_url = excluded.image_url,
    display_order = excluded.display_order,
    is_visible = excluded.is_visible,
    updated_at = now();

insert into public.page_sections (
    page_id,
    section_key,
    section_type,
    title,
    content,
    image_url,
    display_order,
    is_visible
)
select
    p.id,
    'campatienda_intro',
    'hero'::public.section_type,
    'Bienvenido a CampaTienda',
    jsonb_build_object(
        'headline', 'Bienvenido a CampaTienda, la tienda oficial de CCI AL/Colombia',
        'body', 'Aqui encontraras productos campamentiles y articulos disenados para acompanarte en tu servicio y en cada experiencia de campamento.',
        'contact_email', 'comunicacionesccialcol@gmail.com'
    ),
    'assets/images/coleccionistas-1646x660.png',
    0,
    true
from public.pages p
where p.slug = 'campatienda'
on conflict (page_id, section_key) do update
set
    section_type = excluded.section_type,
    title = excluded.title,
    content = excluded.content,
    image_url = excluded.image_url,
    display_order = excluded.display_order,
    is_visible = excluded.is_visible,
    updated_at = now();

insert into public.gallery_images (page_id, section_name, image_url, alt_text, caption, display_order, is_active)
select p.id, g.section_name, g.image_url, g.alt_text, g.caption, g.display_order, true
from public.pages p
cross join (
    values
        ('inicio_gallery', 'assets/images/galeria2001-377x251.jpeg', 'Galeria CCI AL Colombia 1', null, 0),
        ('inicio_gallery', 'assets/images/galeria2002-377x251.jpeg', 'Galeria CCI AL Colombia 2', null, 1),
        ('inicio_gallery', 'assets/images/galeria2003-377x251.jpeg', 'Galeria CCI AL Colombia 3', null, 2),
        ('inicio_gallery', 'assets/images/galeria2004-377x251.jpeg', 'Galeria CCI AL Colombia 4', null, 3),
        ('inicio_gallery', 'assets/images/galeria2005-377x251.jpeg', 'Galeria CCI AL Colombia 5', null, 4),
        ('inicio_gallery', 'assets/images/galeria2006-377x251.jpeg', 'Galeria CCI AL Colombia 6', null, 5)
) as g(section_name, image_url, alt_text, caption, display_order)
where p.slug = 'inicio'
on conflict (page_id, section_name, image_url) do update
set
    alt_text = excluded.alt_text,
    caption = excluded.caption,
    display_order = excluded.display_order,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.gallery_images (page_id, section_name, image_url, alt_text, caption, display_order, is_active)
select p.id, g.section_name, g.image_url, g.alt_text, g.caption, g.display_order, true
from public.pages p
cross join (
    values
        ('store_preview', 'assets/images/features1.jpg', 'Producto CampaTienda 1', null, 0),
        ('store_preview', 'assets/images/features2.jpg', 'Producto CampaTienda 2', null, 1),
        ('store_preview', 'assets/images/features3.jpg', 'Producto CampaTienda 3', null, 2),
        ('store_preview', 'assets/images/features4.jpg', 'Producto CampaTienda 4', null, 3)
) as g(section_name, image_url, alt_text, caption, display_order)
where p.slug = 'campatienda'
on conflict (page_id, section_name, image_url) do update
set
    alt_text = excluded.alt_text,
    caption = excluded.caption,
    display_order = excluded.display_order,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.video_embeds (page_id, youtube_url, title, description, display_order, is_active)
select p.id, v.youtube_url, v.title, v.description, v.display_order, true
from public.pages p
cross join (
    values
        ('https://www.youtube.com/embed/z-62wB_LOAE', 'somos CCI Colombia', null, 0),
        ('https://www.youtube.com/embed/3SzBsdkGUIw', 'SOMOS CCI AL/COLOMBIA', null, 1)
) as v(youtube_url, title, description, display_order)
where p.slug = 'equipados'
on conflict (page_id, youtube_url) do update
set
    title = excluded.title,
    description = excluded.description,
    display_order = excluded.display_order,
    is_active = excluded.is_active,
    updated_at = now();

insert into public.courses (title, subtitle, description, image_url, category, display_order, is_active)
values
    (
        'Construyendo Relaciones',
        'Curso base y puerta de entrada al proceso formativo de CCI AL.',
        'Este curso prepara a los participantes para servir como confidentes, entendiendo que nadie puede dar a otros lo que no ha trabajado primero en su propia vida.',
        'assets/images/construyendo20relaciones-695x899.png',
        'curso',
        0,
        true
    ),
    (
        'Facilitando Acertijos - Basico',
        'Este curso equipa a lideres para facilitar el aprendizaje a traves de la experiencia y la reflexion guiada.',
        'Usa el Ciclo de Kolb de aprendizaje experiencial para elegir actividades que fortalecen el trabajo en equipo, cuidar la seguridad y guiar al grupo a reflexionar.',
        'assets/images/facilitando20acertijos-695x899.png',
        'curso',
        1,
        true
    ),
    (
        'Facilitando Crecimiento',
        'Este curso forma lideres que acompanan procesos de crecimiento espiritual de manera intencional.',
        'Aprendemos a facilitar el crecimiento a traves de la consejeria biblica, la disciplina inductiva y el aprendizaje experiencial.',
        'assets/images/facilitando20crecimiento-695x899.png',
        'curso',
        2,
        true
    ),
    (
        'Programando Campamentos',
        'Este curso equipa lideres para disenar experiencias de campamento que conectan recreacion, comunidad y el mensaje de Cristo.',
        'A traves de un proceso de 12 pasos, aprendemos a crear programas intencionales y contextualizados.',
        'assets/images/programando20campamentos-695x899.png',
        'curso',
        3,
        true
    ),
    (
        'Creando Encuentros Biblicos en Comunidad',
        'Este curso forma lideres con pensamiento biblico, capaces de crear EBC que guian a otros a observar, interpretar y aplicar la Palabra de Dios.',
        'Los Encuentros Biblicos en Comunidad crean espacios donde la Biblia se vive en comunidad.',
        'assets/images/creando20encuentros20biblicos20en20comunidad-695x899.png',
        'curso',
        4,
        true
    ),
    (
        'Taller Reglas del Cerebro',
        null,
        'Aprendemos como funciona el cerebro para ensenar y aprender de manera mas efectiva.',
        'assets/images/portada-dpc-297x385.jpg',
        'taller',
        0,
        true
    ),
    (
        'Taller El Gozo de Trabajo en Equipo',
        null,
        'Descubrimos como nuestras diferencias fortalecen el trabajo en equipo cuando hay unidad.',
        'assets/images/portada-dpc-297x385.jpg',
        'taller',
        1,
        true
    ),
    (
        'Taller ExpoJuegos',
        null,
        'La recreacion con proposito ensena valores y crea ambientes de aprendizaje y comunidad.',
        'assets/images/portada-dpc-297x385.jpg',
        'taller',
        2,
        true
    ),
    (
        'Taller El buen Sembrador: La Flor y La Abeja',
        null,
        'Una forma creativa y profunda de ensenar la Palabra de Dios conectando mente, corazon y accion.',
        'assets/images/portada-dpc-297x385.jpg',
        'taller',
        3,
        true
    ),
    (
        'Zoom de miembros',
        null,
        'Encuentro virtual para miembros de CCI AL Colombia.',
        'assets/images/zoom-1-300x168.jpeg',
        'eventos',
        0,
        true
    ),
    (
        'Taller exclusivo de miembros',
        null,
        'Taller exclusivo para fortalecer la comunion y el aprendizaje de miembros.',
        'assets/images/taller20exclusivo-712x475.jpeg',
        'eventos',
        1,
        true
    ),
    (
        'Encuentro nacional de miembros',
        null,
        'Encuentro nacional para miembros de CCI AL Colombia.',
        'assets/images/encuentro-1-712x949.jpeg',
        'eventos',
        2,
        true
    )
on conflict (title, category) do update
set
    subtitle = excluded.subtitle,
    description = excluded.description,
    image_url = excluded.image_url,
    display_order = excluded.display_order,
    is_active = excluded.is_active,
    updated_at = now();
