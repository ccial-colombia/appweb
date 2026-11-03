# Base de datos (Supabase)

Estado de la base después de ejecutar `supabase/limpieza_tablas_sin_uso.sql`, que borra las
tablas del esquema inicial que la aplicación no usa (`profiles`, `site_settings`, `social_links`, `pages`, `products`, `testimonials`, `video_embeds`).

| Tabla | La usa | Para qué |
|---|---|---|
| `psw_change` (+ función `validar_password`) | `index.html`, panel | Contraseña de acceso de miembros |
| `informacion_general` | todas las páginas, panel | Catálogo de secciones y textos; mostrar u ocultar cada uno |
| `contenido_secciones` | todas las páginas, panel | Textos editables (`data-contenido`) |
| `imagenes_sitio` | todas las páginas, panel | Imágenes editables (`data-imagen`) |
| `fincas`, `transporte`, `juegos`, `cocina`, `graficos`, `testimonios` | `comunidad.html`, `testimonio.html`, panel | Recursos de la comunidad y testimonios |
| `cursos`, `talleres` | `exclusivo.html`, panel | Cursos y talleres |
| `videos` | `equipados.html`, panel | Videos exclusivos |
| `productos` | `campatienda.html`, panel | Catálogo de CampaTienda |

## Table `psw_change`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `correlativo` | `int4` | Primary |
| `fecha` | `date` |  |
| `contrasenia` | `text` |  |

## Table `fincas`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `lugar` | `text` |  Nullable |
| `contacto` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |
| `ciudad` | `text` |  Nullable |
| `capacidad` | `int4` |  Nullable |

## Table `transporte`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `lugar` | `text` |  Nullable |
| `contacto` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |

## Table `juegos`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `lugar` | `text` |  Nullable |
| `contacto` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |

## Table `cocina`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `lugar` | `text` |  Nullable |
| `contacto` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |

## Table `graficos`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `lugar` | `text` |  Nullable |
| `contacto` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |

## Table `testimonios`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `rol` | `text` |  Nullable |
| `mensaje` | `text` |  |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |
| `foto_url` | `text` |  Nullable |

## Table `cursos`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `descripcion` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |
| `imagen_url` | `text` |  Nullable |
| `descripcion_corta` | `text` |  Nullable |

## Table `talleres`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `nombre` | `text` |  |
| `descripcion` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |
| `imagen_url` | `text` |  Nullable |
| `descripcion_corta` | `text` |  Nullable |

## Table `videos`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `titulo` | `text` |  |
| `url` | `text` |  |
| `descripcion` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  Nullable |

## Table `informacion_general`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `clave` | `text` |  Unique |
| `titulo` | `text` |  Nullable |
| `contenido` | `text` |  Nullable |
| `pagina` | `text` |  Nullable |
| `orden` | `int4` |  Nullable |
| `visible` | `bool` |  |

## Table `contenido_secciones`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `seccion_clave` | `text` |  Unique |
| `contenido` | `text` |  Nullable |
| `updated_at` | `timestamptz` |  |

## Table `productos`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `imagen_url` | `text` |  Nullable |
| `nombre` | `text` |  |
| `descripcion` | `text` |  Nullable |
| `precio` | `int4` |  Nullable |
| `opciones` | `text` |  Nullable |
| `disponible` | `bool` |  |
| `orden` | `int4` |  |
| `visible` | `bool` |  |

## Table `imagenes_sitio`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `clave` | `text` |  Unique |
| `pagina` | `text` |  Nullable |
| `titulo` | `text` |  |
| `imagen_url` | `text` |  Nullable |
| `alt` | `text` |  Nullable |
| `orden` | `int4` |  |

## RLS Policies

### `psw_change`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |

### `testimonios`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `transporte`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `juegos`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `cocina`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `graficos`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `fincas`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `contenido_secciones`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `videos`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `cursos`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `talleres`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `informacion_general`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `productos`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `(visible = true)` | — |

### `imagenes_sitio`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |
