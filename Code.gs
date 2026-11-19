const APP_CONFIG = Object.freeze({
  liveModeEnabled: false,
  allowedUsers: Object.freeze({})
});

function doGet() {
  return HtmlService.createTemplateFromFile('index')
    .evaluate()
    .setTitle('Bitácora Mecánica — Demo')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

function apiListJobs() {
  requireLiveRole_(['ADMIN', 'MECHANIC']);
  return liveModeBlocked_();
}

function apiGetJob(jobId) {
  requireLiveRole_(['ADMIN', 'MECHANIC']);
  return liveModeBlocked_();
}

function apiCreateJob(job) {
  requireLiveRole_(['ADMIN', 'MECHANIC']);
  return liveModeBlocked_();
}

function apiUpdateJob(jobId, changes) {
  const identity = requireLiveRole_(['ADMIN', 'MECHANIC']);
  if (identity.role === 'MECHANIC') {
    throw new Error('La edición de trabajos ajenos no está permitida.');
  }
  return liveModeBlocked_();
}

function apiDeleteJob(jobId) {
  requireLiveRole_(['ADMIN']);
  return liveModeBlocked_();
}

function apiUploadPhoto(jobId, photo) {
  requireLiveRole_(['ADMIN', 'MECHANIC']);
  return liveModeBlocked_();
}

function requireLiveRole_(permittedRoles) {
  let activeEmail = '';
  let effectiveEmail = '';
  try {
    activeEmail = Session.getActiveUser().getEmail().trim().toLowerCase();
    effectiveEmail = Session.getEffectiveUser().getEmail().trim().toLowerCase();
  } catch (error) {
    throw new Error('No se pudo verificar tu cuenta de Google. Acceso denegado.');
  }

  const activeDomain = activeEmail.split('@')[1] || '';
  const effectiveDomain = effectiveEmail.split('@')[1] || '';
  if (!activeEmail || !effectiveEmail || !activeDomain || activeDomain !== effectiveDomain) {
    throw new Error('No se pudo verificar una identidad del dominio autorizado. Acceso denegado.');
  }

  if (!Object.prototype.hasOwnProperty.call(APP_CONFIG.allowedUsers, activeEmail)) {
    throw new Error('No se pudo verificar una cuenta autorizada. Acceso denegado.');
  }

  const role = APP_CONFIG.allowedUsers[activeEmail];
  if (permittedRoles.indexOf(role) === -1) {
    throw new Error('Tu rol no permite esta operación.');
  }

  return { email: activeEmail, role: role };
}

function liveModeBlocked_() {
  if (!APP_CONFIG.liveModeEnabled) {
    throw new Error('El modo con datos reales está deshabilitado: la identidad y los permisos aún no tienen una solución segura.');
  }
  throw new Error('Las operaciones con datos reales no están implementadas.');
}
