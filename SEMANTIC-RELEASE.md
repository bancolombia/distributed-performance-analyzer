# Semantic Release
## Commit message format
semantic-release utiliza los mensajes de confirmación para determinar el impacto de los cambios en el release; Siguiendo las convenciones para mensajes de confirmación, semantic-release determina automáticamente el siguiente número de versión semántica, genera un registro de cambios y publica la versión.

De forma predeterminada, la liberación semántica utiliza 
convenciones de mensajes de confirmación angular. [convenciones de mensajes de confirmación angular.](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format)

Se pueden utilizar herramientas como commitizen o commit-lint para ayudar a los contribuyentes y hacer cumplir los mensajes de confirmación válidos.

La siguiente tabla muestra qué mensaje de confirmación le proporciona qué tipo de versión cuando se ejecuta la versión semántica (usando la configuración predeterminada):

| Commit Message                                                                                                                                                                                   | Release type                                                                                                    |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| `fix(pencil): stop graphite breaking when too much pressure applied`                                                                                                                             | ~~Patch~~ Fix Release                                                                                           |
| `feat(pencil): add 'graphiteWidth' option`                                                                                                                                                       | ~~Minor~~ Feature Release                                                                                       |
| `perf(pencil): remove graphiteWidth option`<br><br>`BREAKING CHANGE: The graphiteWidth option has been removed.`<br>`The default graphite width of 10mm is always used for performance reasons.` | ~~Major~~ Breaking Release <br /> (Note that the `BREAKING CHANGE: ` token must be in the footer of the commit) |
**[link a la fuente.](https://github.com/semantic-release/semantic-release?tab=readme-ov-file#Commit%20message%20format)**

dentro de la documentación de angular sobre convenciones de mensajes se tienen estos adicionales:

- **build:** cambios que afectan el sistema de compilación o las dependencias externas (alcances de ejemplo: gulp, broccoli, npm).
- **ci:** Cambios en nuestros archivos y scripts de configuración de CI (ejemplos: CircleCi, SauceLabs).
- **docs:** La documentación solo cambia.
- **feat:** una nueva característica.
- **fix:** una corrección de errores.
- **perf:** Un cambio de código que mejora el rendimiento.
- **refactor:** un cambio de código que no corrige un error ni agrega una característica.
- **test:** agregar pruebas faltantes o corregir pruebas existentes.

## excluir commit del análisis del plugin:

Todas las confirmaciones que contengan [skip release] or [release skip] en su mensaje se excluirán del análisis de confirmación y no participarán en la determinación del tipo de versión.