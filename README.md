# Bitácora Mecánica

Bitácora Mecánica. `local-preview-r1200gs.html` conserva el historial real compartido para una BMW R1200GS 2005 y es solo una demo local; no lo compartas ni despliegues con esos datos. `Index.html` sirve el acceso y la gestión inicial de vehículos y órdenes mediante Apps Script y Supabase. El proyecto de Supabase existe, pero este repositorio no se conecta ni ejecuta cambios remotos automáticamente.

## Arquitectura elegida para evaluar

La aplicación usa Supabase Auth, Postgres con Row Level Security (RLS) y Storage privado para las fotos. Los registros y fotos se alojan en Supabase, no en el Drive personal de Matías. La aplicación se desplegó como web app de Apps Script con acceso `MYSELF` y ejecución como `USER_DEPLOYING`; solo la cuenta que la desplegó puede abrirla.

La matriz de permisos de la base de datos es:

| Operación | ADMIN | MECHANIC |
| --- | --- | --- |
| Listar y leer trabajos | Todos | Todos |
| Crear trabajos | Sí | Sí |
| Editar trabajos | Todos | Solo los creados por ese usuario |
| Eliminar trabajos | Todos | No |
| Leer y crear vehículos | Sí | Sí |
| Editar o eliminar vehículos | No | No |
| Leer y agregar fotos | Según acceso al trabajo | Según acceso al trabajo |
| Eliminar fotos | Sí | No |

Roles y autoría deben derivarse de la identidad autenticada en la base de datos, nunca del selector ni de valores de rol enviados por el cliente. Una clave privilegiada de Supabase nunca debe incluirse en el navegador.

## Estado actual y límites

- `local-preview-r1200gs.html` sigue siendo una demostración visual local con el historial importado; no es una aplicación con inicio de sesión. `Index.html` es la entrada de autenticación por correo y contraseña; `AuthClient.html` recupera la sesión persistente, valida el rol desde el perfil propio y permite cerrar sesión.
- El acceso permanece bloqueado si faltan `SUPABASE_URL` o `SUPABASE_PUBLISHABLE_KEY` en las propiedades del proyecto de Apps Script. El usuario indicó que ya las configuró; no se inspeccionaron sus valores. La app se desplegó con acceso restringido a la cuenta desplegadora, pero no se abrió ni se probó la conexión a Supabase.
- `Client.html` conserva el historial importado y su separación revisada para la demostración local. No se incluye desde la entrada autenticada; las fechas ausentes o no interpretables y los kilometrajes vacíos se muestran sin inventar valores. La fecha `3/11/0201` se conserva en las observaciones como dato no interpretado.
- Los resúmenes y la separación inicial entre trabajo, insumos y observaciones se prepararon localmente a partir del CSV. Las compras sin instalación explícita, los trabajos faltantes, los diagnósticos ambiguos y los resultados no registrados se señalan como “por confirmar”; los valores originales del CSV embebido se conservan. La instalación del DB Killer indicada en las observaciones también se muestra como trabajo. La maqueta no llama a un servicio de IA ni envía esos datos a terceros.
- La pantalla autenticada consulta vehículos y órdenes, crea vehículos y crea órdenes vinculadas a vehículos para ambos roles. La migración `20261123130000_vehicles_and_order_creation.sql` añade la tabla `vehicles`, el vínculo de órdenes y permisos RLS; la base deriva la autoría y genera los IDs. RLS permite a ambos roles leer/crear vehículos, pero no actualizarlos ni borrarlos; las órdenes nuevas requieren un vehículo.
- Crear, editar o eliminar servicios solo cambia la página en memoria. Esos cambios se pierden al recargar; el historial importado permanece en el código local. La maqueta no incluye carga ni gestión de fotos.
- `Code.gs` sirve `Index.html` y lee la configuración pública de las propiedades del proyecto; conserva funciones de API heredadas que rechazan operaciones reales. `APP_CONFIG.liveModeEnabled` permanece desactivado y no hay usuarios autorizados allí. `appsscript.json` configura el proyecto. No habilites esas funciones heredadas.
- `supabase/migrations/20261119210000_initial_rls_schema.sql` y `supabase/migrations/20261120112500_photo_upload_limits.sql` definen el esquema previo y sus políticas RLS. La migración de vehículos queda preparada; no se aplicó SQL remoto.
- `supabase/tests/database/rls.sql` contiene pruebas pgTAP con usuarios, trabajos y fotos ficticios; no crea cuentas utilizables ni usa contraseñas reales.
- El código de persistencia está implementado, pero no se conectó ni probó contra Supabase remoto. El historial de la moto es el único conjunto de datos reales incluido en el repositorio; no importes ese historial ni otros datos personales/fotos a Supabase.
- El registro público de Auth está deshabilitado en `supabase/config.toml`. Antes de habilitar una conexión real, verifica en la configuración Auth del proyecto que también esté deshabilitado: ocultar un botón de registro no bloquea la API pública y los nuevos perfiles tienen rol `MECHANIC`.

