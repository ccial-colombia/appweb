# Supabase setup

Este directorio prepara la base de datos de CCI AL Colombia para Supabase.

## Archivos

- `migrations/20260623000000_initial_schema.sql`: esquema inicial, RLS, funciones, triggers y buckets de Storage.
- `seed.sql`: datos base del sitio actual: paginas, navegacion, redes, secciones principales, galerias, videos, cursos, talleres y eventos.

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
