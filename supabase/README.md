# Supabase setup

Este directorio prepara la base de datos de CCI AL Colombia para Supabase.

## Archivos

- `migrations/20260623000000_initial_schema.sql`: esquema inicial, RLS, funciones, triggers y buckets de Storage.
- `seed.sql`: datos base del sitio actual: paginas, navegacion, redes, secciones principales, galerias, videos, cursos, talleres y eventos.
- `supabase_backend.sql`: tablas que usa el panel `admin.html` (fincas, transporte, juegos, cocina, graficos, testimonios, cursos, talleres, videos, informacion_general, psw_change).
- `secciones_visibilidad.sql`: agrega a `informacion_general` las columnas `pagina`, `orden` y `visible`, y carga el catalogo de secciones visuales de cada pagina.
- `contenido_secciones.sql`: crea la tabla `contenido_secciones`, que asocia cada seccion (`informacion_general.clave`) con un texto con formato editable desde el panel.
- `cursos_talleres.sql` / `cursos_talleres_datos.sql`: nueva estructura de `cursos` y `talleres` (imagen, nombre, descripcion corta, descripcion, orden, visible) y carga de los datos actuales.

## Secciones visuales

Cada bloque administrable del HTML lleva `data-seccion="clave"` y `assets/js/secciones.js`
(incluido en el `<head>` de cada pagina) consulta `informacion_general` filtrando por el
nombre del archivo. Los bloques con `visible = false` se quitan al cargar la pagina; los
que no tengan fila en la tabla se muestran siempre.

Para agregar una seccion nueva: pon `data-seccion="pagina.clave"` en el HTML e inserta la
fila correspondiente en `informacion_general` (o desde el panel, en "Secciones de la web").

## Contenido de secciones

La tabla `contenido_secciones` guarda un texto con formato por seccion. Desde el panel,
en "Contenido de secciones", se elige la seccion en un desplegable y se escribe el texto
en un editor embebido (Quill).

Para mostrar ese texto en una pagina, agrega un marcador donde quieras que aparezca:

```html
<div data-contenido="comunidad.fincas"></div>
```

`secciones.js` detecta esos marcadores, consulta `contenido_secciones` y reemplaza su
contenido con el HTML guardado. Si una pagina no tiene marcadores, no se hace la consulta.

## Orden de ejecucion

1. Crea el proyecto en Supabase.
2. Ejecuta la migracion SQL.
3. Ejecuta `seed.sql`.
4. Crea el primer usuario desde Supabase Auth.
5. Promueve ese usuario a `superadmin` desde el SQL Editor:

```sql
update public.profiles
set role = 'superadmin'
where id = '<AUTH_USER_ID>';
```

## Notas

- `products`, `community_resources` y `testimonials` quedan listos, pero sin seed de contenido porque el HTML actual tiene productos sin datos completos, recursos comunitarios vacios y testimonios de plantilla.
- El bucket `media` es privado y se lee por usuarios autenticados. El bucket `avatars` es publico.
- Las paginas antiguas `valores`, `normas` y `enciclopedia` se incluyen en `pages`, pero quedan inactivas en la navegacion principal.