El usuario confirmó la rotación de la contraseña de base de datos expuesta y que el registro público está deshabilitado; ninguno de esos estados se verificó independientemente. Se desplegó la app web privada de Apps Script. No se conectó ni probó Supabase y no se ejecutó SQL remoto. Nunca compartas contraseñas ni claves por chat.

La demo histórica puede ocultar acciones según un rol simulado para facilitar la revisión visual; eso no es un control de seguridad. En la aplicación autenticada, los permisos dependen de RLS. No se afirma que la autenticación o el control de acceso estén listos para producción.

## Probar la maqueta

1. Abre `local-preview-r1200gs.html` para la demo visual con historial o `local-preview-auth.html` para revisar la nueva pantalla de acceso bloqueada. `index.html` contiene plantillas de Apps Script y no funciona directamente como archivo local.
2. Escribe `LZ233` carácter por carácter o prueba `LZ`, `233`, `lz 233` y `LZ-233`: las coincidencias parciales deben aparecer mientras escribes, ignorando mayúsculas, espacios y guiones. Al abrir la única motocicleta, deben aparecer sus 52 servicios, en páginas de hasta 10 entradas, con el contacto Matias Cuevas / `+569 900 91 888`.
3. Las entradas sin fecha o kilometraje se muestran como “Sin información”; las fechas vacías o no interpretables quedan al final y no se derivaron valores faltantes. El registro con `3/11/0201` conserva esa fecha original en sus observaciones.
4. El selector sigue siendo simulado: como Marco/Mecánico, los registros importados no están asignados a su identidad ficticia y no se pueden editar; como Matías/Admin demo, se pueden editar. No es una prueba de permisos reales.
5. Abre un servicio para revisar trabajo completo, resumen, insumos, observaciones, mecánico, fecha, kilometraje y costo; puedes volver al historial o a la búsqueda. Prueba crear, editar o eliminar servicios y usa la impresión. Los cambios interactivos se pierden al recargar; vuelven los 52 registros del código.
6. El historial personal está en `Client.html` y el CSV original permanece local. No compartas, publiques ni despliegues el proyecto con esos archivos; no configures credenciales ni uses la maqueta para persistir información.

La vista previa local usa una configuración vacía, por lo que deja el botón de acceso deshabilitado y no carga el SDK. No se pudieron inspeccionar las propiedades privadas de Apps Script desde este entorno. Si se configuran las propiedades, `AuthClient.html` carga Supabase JS y el SDK gestiona la sesión y sus tokens; el cliente solo acepta la clave publicable. La demo histórica local sigue usando datos estáticos y no autentica ni persiste cambios.

## Esquema y pruebas de seguridad (sin SQL remoto)

La migración define `profiles` ligado a `auth.users`, `jobs` con autoría y `job_photos` con metadatos/ruta de almacenamiento. Un trigger crea cada perfil como `MECHANIC` para nuevos usuarios y la migración crea perfiles `MECHANIC` para cuentas Auth existentes, sin cambiar perfiles que ya existan ni confiar en metadatos del usuario. La migración no concede a clientes permisos para insertar/cambiar IDs, autoría o roles; la política de rol no permite escrituras desde el cliente.

