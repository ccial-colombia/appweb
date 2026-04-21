# Base de Datos — CCI AL Colombia (Supabase / PostgreSQL)

> **Plataforma:** Supabase (PostgreSQL 15+)
> **Revisado:** April 6, 2026
> **Ver también:** [Plan for CCI AL Colombia.md](Plan%20for%20CCI%20AL%20Colombia.md)

---

## Tabla de Contenidos

1. [Decisiones de Diseño](#1-decisiones-de-diseño)
2. [Diagrama ER](#2-diagrama-er)
3. [Esquema Completo (SQL)](#3-esquema-completo-sql)
4. [Row Level Security (RLS)](#4-row-level-security-rls)
5. [Supabase Storage Buckets](#5-supabase-storage-buckets)
6. [Funciones y Triggers](#6-funciones-y-triggers)
7. [Seed Inicial](#7-seed-inicial)
8. [Tipos Generados (TypeScript)](#8-tipos-generados-typescript)

---

## 1. Decisiones de Diseño

| Decisión | Justificación |
|----------|--------------|
| **UUID como PK** | Convención de Supabase; compatible con `auth.users`; seguro para exponer en URLs |
| **`profiles` en vez de `users`** | Supabase Auth maneja `auth.users`; `profiles` extiende ese registro con datos de la app |
| **RLS en todas las tablas** | La seguridad se aplica en la base de datos — cualquier cliente que acceda a la DB respeta los permisos sin lógica adicional en el backend |
| **`jsonb` para contenido flexible** | `PAGE_SECTIONS` puede guardar estructuras distintas por tipo de sección sin cambios de schema |
| **`text` para strings** | PostgreSQL no tiene overhead al usar `text` vs `varchar(n)`; más flexible |
| **`updated_at` automático** | Trigger `moddatetime` de Supabase actualiza el campo en cada UPDATE |
| **Soft delete con `is_active`** | Preserva historial; permite recuperar registros sin logs adicionales |
| **Supabase Storage para media** | Integrado con RLS; evita servicio externo (Cloudinary, S3) |

---

## 2. Diagrama ER

```mermaid
erDiagram
    AUTH_USERS {
        uuid id PK
        text email
        text encrypted_password
        timestamp created_at
    }

    PROFILES {
        uuid id PK_FK "references auth.users"
        text full_name
        text role "superadmin|admin|editor|member"
        text avatar_url
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    SITE_SETTINGS {
        uuid id PK
        text key UK
        text value
        timestamp updated_at
        uuid updated_by FK
    }

    NAV_ITEMS {
        uuid id PK
        text label
        text url
        boolean is_external
        int display_order
        boolean is_active
    }

    SOCIAL_LINKS {
        uuid id PK
        text platform
        text url
        text icon
        int display_order
        boolean is_active
    }

    PAGES {
        uuid id PK
        text slug UK
        text title
        text meta_description
        boolean requires_auth
        timestamp updated_at
    }

    PAGE_SECTIONS {
        uuid id PK
        uuid page_id FK
        text section_type
        text title
        jsonb content
        text image_url
        int display_order
        boolean is_visible
        timestamp updated_at
        uuid updated_by FK
    }

    COURSES {
        uuid id PK
        text title
        text subtitle
        text description
        text image_url
        text category "course|workshop"
        int display_order
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    PRODUCTS {
        uuid id PK
        text name
        text description
        numeric price
        text currency "COP|USD"
        text image_url
        boolean is_available
        int display_order
        timestamp created_at
        timestamp updated_at
    }

    COMMUNITY_RESOURCES {
        uuid id PK
        text category "finca|transporte|juego|cocina|grafico"
        text title
        text content
        text contact_info
        text location
        text file_url
        int display_order
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    TESTIMONIALS {
        uuid id PK
        text author_name
        text quote
        text author_photo_url
        boolean is_active
        int display_order
        timestamp created_at
    }

    GALLERY_IMAGES {
        uuid id PK
        uuid page_id FK
        text section_name
        text image_url
        text alt_text
        text caption
        int display_order
        boolean is_active
    }

    VIDEO_EMBEDS {
        uuid id PK
        uuid page_id FK
        text youtube_url
        text title
        text description
        int display_order
        boolean is_active
    }

    AUTH_USERS ||--|| PROFILES : "extends"
    PROFILES ||--o{ SITE_SETTINGS : "updated_by"
    PROFILES ||--o{ PAGE_SECTIONS : "updated_by"
    PAGES ||--o{ PAGE_SECTIONS : "contains"
    PAGES ||--o{ GALLERY_IMAGES : "has"
    PAGES ||--o{ VIDEO_EMBEDS : "has"
```

---

## 3. Esquema Completo (SQL)

> Ejecutar en el **SQL Editor** de Supabase, en este orden.

### 3.1 Extensiones

```sql
-- Necesarias para UUIDs y timestamps automáticos
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS moddatetime;
```

### 3.2 Enums

```sql
CREATE TYPE user_role AS ENUM ('superadmin', 'admin', 'editor', 'member');
CREATE TYPE course_category AS ENUM ('course', 'workshop');
CREATE TYPE community_category AS ENUM ('finca', 'transporte', 'juego', 'cocina', 'grafico');
CREATE TYPE section_type AS ENUM ('hero', 'text', 'gallery', 'video', 'cards', 'testimonials', 'custom');
```

### 3.3 Tabla: `profiles`

Extiende `auth.users` con información de perfil y roles de la app.

```sql
CREATE TABLE profiles (
    id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name   text NOT NULL DEFAULT '',
    role        user_role NOT NULL DEFAULT 'member',
    avatar_url  text,
    is_active   boolean NOT NULL DEFAULT true,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Trigger: auto-create profile cuando se registra un usuario en Supabase Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'full_name', ''),
        'member'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger: updated_at automático
CREATE TRIGGER profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
```

### 3.4 Tabla: `site_settings`

Almacena configuraciones globales como clave-valor.

```sql
CREATE TABLE site_settings (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    key         text NOT NULL UNIQUE,  -- e.g. 'site_name', 'logo_url', 'copyright'
    value       text,
    updated_at  timestamptz NOT NULL DEFAULT now(),
    updated_by  uuid REFERENCES profiles(id) ON DELETE SET NULL
);

CREATE TRIGGER site_settings_updated_at
    BEFORE UPDATE ON site_settings
    FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);

-- Índice para búsqueda rápida por key
CREATE INDEX idx_site_settings_key ON site_settings(key);
```

### 3.5 Tabla: `nav_items`

Elementos del menú de navegación.

```sql
CREATE TABLE nav_items (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    label         text NOT NULL,
    url           text NOT NULL,
    is_external   boolean NOT NULL DEFAULT false,
    display_order integer NOT NULL DEFAULT 0,
    is_active     boolean NOT NULL DEFAULT true
);

CREATE INDEX idx_nav_items_order ON nav_items(display_order) WHERE is_active = true;
```

### 3.6 Tabla: `social_links`

Links a redes sociales para el footer.

```sql
CREATE TABLE social_links (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    platform      text NOT NULL,  -- 'facebook', 'instagram', 'youtube', 'email', 'whatsapp'
    url           text NOT NULL,
    icon          text,           -- nombre del ícono Bootstrap Icons, e.g. 'bi-facebook'
    display_order integer NOT NULL DEFAULT 0,
    is_active     boolean NOT NULL DEFAULT true
);
```

### 3.7 Tabla: `pages`

Registro de cada página del sitio.

```sql
CREATE TABLE pages (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug             text NOT NULL UNIQUE,  -- 'inicio', 'equipados', 'exclusivo', etc.
    title            text NOT NULL,
    meta_description text,
    requires_auth    boolean NOT NULL DEFAULT true,
    updated_at       timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER pages_updated_at
    BEFORE UPDATE ON pages
    FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
```

### 3.8 Tabla: `page_sections`

Secciones de contenido de cada página. El campo `content` usa JSONB para flexibilidad.

```sql
CREATE TABLE page_sections (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    page_id       uuid NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
    section_type  section_type NOT NULL DEFAULT 'custom',
    title         text,
    content       jsonb,          -- Estructura flexible por tipo de sección
    image_url     text,
    display_order integer NOT NULL DEFAULT 0,
    is_visible    boolean NOT NULL DEFAULT true,
    updated_at    timestamptz NOT NULL DEFAULT now(),
    updated_by    uuid REFERENCES profiles(id) ON DELETE SET NULL
);

CREATE INDEX idx_page_sections_page ON page_sections(page_id, display_order);

CREATE TRIGGER page_sections_updated_at
    BEFORE UPDATE ON page_sections
    FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
```

**Ejemplos de estructura `content` por tipo de sección:**

```json
// section_type = 'hero'
{
  "headline": "Bienvenidos a CCI AL Colombia",
  "subheadline": "Comunidad cristiana de impacto",
  "cta_text": "Únete",
  "cta_url": "/login"
}

// section_type = 'text'
{
  "body": "<p>Texto enriquecido en HTML...</p>"
}

// section_type = 'cards'
{
  "items": [
    { "title": "Visión", "description": "...", "icon": "bi-eye" },
    { "title": "Misión", "description": "...", "icon": "bi-bullseye" }
  ]
}
```

### 3.9 Tabla: `courses`

Catálogo de cursos y talleres (Exclusivo).

```sql
CREATE TABLE courses (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title         text NOT NULL,
    subtitle      text,
    description   text,
    image_url     text,
    category      course_category NOT NULL DEFAULT 'course',
    display_order integer NOT NULL DEFAULT 0,
    is_active     boolean NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_courses_category ON courses(category, display_order) WHERE is_active = true;

CREATE TRIGGER courses_updated_at
    BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
```

### 3.10 Tabla: `products`

Productos de la CampaTienda.

```sql
CREATE TABLE products (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name          text NOT NULL,
    description   text,
    price         numeric(12, 2),
    currency      text NOT NULL DEFAULT 'COP',
    image_url     text,
    is_available  boolean NOT NULL DEFAULT true,
    display_order integer NOT NULL DEFAULT 0,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_products_order ON products(display_order) WHERE is_available = true;

CREATE TRIGGER products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
```

### 3.11 Tabla: `community_resources`

Recursos de la sección Comunidad: fincas, transporte, juegos, cocina, gráficos.

```sql
CREATE TABLE community_resources (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category      community_category NOT NULL,
    title         text NOT NULL,
    content       text,           -- Descripción, instrucciones, receta, etc.
    contact_info  text,           -- Teléfono, email, WhatsApp
    location      text,           -- Para fincas y transporte
    file_url      text,           -- Para gráficos descargables
    display_order integer NOT NULL DEFAULT 0,
    is_active     boolean NOT NULL DEFAULT true,
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_community_category ON community_resources(category, display_order) WHERE is_active = true;

CREATE TRIGGER community_resources_updated_at
    BEFORE UPDATE ON community_resources
    FOR EACH ROW EXECUTE FUNCTION moddatetime(updated_at);
```

### 3.12 Tabla: `testimonials`

Testimonios de la comunidad.

```sql
CREATE TABLE testimonials (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    author_name      text NOT NULL,
    quote            text NOT NULL,
    author_photo_url text,
    is_active        boolean NOT NULL DEFAULT true,
    display_order    integer NOT NULL DEFAULT 0,
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_testimonials_order ON testimonials(display_order) WHERE is_active = true;
```

### 3.13 Tabla: `gallery_images`

Imágenes de las galerías por página.

```sql
CREATE TABLE gallery_images (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    page_id       uuid NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
    section_name  text,           -- Para identificar la galería dentro de la página
    image_url     text NOT NULL,
    alt_text      text,
    caption       text,
    display_order integer NOT NULL DEFAULT 0,
    is_active     boolean NOT NULL DEFAULT true
);

CREATE INDEX idx_gallery_page ON gallery_images(page_id, display_order) WHERE is_active = true;
```

### 3.14 Tabla: `video_embeds`

Videos de YouTube embebidos (Equipados).

```sql
CREATE TABLE video_embeds (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    page_id       uuid NOT NULL REFERENCES pages(id) ON DELETE CASCADE,
    youtube_url   text NOT NULL,
    title         text,
    description   text,
    display_order integer NOT NULL DEFAULT 0,
    is_active     boolean NOT NULL DEFAULT true
);

CREATE INDEX idx_videos_page ON video_embeds(page_id, display_order) WHERE is_active = true;
```

---

## 4. Row Level Security (RLS)

> **Regla general:** Habilitar RLS en todas las tablas. Sin una política explícita, nadie puede leer ni escribir.

### Función auxiliar: verificar rol del usuario

```sql
-- Función para obtener el rol del usuario actual desde la tabla profiles
CREATE OR REPLACE FUNCTION get_my_role()
RETURNS user_role AS $$
    SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Función auxiliar para verificar si el usuario tiene al menos cierto rol
CREATE OR REPLACE FUNCTION has_role(minimum_role user_role)
RETURNS boolean AS $$
    SELECT CASE
        WHEN minimum_role = 'member'     THEN get_my_role() IN ('member', 'editor', 'admin', 'superadmin')
        WHEN minimum_role = 'editor'     THEN get_my_role() IN ('editor', 'admin', 'superadmin')
        WHEN minimum_role = 'admin'      THEN get_my_role() IN ('admin', 'superadmin')
        WHEN minimum_role = 'superadmin' THEN get_my_role() = 'superadmin'
        ELSE false
    END;
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

### 4.1 Políticas: `profiles`

```sql
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede ver todos los perfiles (para admin panels)
CREATE POLICY "profiles_select_authenticated"
    ON profiles FOR SELECT
    TO authenticated
    USING (true);

-- Cada usuario puede actualizar solo su propio perfil
CREATE POLICY "profiles_update_own"
    ON profiles FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (
        id = auth.uid()
        -- No puede cambiar su propio rol
        AND role = (SELECT role FROM profiles WHERE id = auth.uid())
    );

-- Solo Admin+ puede actualizar roles de otros usuarios
CREATE POLICY "profiles_update_role_admin"
    ON profiles FOR UPDATE
    TO authenticated
    USING (has_role('admin'));
```

### 4.2 Políticas: `site_settings`

```sql
ALTER TABLE site_settings ENABLE ROW LEVEL SECURITY;

-- Cualquiera puede leer las settings (necesario para navbar, footer, etc.)
CREATE POLICY "settings_select_public"
    ON site_settings FOR SELECT
    USING (true);

-- Solo Admin+ puede modificar
CREATE POLICY "settings_write_admin"
    ON site_settings FOR ALL
    TO authenticated
    USING (has_role('admin'))
    WITH CHECK (has_role('admin'));
```

### 4.3 Políticas: `nav_items` y `social_links`

```sql
ALTER TABLE nav_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "nav_select_public" ON nav_items FOR SELECT USING (true);
CREATE POLICY "nav_write_admin"   ON nav_items FOR ALL TO authenticated
    USING (has_role('admin')) WITH CHECK (has_role('admin'));

CREATE POLICY "social_select_public" ON social_links FOR SELECT USING (true);
CREATE POLICY "social_write_admin"   ON social_links FOR ALL TO authenticated
    USING (has_role('admin')) WITH CHECK (has_role('admin'));
```

### 4.4 Políticas: `pages`

```sql
ALTER TABLE pages ENABLE ROW LEVEL SECURITY;

-- Páginas públicas: todos pueden leer
CREATE POLICY "pages_select_public"
    ON pages FOR SELECT
    USING (requires_auth = false);

-- Páginas protegidas: solo usuarios autenticados
CREATE POLICY "pages_select_authenticated"
    ON pages FOR SELECT
    TO authenticated
    USING (requires_auth = true);

-- Solo Editor+ puede modificar metadatos de páginas
CREATE POLICY "pages_write_editor"
    ON pages FOR UPDATE
    TO authenticated
    USING (has_role('editor'))
    WITH CHECK (has_role('editor'));
```

### 4.5 Políticas: `page_sections`

```sql
ALTER TABLE page_sections ENABLE ROW LEVEL SECURITY;

-- Secciones visibles de páginas públicas: lectura pública
CREATE POLICY "sections_select_public"
    ON page_sections FOR SELECT
    USING (
        is_visible = true
        AND EXISTS (
            SELECT 1 FROM pages
            WHERE pages.id = page_sections.page_id
            AND pages.requires_auth = false
        )
    );

-- Secciones de páginas protegidas: solo autenticados
CREATE POLICY "sections_select_authenticated"
    ON page_sections FOR SELECT
    TO authenticated
    USING (is_visible = true);

-- Editor+ puede modificar secciones
CREATE POLICY "sections_write_editor"
    ON page_sections FOR ALL
    TO authenticated
    USING (has_role('editor'))
    WITH CHECK (has_role('editor'));
```

### 4.6 Políticas: Tablas de contenido (cursos, productos, comunidad, testimonios, galería, videos)

```sql
-- Patrón para todas las tablas de contenido protegido:
-- READ: usuarios autenticados (Member+)
-- WRITE: Editor+

ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "courses_select" ON courses FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "courses_write"  ON courses FOR ALL TO authenticated
    USING (has_role('editor')) WITH CHECK (has_role('editor'));
-- SuperAdmin puede ver/eliminar cursos inactivos
CREATE POLICY "courses_select_all_superadmin" ON courses FOR SELECT TO authenticated
    USING (has_role('superadmin'));

ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products_select" ON products FOR SELECT TO authenticated USING (is_available = true);
CREATE POLICY "products_write"  ON products FOR ALL TO authenticated
    USING (has_role('editor')) WITH CHECK (has_role('editor'));
CREATE POLICY "products_select_all_superadmin" ON products FOR SELECT TO authenticated
    USING (has_role('superadmin'));

ALTER TABLE community_resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "community_select" ON community_resources FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "community_write"  ON community_resources FOR ALL TO authenticated
    USING (has_role('editor')) WITH CHECK (has_role('editor'));

ALTER TABLE testimonials ENABLE ROW LEVEL SECURITY;
CREATE POLICY "testimonials_select" ON testimonials FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "testimonials_write"  ON testimonials FOR ALL TO authenticated
    USING (has_role('editor')) WITH CHECK (has_role('editor'));

ALTER TABLE gallery_images ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gallery_select" ON gallery_images FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "gallery_write"  ON gallery_images FOR ALL TO authenticated
    USING (has_role('editor')) WITH CHECK (has_role('editor'));

ALTER TABLE video_embeds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "videos_select" ON video_embeds FOR SELECT TO authenticated USING (is_active = true);
CREATE POLICY "videos_write"  ON video_embeds FOR ALL TO authenticated
    USING (has_role('editor')) WITH CHECK (has_role('editor'));
```

---

## 5. Supabase Storage Buckets

### Configuración de Buckets

```sql
-- Bucket para imágenes y archivos del sitio (no público por defecto)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'media',
    'media',
    false,   -- acceso controlado por RLS
    5242880, -- 5 MB por archivo
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf']
);

-- Bucket para avatares de usuarios (público — URLs estables)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,    -- público para mostrar en perfiles
    2097152, -- 2 MB por avatar
    ARRAY['image/jpeg', 'image/png', 'image/webp']
);
```

### Estructura de carpetas en el bucket `media`

```
media/
├── pages/
│   ├── inicio/          # Imágenes del hero e inicio
│   ├── exclusivo/       # Imágenes de cursos y talleres
│   ├── comunidad/       # Imágenes de recursos comunitarios
│   └── campatienda/     # Imágenes de productos
├── gallery/             # Imágenes de galerías
├── graphics/            # Archivos descargables (gráficos)
└── general/             # Otros archivos
```

### Políticas de Storage

```sql
-- media bucket: Editor+ puede subir
CREATE POLICY "media_upload_editor"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'media'
        AND has_role('editor')
    );

-- media bucket: autenticados pueden leer
CREATE POLICY "media_read_authenticated"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'media');

-- media bucket: Admin+ puede eliminar
CREATE POLICY "media_delete_admin"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'media'
        AND has_role('admin')
    );

-- avatars bucket: cada usuario sube/modifica solo su avatar
CREATE POLICY "avatars_upload_own"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

CREATE POLICY "avatars_update_own"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'avatars'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- avatars bucket: lectura pública (el bucket es público)
CREATE POLICY "avatars_read_public"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');
```

---

## 6. Funciones y Triggers

### 6.1 Trigger: `updated_at` automático

El trigger `moddatetime` de Supabase se aplica en todas las tablas que tienen `updated_at`. Ya configurado en cada `CREATE TABLE` de la Sección 3.

### 6.2 Función: Promover usuario a rol

Solo ejecutable desde el backend con service role key.

```sql
CREATE OR REPLACE FUNCTION promote_user(target_user_id uuid, new_role user_role)
RETURNS void AS $$
BEGIN
    -- Solo superadmin puede promover a admin o superadmin
    IF new_role IN ('admin', 'superadmin') AND NOT has_role('superadmin') THEN
        RAISE EXCEPTION 'Solo un superadmin puede asignar roles de admin o superadmin';
    END IF;

    -- Editor+ puede promover a member o editor
    IF NOT has_role('admin') THEN
        RAISE EXCEPTION 'Permisos insuficientes para cambiar roles';
    END IF;

    UPDATE profiles SET role = new_role WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 6.3 Función: Reordenar elementos

Utilidad para actualizar `display_order` en cualquier tabla de forma atómica.

```sql
CREATE OR REPLACE FUNCTION reorder_items(
    table_name text,
    ordered_ids uuid[]
)
RETURNS void AS $$
DECLARE
    i integer;
BEGIN
    FOR i IN 1..array_length(ordered_ids, 1) LOOP
        EXECUTE format(
            'UPDATE %I SET display_order = $1 WHERE id = $2',
            table_name
        ) USING i - 1, ordered_ids[i];
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 7. Seed Inicial

Datos iniciales para poblar la base de datos desde el contenido actual del sitio estático.

```sql
-- =============================================
-- PAGES
-- =============================================
INSERT INTO pages (slug, title, meta_description, requires_auth) VALUES
    ('landing',     'CCI AL Colombia',      'Comunidad cristiana de impacto',    false),
    ('inicio',      'Inicio',               'Página de inicio para miembros',    true),
    ('equipados',   'Equipados',            'Videos y recursos de formación',    true),
    ('exclusivo',   'Exclusivo',            'Cursos y talleres exclusivos',      true),
    ('comunidad',   'Comunidad',            'Recursos de la comunidad',          true),
    ('campatienda', 'CampaTienda',          'Tienda de la comunidad',            true);

-- =============================================
-- NAV ITEMS
-- =============================================
INSERT INTO nav_items (label, url, display_order, is_active) VALUES
    ('Inicio',      '/inicio',      0, true),
    ('Equipados',   '/equipados',   1, true),
    ('Exclusivo',   '/exclusivo',   2, true),
    ('Comunidad',   '/comunidad',   3, true),
    ('CampaTienda', '/campatienda', 4, true);

-- =============================================
-- SITE SETTINGS
-- =============================================
INSERT INTO site_settings (key, value) VALUES
    ('site_name',    'CCI AL Colombia'),
    ('logo_url',     '/images/logo.png'),
    ('copyright',    '© 2026 CCI AL Colombia. Todos los derechos reservados.'),
    ('hero_headline','Bienvenidos a CCI AL Colombia'),
    ('hero_subtext', 'Comunidad cristiana de impacto');

-- =============================================
-- SOCIAL LINKS
-- =============================================
INSERT INTO social_links (platform, url, icon, display_order) VALUES
    ('facebook',  'https://facebook.com/ccialcol',  'bi-facebook',  0),
    ('instagram', 'https://instagram.com/ccialcol', 'bi-instagram', 1),
    ('youtube',   'https://youtube.com/@ccialcol',  'bi-youtube',   2),
    ('whatsapp',  'https://wa.me/57XXXXXXXXXX',     'bi-whatsapp',  3);

-- =============================================
-- COURSES (Exclusivo)
-- =============================================
INSERT INTO courses (title, subtitle, description, category, display_order) VALUES
    ('Curso 1', 'Subtítulo del curso', 'Descripción del curso...', 'course',    0),
    ('Curso 2', 'Subtítulo del curso', 'Descripción del curso...', 'course',    1),
    ('Taller 1','Subtítulo del taller','Descripción del taller...','workshop',  0),
    ('Taller 2','Subtítulo del taller','Descripción del taller...','workshop',  1);

-- Nota: completar con el contenido real del HTML actual de exclusivo.html

-- =============================================
-- COMMUNITY RESOURCES (Comunidad)
-- =============================================
INSERT INTO community_resources (category, title, content, display_order) VALUES
    ('finca',      'Finca 1',       'Descripción de la finca...',   0),
    ('transporte', 'Transporte 1',  'Servicio de transporte...',    0),
    ('juego',      'Juego 1',       'Instrucciones del juego...',   0),
    ('cocina',     'Receta 1',      'Ingredientes e instrucciones...', 0),
    ('grafico',    'Plantilla 1',   'Plantilla descargable...',     0);

-- Nota: completar con el contenido real del HTML actual de comunidad.html
```

---

## 8. Tipos Generados (TypeScript)

Supabase genera tipos TypeScript automáticamente. Ejecutar:

```bash
npx supabase gen types typescript --project-id YOUR_PROJECT_ID > lib/supabase/database.types.ts
```

Esto genera tipos como:

```typescript
// Ejemplo del tipo generado para la tabla courses
export type Course = Database['public']['Tables']['courses']['Row']
export type CourseInsert = Database['public']['Tables']['courses']['Insert']
export type CourseUpdate = Database['public']['Tables']['courses']['Update']

// Uso en componentes:
import type { Course } from '@/lib/supabase/database.types'

const { data: courses } = await supabase
    .from('courses')
    .select('*')
    .returns<Course[]>()
```

---

## Resumen de Tablas

| Tabla | Filas estimadas | RLS | Acceso lectura | Acceso escritura |
|-------|----------------|-----|----------------|-----------------|
| `profiles` | ~50–200 | ✅ | Autenticado | Propio / Admin+ |
| `site_settings` | ~20 | ✅ | Público | Admin+ |
| `nav_items` | ~5–10 | ✅ | Público | Admin+ |
| `social_links` | ~4–6 | ✅ | Público | Admin+ |
| `pages` | 6 | ✅ | Público / Autenticado | Editor+ |
| `page_sections` | ~30–50 | ✅ | Público / Autenticado | Editor+ |
| `courses` | ~10–20 | ✅ | Member+ | Editor+ |
| `products` | ~10–50 | ✅ | Member+ | Editor+ |
| `community_resources` | ~20–100 | ✅ | Member+ | Editor+ |
| `testimonials` | ~5–20 | ✅ | Member+ | Editor+ |
| `gallery_images` | ~10–30 | ✅ | Member+ | Editor+ |
| `video_embeds` | ~10–50 | ✅ | Member+ | Editor+ |

**Total estimado:** < 400 filas — perfectamente dentro del free tier de Supabase (500 MB).

---

*Documento creado: April 6, 2026*
