# Privacy Data Guidelines

## Principios

- No enviar titulos de tareas a analytics.
- No enviar notas personales.
- No enviar texto crudo usado para clasificacion.
- Mantener clasificacion local-first por defecto.
- Activar cloud sync solo con consentimiento y autenticacion.

## Analytics

Eventos permitidos:

- nombres de evento centralizados;
- cuadrante;
- categoria;
- nivel de confianza;
- booleanos como `has_auto_tags`;
- fuente agregada de accion.

Eventos no permitidos:

- task title;
- task notes;
- texto libre capturado;
- direccion, coordenadas o datos sensibles sin consentimiento.

## Crash reporting

- Sanitizar contexto antes de capturar errores.
- No adjuntar payloads completos de tareas.
- No incluir secretos ni tokens.

## Feature flags

- Ningun flag debe activar cloud sync sin aviso al usuario.
- Flags remotos futuros no deben superar consentimiento local.

## Derechos de datos

La arquitectura futura debe contemplar:

- exportacion local;
- borrado completo local;
- borrado remoto;
- revocacion de sync cloud.
