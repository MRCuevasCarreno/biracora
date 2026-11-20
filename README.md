# Bitácora Mecánica — prototipo visual

Maqueta interactiva para revisar la interfaz de la bitácora. Solo usa datos ficticios en memoria del navegador; no se conecta a Supabase, Google Sheets ni Google Drive y no está lista para producción. No hay proyectos ni cuentas remotas, facturación ni despliegues. El esquema se probó únicamente en una instancia local de Supabase con fixtures ficticios.

## Arquitectura elegida para evaluar

La dirección acordada es Supabase Auth, Postgres con Row Level Security (RLS) y Storage privado para las fotos. Los registros y fotos se alojarían en Supabase, no en el Drive personal de Matías. Esta arquitectura aún no está conectada a la maqueta ni desplegada.

La matriz de permisos de la futura base de datos es:

| Operación | ADMIN | MECHANIC |
| --- | --- | --- |
| Listar y leer trabajos | Todos | Todos |
| Crear trabajos | Sí | Sí |
| Editar trabajos | Todos | Solo los creados por ese usuario |
| Eliminar trabajos | Todos | No |
| Leer y agregar fotos | Según acceso al trabajo | Según acceso al trabajo |
| Eliminar fotos | Sí | No |

Roles y autoría deben derivarse de la identidad autenticada en la base de datos, nunca del selector ni de valores de rol enviados por el cliente. Una clave privilegiada de Supabase nunca debe incluirse en el navegador.

## Estado actual y límites

- `index.html`, `Styles.html` y `Client.html` presentan la maqueta visual: búsqueda exacta por patente normalizada, detalle, impresión y formularios de ejemplo.
- El selector Matías/Admin y Marco/Mecánico es una simulación local, no es inicio de sesión ni prueba de identidad.
- Crear, editar, eliminar y agregar/quitar elementos de fotos solo cambia los ejemplos de la página. Los cambios se pierden al recargar. No se seleccionan ni transfieren archivos.
- `Code.gs` y `appsscript.json` pertenecen al prototipo anterior de Apps Script. `APP_CONFIG.liveModeEnabled` permanece desactivado, no hay usuarios autorizados configurados y las funciones de API rechazan operaciones reales. No lo cambies a `true`.
- `supabase/migrations/20261119210000_initial_rls_schema.sql` define el esquema y las políticas RLS. Se aplicó únicamente a la base Supabase local de pruebas; no hay proyecto, cuentas ni tablas alojados, ni permisos remotos ni despliegues configurados.
- `supabase/tests/database/rls.sql` contiene pruebas pgTAP con usuarios, trabajos y fotos ficticios; no crea cuentas utilizables ni usa contraseñas reales.
- No se ha conectado Supabase ni existe código de persistencia real. No introduzcas datos ni fotos reales.

La interfaz puede ocultar acciones según el rol simulado para facilitar la revisión visual; eso no es un control de seguridad. No se afirma que la autenticación o el control de acceso estén listos para producción.

## Probar la maqueta

1. Abre la vista previa independiente generada para la sesión. `index.html` contiene plantillas de Apps Script y no funciona directamente como archivo local.
2. Prueba `DE-MO-03`, `de mo 03` y `DEMO03`: deben encontrar el mismo registro ficticio. La búsqueda es exacta después de ignorar mayúsculas, espacios y guiones.
3. Cambia el selector entre Matías y Marco. Como Marco, verifica que se puede editar un ejemplo creado por Marco, pero no uno creado por Matías, y que no aparece la acción de eliminar.
4. Como Matías, prueba eliminar un ejemplo y quitar una foto de ejemplo. Estas acciones no afectan archivos ni datos persistentes.
5. Crea y edita ejemplos, usa la impresión y recarga para comprobar que la lista vuelve a sus registros iniciales.
6. Usa solo datos inventados. No configures un proyecto, no conectes credenciales y no uses la maqueta con información real.

La página no llama `google.script.run`, no usa `fetch` para acceder a servicios, no carga ni almacena credenciales y no persiste cambios en `localStorage` o `sessionStorage`.

## Esquema y pruebas de seguridad (solo local, sin desplegar)

La migración define `profiles` ligado a `auth.users`, `jobs` con autoría y `job_photos` con metadatos/ruta de almacenamiento. Un trigger crea cada perfil como `MECHANIC`, sin confiar en metadatos del usuario. La migración no concede a clientes permisos para insertar/cambiar IDs, autoría o roles; la política de rol no permite escrituras desde el cliente.

### Asignación inicial de ADMIN (procedimiento elegido; pendiente)

Para este prototipo se elige una única asignación inicial y manual: Matías será el único ADMIN. No se construirá un flujo recurrente de administración desde un backend. Esto no crea una cuenta ni asigna el rol ahora: no hay proyecto remoto ni identidad de Supabase que se pueda verificar. El nombre “Matías” por sí solo no identifica de forma segura una cuenta; antes de la operación habrá que comprobar la identidad autenticada y su UUID exacto.

Cuando exista un proyecto real y una persona operadora autorizada pueda acceder a su canal administrativo confiable:

