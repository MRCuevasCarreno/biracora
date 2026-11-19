<<<<<<< HEAD
# Bitácora Mecánica — prototipo visual

Interfaz de demostración para “Bitácora Mecánica — Marco ‘Pelao’ Cifuentes”, preparada como archivos fuente para copiar manualmente a un proyecto de Google Apps Script. **No es un sistema conectado ni listo para producción.** No crea hojas, carpetas, despliegues ni servicios; tampoco requiere Node, npm o datos de clientes.

## Bloqueo de seguridad: identidad y roles

Las cuentas personales de Google no ofrecen una forma segura de combinar, sin configuración adicional, estas dos necesidades:

1. Que el servidor acceda como Matías a su hoja y carpeta privadas de Drive.
2. Que el servidor identifique de manera verificable a Matías o Marco en cada petición y aplique sus roles.

`Session.getActiveUser().getEmail()` puede devolver una cadena vacía cuando la web app se ejecuta como su propietario. Google documenta la ejecución como el usuario que accede como alternativa, pero entonces las operaciones de Sheets/Drive quedan bajo los permisos de esa persona. Compartir los archivos con Marco para permitir escrituras le permitiría modificarlos directamente, fuera de las comprobaciones por rol de la aplicación.

Por eso esta entrega **falla de manera cerrada**: `APP_CONFIG.liveModeEnabled` está desactivado; las funciones de API en `Code.gs` comprueban identidad/rol en el servidor y luego rechazan toda operación de datos reales. La interfaz solo muestra una lista ficticia en memoria, no tiene selector de rol y no llama esas funciones. Crear, editar, borrar y subir fotos están deshabilitados. No introduzcas datos ni fotos reales.

Para habilitar un sistema real habría que decidir y revisar una solución de autenticación independiente y verificable que permita al backend actuar con privilegios propios, validar tokens en el servidor y restringir los archivos a Matías; por ejemplo, evaluar una arquitectura de identidad/OIDC configurada para esas cuentas o migrar a identidades administradas por un dominio Google Workspace. Esto requiere decisiones y configuración de autenticación/OAuth que no se han realizado, tal como se pidió. No cambies `liveModeEnabled` a `true` para “probar”: no activa almacenamiento y no resuelve el bloqueo. No se afirma que el control de acceso esté listo para producción.

Los correos `matias@example.com` y `marco@example.com` en `Code.gs` son marcadores de ejemplo, no identidades funcionales. No se configuraron cuentas, OAuth, facturación, despliegues ni enlaces compartidos.

## Archivos

- `Code.gs`: entrada HTML y endpoints deliberadamente bloqueados con comprobación de identidad y rol.
- `Index.html`: interfaz adaptable y orden de trabajo ficticia.
- `Styles.html`: estilos de escritorio/móvil y CSS de impresión.
- `Client.html`: registros inventados, búsqueda exacta por patente normalizada y acciones de impresión.
- `appsscript.json`: zona horaria `America/Santiago` y runtime V8.

`prompt-inicial.txt` se conserva sin modificaciones.

## Probar el prototipo

1. Copia manualmente los cinco archivos a un proyecto de Apps Script para preparar la prueba. El HTML usa plantillas de Apps Script y no funciona si se abre directamente como archivo local.
2. No se ha creado ni desplegado ningún proyecto. Cuando decidas probarlo en Google, usa una implementación de prueba de Apps Script; no configures una implementación pública ni compartas los archivos. `Code.gs` no realiza operaciones reales incluso si se muestra la interfaz.
3. Busca `DE-MO-03`, `de mo 03` y `DEMO03`: deben mostrar el mismo registro. La búsqueda es **exacta después de normalizar**; no es parcial. Una patente sin coincidencia muestra un mensaje, y el campo vacío lista los ejemplos.
4. Usa **Imprimir orden** para abrir la impresión del navegador. La orden excluye fotos de ejemplo y controles de navegación.
5. Verifica que Nuevo trabajo, Editar, Eliminar y Agregar fotos sigan deshabilitados.
6. Si pruebas directamente `apiListJobs`, `apiCreateJob`, `apiUpdateJob`, `apiDeleteJob` o `apiUploadPhoto` desde el editor Apps Script, deben fallar con acceso denegado o con el aviso de modo real deshabilitado. No devuelven registros ni escriben datos.

La demo funciona solo con datos ficticios en memoria; no llama `google.script.run`. No se hizo una implementación de prueba porque se pidió no configurar despliegues.

## Pendiente antes de una versión real

- Resolver la identidad verificable para cuentas personales, el modelo de ejecución y la autorización del almacenamiento; hacer una revisión de seguridad antes de habilitar datos reales.
- Recién después de resolverlo, crear manualmente una hoja privada y una carpeta privada en Drive propiedad de Matías; compartir solo con personas específicas y nunca hacerlos públicos. Añadir a configuración los IDs y correos reales fuera de los archivos fuente distribuidos.
- Implementar almacenamiento con columnas de creador verificable y marcas de tiempo, validación de servidor, búsquedas, gestión de roles y pruebas de acceso directo a cada operación. Validar también permisos para cualquier archivo de foto.
- Implementar el formulario, validaciones, compresión, límites por archivo y total, formatos permitidos, borrado/retención de fotos y errores de carga.
- Ejecutar pruebas de aceptación con ambas cuentas antes de cualquier despliegue. En la versión actual no se puede comprobar creación real, permisos sobre registros, almacenamiento de fotos ni acceso desde ambas cuentas.

La zona horaria prevista es `America/Santiago`. Debe configurarse tanto en el proyecto Apps Script como en la hoja cuando se implemente persistencia, y probarse en los cambios de horario.

### Cuotas y disponibilidad

Apps Script y Drive aplican cuotas y límites de uso que varían según la cuenta y pueden cambiar. La capacidad de Google One se comparte con otros productos y no equivale a una cuota garantizada para esta aplicación. No se promete costo cero absoluto, capacidad ilimitada ni disponibilidad garantizada.
=======
# biracora
>>>>>>> origin/main