### Asignación inicial de ADMIN (procedimiento elegido; pendiente)

Para este prototipo se elige una única asignación inicial y manual: Matías será el único ADMIN. No se construirá un flujo recurrente de administración desde un backend. Esto no crea una cuenta ni asigna el rol ahora: no se verificó ninguna identidad en el proyecto. El nombre “Matías” por sí solo no identifica de forma segura una cuenta; antes de la operación habrá que comprobar la identidad autenticada y su UUID exacto.

Cuando una persona operadora autorizada pueda acceder al canal administrativo confiable del proyecto:

1. Usa la cuenta individual ya establecida para Matías y verifica su identidad por el proceso administrativo aprobado. Mantén deshabilitado el registro público. No compartas contraseñas ni uses metadatos de Auth para otorgar el rol.
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

Supabase CLI y Docker Desktop se usaron anteriormente con una base Postgres local; la configuración `supabase/config.toml` no está vinculada a un proyecto remoto. En una verificación previa a los límites de fotos, `supabase test db` pasó 38 pruebas pgTAP. Para esta etapa se añadieron pruebas pgTAP de vehículos y órdenes con identidades `example.invalid` y fixtures ficticios; no se ejecutaron porque Supabase CLI no está disponible en el entorno actual. No se inició la API local ni se ejecutó SQL remoto. Las pruebas no son una garantía de producción.

Antes de habilitar datos reales aún hay que definir el alta segura de administradores, probar la carga y rechazo de archivos a través de Storage, validar la correspondencia entre metadatos y contenido, definir errores y enlaces firmados, limpieza coordinada de Storage, respaldos, retención, sesiones, costos y revisión independiente de políticas. No se afirma que la seguridad esté lista para producción.

La documentación oficial describe [Supabase Auth](https://supabase.com/docs/guides/auth), [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) y [control de acceso a Storage](https://supabase.com/docs/guides/storage/security/access-control). El plan gratuito publica límites de almacenamiento —incluidos 500 MB de base de datos y 1 GB de archivos— y pausa proyectos tras una semana de inactividad. Revisar [precios y límites actuales](https://supabase.com/pricing) antes de depender del servicio; pueden cambiar.

## Archivos del prototipo

- `index.html`: página principal de acceso por correo y contraseña, servida por Apps Script.
- `Styles.html`: estilos adaptables para escritorio, móvil e impresión.
- `AuthClient.html`: cliente de autenticación y operaciones de vehículos/órdenes; Supabase JS se carga solo cuando la configuración está presente. Las sesiones y sus tokens los administra el SDK.
- `local-preview-auth.html`: vista estática de acceso, bloqueada mientras la configuración esté vacía.
- `Client.html`: historial local importado del CSV y comportamiento interactivo solo en memoria; no se incluye en la entrada autenticada.
- `Code.gs`: sirve la entrada y lee la configuración pública de Supabase desde propiedades del proyecto; sus APIs de datos siguen deliberadamente bloqueadas.
- `appsscript.json`: configuración del prototipo Apps Script.
- `prompt-inicial.txt`: prompt original, conservado.

La app ya está desplegada en Apps Script con acceso `MYSELF`. En **Project Settings → Script properties**, configura `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` copiando ambos valores desde los ajustes API del proyecto correcto. No los compartas por chat ni los guardes en el repositorio; no uses `service_role`. Los usuarios deben ser las cuentas individuales existentes e indicadas para el proyecto, con sus propios correos/contraseñas; no se implementa registro ni se crean claves compartidas. Los perfiles nuevos reciben `MECHANIC`; la asignación inicial de ADMIN sigue el procedimiento documentado arriba.

Al abrir la app, la interfaz consulta y crea vehículos y órdenes directamente con la clave publicable, siempre que las propiedades estén configuradas. La conexión aún no se ha probado. La sesión/rol no reemplazan a RLS: Postgres valida el rol, la autoría, la selección de vehículo y las columnas permitidas.
