# Bitácora Mecánica — prototipo visual

Maqueta interactiva para revisar la interfaz de la bitácora. `Client.html` incluye el historial real que el usuario compartió para una BMW R1200GS 2005; el prototipo no se conecta a Supabase, Google Sheets ni Google Drive y no está listo para producción. El historial está embebido en un archivo local: no hagas commit/push ni compartas, publiques o despliegues este proyecto con esos datos. No hay proyectos ni cuentas remotas, facturación ni despliegues. El esquema se probó únicamente en una instancia local de Supabase con fixtures ficticios.

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

- `index.html`, `Styles.html` y `Client.html` presentan una búsqueda en vivo por coincidencia parcial de patente normalizada que devuelve una sola motocicleta, su historial paginado de servicios y el detalle completo de cada registro.
- El selector Matías/Admin y Marco/Mecánico es una simulación local, no es inicio de sesión ni prueba de identidad.
- `Client.html` contiene 52 registros convertidos desde el CSV. Las fechas ausentes o no interpretables y los kilometrajes vacíos se muestran sin inventar valores. La fecha `3/11/0201` se conserva en las observaciones como dato no interpretado.
- Los resúmenes y la separación inicial entre trabajo, insumos y observaciones se prepararon localmente a partir del CSV. Las compras sin instalación explícita, los trabajos faltantes, los diagnósticos ambiguos y los resultados no registrados se señalan como “por confirmar”; los valores originales del CSV embebido se conservan. La instalación del DB Killer indicada en las observaciones también se muestra como trabajo. La maqueta no llama a un servicio de IA ni envía esos datos a terceros.
- Crear, editar o eliminar servicios solo cambia la página en memoria. Esos cambios se pierden al recargar; el historial importado permanece en el código local. La maqueta no incluye carga ni gestión de fotos.
- `Code.gs` y `appsscript.json` pertenecen al prototipo anterior de Apps Script. `APP_CONFIG.liveModeEnabled` permanece desactivado, no hay usuarios autorizados configurados y las funciones de API rechazan operaciones reales. No lo cambies a `true`.
- `supabase/migrations/20261119210000_initial_rls_schema.sql` define el esquema y las políticas RLS. Se aplicó únicamente a la base Supabase local de pruebas; no hay proyecto, cuentas ni tablas alojados, ni permisos remotos ni despliegues configurados.
- `supabase/tests/database/rls.sql` contiene pruebas pgTAP con usuarios, trabajos y fotos ficticios; no crea cuentas utilizables ni usa contraseñas reales.
- No se ha conectado Supabase ni existe código de persistencia real. El historial de la moto es el único conjunto de datos reales incluido; no agregues otros datos personales ni fotos.

La interfaz puede ocultar acciones según el rol simulado para facilitar la revisión visual; eso no es un control de seguridad. No se afirma que la autenticación o el control de acceso estén listos para producción.

## Probar la maqueta

1. Abre `local-preview-r1200gs.html`, la vista previa independiente generada para la sesión. `index.html` contiene plantillas de Apps Script y no funciona directamente como archivo local.
2. Escribe `LZ233` carácter por carácter o prueba `LZ`, `233`, `lz 233` y `LZ-233`: las coincidencias parciales deben aparecer mientras escribes, ignorando mayúsculas, espacios y guiones. Al abrir la única motocicleta, deben aparecer sus 52 servicios, en páginas de hasta 10 entradas, con el contacto Matias Cuevas / `+569 900 91 888`.
3. Las entradas sin fecha o kilometraje se muestran como “Sin información”; las fechas vacías o no interpretables quedan al final y no se derivaron valores faltantes. El registro con `3/11/0201` conserva esa fecha original en sus observaciones.
4. El selector sigue siendo simulado: como Marco/Mecánico, los registros importados no están asignados a su identidad ficticia y no se pueden editar; como Matías/Admin demo, se pueden editar. No es una prueba de permisos reales.
5. Abre un servicio para revisar trabajo completo, resumen, insumos, observaciones, mecánico, fecha, kilometraje y costo; puedes volver al historial o a la búsqueda. Prueba crear, editar o eliminar servicios y usa la impresión. Los cambios interactivos se pierden al recargar; vuelven los 52 registros del código.
6. El historial personal está en `Client.html` y el CSV original permanece local. No compartas, publiques ni despliegues el proyecto con esos archivos; no configures credenciales ni uses la maqueta para persistir información.

La página no llama `google.script.run`, no usa `fetch` para acceder a servicios, no carga ni almacena credenciales y no persiste cambios en `localStorage` o `sessionStorage`. El historial se incluye como datos estáticos en `Client.html`.

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
- `Client.html`: historial real importado del CSV y comportamiento interactivo solo en memoria.
- `Code.gs`: restos del servidor Apps Script, deliberadamente bloqueado.
- `appsscript.json`: configuración del prototipo Apps Script.
- `prompt-inicial.txt`: prompt original, conservado.
