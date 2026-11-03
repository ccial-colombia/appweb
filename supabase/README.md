# Supabase setup

Este directorio prepara la base de datos de CCI AL Colombia para Supabase.

## Tablas que usa la aplicacion

| Tabla | La usa | Para que |
|---|---|---|
| `psw_change` (+ funcion `validar_password`) | `index.html`, panel | Contraseña de acceso de miembros |
| `informacion_general` | todas las paginas, panel | Catalogo de secciones y textos; mostrar u ocultar cada uno |
| `contenido_secciones` | todas las paginas, panel | Textos editables (`data-contenido`) |
| `imagenes_sitio` | todas las paginas, panel | Imagenes editables (`data-imagen`) |
| `fincas`, `transporte`, `juegos`, `cocina`, `graficos`, `testimonios` | `comunidad.html`, `testimonio.html`, panel | Recursos de la comunidad y testimonios |
| `cursos`, `talleres` | `exclusivo.html`, panel | Cursos y talleres |
| `videos` | `equipados.html`, panel | Videos exclusivos |
| `descargables` | `equipados.html`, panel | Recursos descargables (PDF de ISL y de la Enciclopedia de Juegos) |
| `productos` | `campatienda.html`, panel | Catalogo de CampaTienda |

Buckets de Storage: `contenido` (imagenes de cursos, talleres, productos, portadas de descargables e imagenes del sitio), `testimonios` (fotos de testimonios) y `descargables` (PDF de recursos descargables; solo acepta PDF).

## Archivos

- `supabase_setup.sql`: tabla `psw_change` y funcion `validar_password` (acceso de miembros).
- `supabase_contenido.sql`: tablas de la pagina Comunidad (fincas, transporte, juegos, cocina, graficos, testimonios) con datos de ejemplo.
- `supabase_backend.sql`: tablas `cursos`, `talleres`, `videos`, `informacion_general` y `contenido_secciones`, y permisos de administracion para usuarios autenticados.
- `supabase_migracion_fincas.sql` / `supabase_migracion_fotos_testimonios.sql`: columnas `ciudad` y `capacidad` en fincas, foto en testimonios y bucket `testimonios`.
- `secciones_visibilidad.sql`: agrega a `informacion_general` las columnas `pagina`, `orden` y `visible`, y carga el catalogo de secciones visuales de cada pagina.
- `contenido_secciones.sql`: crea la tabla `contenido_secciones`, que asocia cada seccion (`informacion_general.clave`) con un texto con formato editable desde el panel.
- `contenido_inicio.sql`: precarga los textos de `inicio.html` (encabezado, vision, mision, quienes somos).
- `cursos_talleres.sql` / `cursos_talleres_datos.sql`: nueva estructura de `cursos` y `talleres` (imagen, nombre, descripcion corta, descripcion, orden, visible) y carga de los datos actuales.
- `campatienda_productos.sql`: crea la tabla `productos` (foto, nombre, descripcion, precio, tallas u opciones, disponible, orden, visible) que muestra `campatienda.html` y se administra en el panel, pestaña "CampaTienda". Carga los 7 productos iniciales con sus fotos de `assets/images/campatienda/`. Se puede ejecutar mas de una vez.
- `imagenes_sitio.sql`: crea la tabla `imagenes_sitio` con las 61 imagenes fijas del sitio (logo, favicon, portadas, galeria, tomos, normas, valores y fondos) para cambiarlas desde el panel, pestaña "Imagenes del sitio". Se puede ejecutar mas de una vez sin perder los cambios hechos en el panel.
- `textos_editables.sql`: registra los 123 textos de las paginas (titulos y parrafos con `data-contenido`) en `informacion_general` y copia su texto actual a `contenido_secciones`, para editarlos en el panel, pestaña "Contenido de secciones". Se puede ejecutar mas de una vez sin perder los cambios hechos en el panel.
- `recursos_descargables.sql`: crea la tabla `descargables` (tipo `isl` o `juegos`, titulo, descripcion, PDF, tamaño, portada opcional, orden, visible) y el bucket `descargables` (solo PDF). `equipados.html` la muestra en "3. Recursos descargables", agrupada por tipo, y se administra en el panel, pestaña "Recursos descargables". Tambien registra la seccion `equipados.descargables` y sus 4 textos editables. Se puede ejecutar mas de una vez sin perder los cambios hechos en el panel.
- `limpieza_tablas_sin_uso.sql`: borra las tablas, funciones, tipos y el trigger de `auth.users` del esquema inicial que la aplicacion nunca uso (`profiles`, `site_settings`, `social_links`, `pages`, `products`, `testimonials`, `video_embeds`, ...). Solo hace falta en bases creadas con ese esquema.

