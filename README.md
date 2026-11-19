# Bitácora Mecánica — prototipo visual

Maqueta interactiva para revisar la interfaz de la bitácora. Solo usa datos ficticios en memoria del navegador; no se conecta a Supabase, Google Sheets ni Google Drive y no está lista para producción. No se han creado proyectos, cuentas, tablas, permisos, facturación ni despliegues.

## Arquitectura elegida para evaluar

La dirección acordada es Supabase Auth, Postgres con Row Level Security (RLS) y Storage privado para las fotos. Los registros y fotos se alojarían en Supabase, no en el Drive personal de Matías. Esta decisión todavía no está implementada ni configurada.

La matriz de permisos que debe aplicar la futura base de datos es:

| Operación | ADMIN | MECHANIC |
| --- | --- | --- |
| Listar y leer trabajos | Todos | Todos |
| Crear trabajos | Sí | Sí |
| Editar trabajos | Todos | Solo los creados por ese usuario |
| Eliminar trabajos | Todos | No |
| Leer y agregar fotos | Según acceso al trabajo | Según acceso al trabajo |
| Eliminar fotos | Sí | No |

Roles y autoría deberán derivarse de la identidad autenticada en el servidor/base de datos, nunca del selector ni de valores de rol enviados por el cliente. RLS debe proteger también las llamadas directas a la API. El bucket de fotos deberá ser privado y sus políticas deberán comprobar el permiso sobre el trabajo asociado. Una clave privilegiada de Supabase nunca debe incluirse en el navegador.

## Estado actual y límites

- `index.html`, `Styles.html` y `Client.html` presentan la maqueta visual: búsqueda exacta por patente normalizada, detalle, impresión y formularios de ejemplo.
- El selector Matías/Admin y Marco/Mecánico es una simulación local, no es inicio de sesión ni prueba de identidad.
- Crear, editar, eliminar y agregar/quitar elementos de fotos solo cambia los ejemplos de la página. Los cambios se pierden al recargar. No se seleccionan ni transfieren archivos.
- `Code.gs` y `appsscript.json` pertenecen al prototipo anterior de Apps Script. `APP_CONFIG.liveModeEnabled` permanece desactivado, no hay usuarios autorizados configurados y las funciones de API rechazan operaciones reales. No lo cambies a `true`.
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

## Diseño técnico pendiente antes de Supabase

1. Definir tablas, restricciones e índices. Como base: perfil/rol asociado a `auth.users`, trabajos con creador autenticado, y metadatos de fotos asociados a un trabajo.
2. Implementar RLS con denegación por defecto: ambos roles leen todos los trabajos; ambos crean con `created_by = auth.uid()`; mecánicos actualizan solo los propios; administradores actualizan y eliminan cualquier trabajo.
3. Evitar que las actualizaciones cambien la autoría o el rol de una cuenta. El rol debe poder cambiarse solo por un flujo administrativo confiable.
4. Usar un bucket privado. Las reglas de Storage deben autorizar cada lectura/carga/eliminación según el trabajo relacionado; eliminar fotos solo como administrador. Revisar también el ciclo de vida de metadatos y archivos.
5. Añadir validación de campos, límites de tamaño y tipos de imágenes, tratamiento explícito de errores y enlaces privados de duración limitada si se necesitan para mostrar fotos.
6. Probar RLS y Storage con usuarios ficticios: anónimo, administrador, mecánico propietario y mecánico ajeno; probar llamadas directas a la API, cambio de IDs, rol/autoría falsificados, acceso a archivos y errores.
7. Revisar las políticas, respaldos, retención, sesiones y costos antes de decidir si se habilitan datos reales.

La documentación oficial describe [Supabase Auth](https://supabase.com/docs/guides/auth), [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) y [control de acceso a Storage](https://supabase.com/docs/guides/storage/security/access-control). El plan gratuito publica límites de almacenamiento —incluidos 500 MB de base de datos y 1 GB de archivos— y pausa proyectos tras una semana de inactividad. Revisar [precios y límites actuales](https://supabase.com/pricing) antes de depender del servicio; pueden cambiar.

## Archivos del prototipo

- `index.html`: interfaz de demostración.
- `Styles.html`: estilos adaptables para escritorio, móvil e impresión.
- `Client.html`: datos inventados y comportamiento solo en memoria.
- `Code.gs`: restos del servidor Apps Script, deliberadamente bloqueado.
- `appsscript.json`: configuración del prototipo Apps Script.
- `prompt-inicial.txt`: prompt original, conservado.