1. Matías crea y verifica su propia cuenta de Supabase Auth por el proceso normal. No compartir contraseñas ni usar metadatos de Auth para otorgar el rol.
2. La persona operadora inicia sesión en el panel administrativo del proyecto correcto y confirma que no haya otro perfil `ADMIN`. Identifica el perfil de Matías mediante la cuenta verificada y comprueba su UUID y rol actual. Si hay cero o más de una coincidencia, o ya existe otro `ADMIN`, se detiene y resuelve la identidad/situación antes de cambiar nada.
3. En el SQL Editor del proyecto correcto, la persona operadora ejecuta una sola actualización reemplazando el marcador por el UUID que verificó. El UUID debe coincidir con Matías; no se debe buscar ni asignar por nombre:

   ```sql
   update public.profiles
   set role = 'ADMIN'
   where id = '<UUID_VERIFICADO_DE_MATIAS>'::uuid
     and role = 'MECHANIC'
   returning id, role;
   ```

   Solo se continúa si la consulta devuelve exactamente el UUID confirmado y el rol `ADMIN`. Si no devuelve una fila, se detiene y se investiga; no se amplía el filtro ni se repite a ciegas.
4. La persona operadora verifica que ese perfil sea el único `ADMIN` y registra en el registro operativo quién hizo el cambio, cuándo, el proyecto y el UUID verificado. No registra contraseñas, tokens ni claves. Cualquier corrección o cambio posterior de rol requiere de nuevo una operación administrativa autorizada.

Este procedimiento es una guía para una futura operación, no una migración ni una consulta ejecutada. Nunca se debe efectuar desde el cliente, el selector visual, ni con una clave privilegiada en el navegador. No demuestra que el sistema esté listo para producción.

Las políticas RLS cubren llamadas directas a las tablas y a `storage.objects`: ambos roles pueden leer todos los trabajos visibles y agregar metadatos/fotos; mecánicos solo actualizan trabajos propios; solo ADMIN puede borrar trabajos, metadatos y archivos. El bucket privado `work-photos` permite JPEG, PNG y WebP, con un máximo de 10 MiB por archivo; HEIC no está permitido. La configuración local mantiene además un límite global de 50 MiB. La migración `20261120112500_photo_upload_limits.sql` aplica los mismos límites al bucket y a los metadatos. Estos controles de metadatos no verifican que el MIME y el tamaño registrados correspondan a los bytes reales del archivo. El archivo debe tener una fila de metadatos antes de poder cargarse; la lectura requiere metadatos asociados. El borrado de un trabajo elimina metadatos en cascada, no los objetos de Storage: antes de borrar, un futuro cliente debe coordinar la limpieza de archivos. ADMIN puede borrar objetos huérfanos. No hay código de carga ni pruebas contra la API de Storage en este prototipo; tampoco se configuran aquí enlaces firmados ni un proceso administrativo.

Las pruebas usan únicamente identidades `example.invalid` y UUIDs de fixture. Cubren acceso anónimo, lectura/listado, creación, autoría derivada de `auth.uid()`, edición/borrado por rol, fotos y Storage, cambio de IDs, falsificación de rol/autoría mediante llamadas SQL directas y las restricciones de tipo/tamaño de los metadatos. No verifican que la API de Storage rechace cargas reales.

Supabase CLI 3.2.0 y Docker Desktop se usaron con una base Postgres local; la configuración `supabase/config.toml` no está vinculada a un proyecto remoto. En una verificación previa a los límites de fotos, la migración se aplicó con `supabase db reset --no-seed` y `supabase test db` pasó 38 pruebas pgTAP. Se usaron únicamente identidades `example.invalid` y fixtures ficticios; la prueba hace rollback de sus datos. Para este cambio no se ejecutó SQL ni se inició la API local completa. Las pruebas verifican este esquema en desarrollo, no son una garantía de producción.

Antes de habilitar datos reales aún hay que definir el alta segura de administradores, probar la carga y rechazo de archivos a través de Storage, validar la correspondencia entre metadatos y contenido, definir errores y enlaces firmados, limpieza coordinada de Storage, respaldos, retención, sesiones, costos y revisión independiente de políticas. No se afirma que la seguridad esté lista para producción.

La documentación oficial describe [Supabase Auth](https://supabase.com/docs/guides/auth), [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) y [control de acceso a Storage](https://supabase.com/docs/guides/storage/security/access-control). El plan gratuito publica límites de almacenamiento —incluidos 500 MB de base de datos y 1 GB de archivos— y pausa proyectos tras una semana de inactividad. Revisar [precios y límites actuales](https://supabase.com/pricing) antes de depender del servicio; pueden cambiar.

## Archivos del prototipo

- `index.html`: interfaz de demostración.
- `Styles.html`: estilos adaptables para escritorio, móvil e impresión.
- `Client.html`: datos inventados y comportamiento solo en memoria.
- `Code.gs`: restos del servidor Apps Script, deliberadamente bloqueado.
- `appsscript.json`: configuración del prototipo Apps Script.
- `prompt-inicial.txt`: prompt original, conservado.
