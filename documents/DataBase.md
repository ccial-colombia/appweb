# Base de datos (Supabase)

Estado de la base después de ejecutar `supabase/limpieza_tablas_sin_uso.sql`, que borra las
tablas del esquema inicial que la aplicación no usa (`profiles`, `site_settings`, `social_links`, `pages`, `products`, `testimonials`, `video_embeds`).

| Tabla | La usa | Para qué |
|---|---|---|
| `psw_change` (+ función `validar_password`) | `index.html`, panel | Contraseña de acceso de miembros |
| `informacion_general` | todas las páginas, panel | Catálogo de secciones y textos; mostrar u ocultar cada uno |
| `contenido_secciones` | todas las páginas, panel | Textos editables (`data-contenido`) |
| `imagenes_sitio` | todas las páginas, panel | Imágenes editables (`data-imagen`) |
| `fincas`, `transporte`, `cocina`, `testimonios` | `comunidad.html`, `testimonio.html`, panel | Recursos de la comunidad y testimonios |
| `cursos`, `talleres` | `exclusivo.html`, panel | Cursos y talleres |
| `videos` | `equipados.html`, panel | Videos exclusivos |
| `descargables` | `equipados.html`, panel | Recursos descargables (PDF) |
| `productos` | `campatienda.html`, panel | Catálogo de CampaTienda |
| `anuncios` | `index.html`, `inicio.html`, panel | Anuncios del carrusel de bienvenida y de la sección "Anuncios" de Inicio (con fechas) |
| `articulos` | `elpunto.html`, `articulo.html`, panel | Artículos de la revista virtual El Punto |
| `menu` | páginas con menú superior, panel | Opciones del menú superior (texto, enlace, orden) |
| `estilos_titulos` | todas las páginas, panel | Tipo de letra, tamaño y color de títulos y subtítulos |

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
| `titulo` | `text` |  Nullable (opcional; `testimonios_titulo.sql`) |

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

## Table `descargables`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `categoria` | `text` |  Check (`isl`, `juegos`) |
| `titulo` | `text` |  |
| `descripcion` | `text` |  Nullable |
| `archivo_url` | `text` |  |
| `tamano_bytes` | `int4` |  Nullable |
| `imagen_url` | `text` |  Nullable |
| `orden` | `int4` |  |
| `visible` | `bool` |  |

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

## Table `anuncios`

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `imagen_url` | `text` |  |
| `titulo` | `text` |  |
| `enlace` | `text` |  Nullable |
| `fecha_inicio` | `date` |  Default: hoy (hora de Colombia) |
| `fecha_fin` | `date` |  Check (`fecha_fin >= fecha_inicio`) |
| `orden` | `int4` |  |
| `visible` | `bool` |  |

## Table `articulos`

Sin columna `orden`: se ordena por `fecha_ingreso` (del más nuevo al más viejo) y luego por `id`.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `titulo` | `text` |  |
| `autor` | `text` |  Nullable |
| `rol` | `text` |  Nullable |
| `foto_url` | `text` |  Nullable |
| `contenido` | `text` |  |
| `fecha_ingreso` | `date` |  Default: hoy (hora de Colombia) |
| `visible` | `bool` |  |

## Table `menu`

`secciones.js` arma el menú superior con las filas visibles, ordenadas por `orden` y luego `id`.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `etiqueta` | `text` |  |
| `enlace` | `text` |  |
| `nueva_pestana` | `bool` |  Default: false |
| `orden` | `int4` |  |
| `visible` | `bool` |  |

## Table `estilos_titulos`

Una fila por grupo de títulos (`titulos`, `subtitulos`, `tarjetas`); las crea `estilos_titulos.sql` y el panel solo las edita. `secciones.js` las aplica en todas las páginas. Vacío = original.

### Columns

| Name | Type | Constraints |
|------|------|-------------|
| `id` | `int4` | Primary |
| `clave` | `text` |  Unique |
| `nombre` | `text` |  |
| `descripcion` | `text` |  Nullable |
| `fuente` | `text` |  Nullable; letras, números y espacios |
| `tamano` | `int4` |  Nullable; 50 a 200 (% del original) |
| `color` | `text` |  Nullable; `#rrggbb` |
| `orden` | `int4` |  Default: 0 |

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

### `cocina`

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

### `descargables`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `(visible = true)` | — |

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

### `anuncios`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `visible = true and (now() at time zone 'America/Bogota')::date between fecha_inicio and fecha_fin` | — |

### `articulos`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `visible = true` | — |

### `menu`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `visible = true` | — |

### `estilos_titulos`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |

### `imagenes_sitio`

| Policy | Command | Roles | Action | USING | WITH CHECK |
|--------|---------|-------|--------|-------|------------|
| `admin total` | ALL | authenticated | PERMISSIVE | `true` | `true` |
| `lectura publica` | SELECT | public | PERMISSIVE | `true` | — |