El esquema inicial que creaba esas tablas (`migrations/20260623000000_initial_schema.sql` y `seed.sql`) se movio a `not_used/supabase/` para que no se vuelva a ejecutar.

## Secciones visuales

Cada bloque administrable del HTML lleva `data-seccion="clave"` y `assets/js/secciones.js`
(incluido en el `<head>` de cada pagina) consulta `informacion_general` filtrando por el
nombre del archivo. Los bloques con `visible = false` se quitan al cargar la pagina; los
que no tengan fila en la tabla se muestran siempre.

Para agregar una seccion nueva: pon `data-seccion="pagina.clave"` en el HTML e inserta la
fila correspondiente en `informacion_general` (o desde el panel, en "Secciones de la web").

## Textos editables (Contenido de secciones)

Cada texto administrable del HTML lleva `data-contenido="clave"`, con una fila en
`informacion_general` (para elegirlo en el panel) y su texto en `contenido_secciones`:

```html
<h6 data-contenido="valores.valor_01_titulo" class="card-title mbr-fonts-style display-2"><strong>Dependencia de Dios</strong></h6>
<p data-contenido="valores.valor_01_texto" class="mbr-text mbr-fonts-style display-7">Creemos que Dios es soberano...</p>
<div data-contenido="inicio.quienes_somos" class="mbr-text mbr-fonts-style display-7 mb-3">...</div>
```

`secciones.js` consulta `contenido_secciones` con las claves de la pagina y pone el texto
guardado antes de mostrar la pagina:

- En titulos y parrafos (`h1`-`h6`, `p`, ...) cada linea del editor se pone separada con
  `<br>`, y el elemento conserva su clase, tamaño y color.
- En un `div` se pone el HTML del editor tal cual (parrafos, listas, alineacion).
- Si la clave no tiene texto guardado, o la consulta falla, queda el texto del HTML.
- Si la fila de `informacion_general` tiene `visible = false`, el texto se quita de la pagina.
- La clave `global.copyright` (pie de pagina) se usa en todas las paginas.

En el panel, "Contenido de secciones" se puede filtrar por pagina; el desplegable de
secciones esta agrupado por pagina.

Para hacer editable un texto nuevo: pon `data-contenido="pagina.nombre"` en el elemento,
inserta su fila en `informacion_general` y luego escribe el texto en el panel.

## Imagenes del sitio

Cada imagen fija del HTML lleva `data-imagen="clave"`:

```html
<img data-imagen="inicio.vision_mision" src="assets/images/vision20y20mision-1101x734.jpeg" alt="">
<section data-seccion="valores.encabezado" data-imagen="valores.fondo">  <!-- imagen de fondo -->
<link rel="icon" href="assets/images/favicon-192x192.png" data-imagen="global.favicon">
```

`secciones.js` consulta `imagenes_sitio` con las claves de la pagina y cambia la imagen
(`src` en `<img>`, `href` en el favicon, imagen de fondo en cualquier otro elemento) antes
de mostrarla. Si la clave no tiene imagen guardada, o la consulta falla, queda la del HTML.
Las claves `global.*` (logo y favicon) se usan en todas las paginas.

Las imagenes de cursos, talleres, testimonios y productos se administran en sus propias
pestañas del panel.

## Orden de ejecucion (base nueva)

1. Crea el proyecto en Supabase.
2. En el SQL Editor ejecuta, en este orden:
   1. `supabase_setup.sql`
   2. `supabase_contenido.sql`
   3. `supabase_backend.sql`
   4. `supabase_migracion_fincas.sql`
   5. `supabase_migracion_fotos_testimonios.sql`
   6. `secciones_visibilidad.sql`
   7. `contenido_secciones.sql`
   8. `contenido_inicio.sql`
   9. `cursos_talleres.sql`
   10. `cursos_talleres_datos.sql`
   11. `campatienda_productos.sql`
   12. `imagenes_sitio.sql`
   13. `textos_editables.sql`
   14. `recursos_descargables.sql`
3. Authentication > Users > Add user: crea el usuario administrador ("Auto Confirm User").
4. Authentication > Sign In / Providers: desactiva "Allow new users to sign up".
5. Carga la contraseña de miembros desde el panel (Contraseñas de acceso).

En la base actual (que se creo con el esquema inicial) ejecuta ademas, una vez,
`limpieza_tablas_sin_uso.sql`.
