# Semantic Release
## Commit message format
semantic-release utiliza los mensajes de confirmación para determinar el impacto de los cambios en el release; Siguiendo las convenciones para mensajes de confirmación, semantic-release determina automáticamente el siguiente número de versión semántica, genera un registro de cambios y publica la versión.

De forma predeterminada, la liberación semántica utiliza 
convenciones de mensajes de confirmación angular. [convenciones de mensajes de confirmación angular.](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format)

Se pueden utilizar herramientas como commitizen o commit-lint para ayudar a los contribuyentes y hacer cumplir los mensajes de confirmación válidos.

La siguiente tabla muestra qué mensaje de confirmación le proporciona qué tipo de versión cuando se ejecuta la versión semántica (usando la configuración predeterminada):

**formato version:** `v<<major>>.<<minor>>.<<patch>>`

| Commit Message                                                                                                                                                                                   | Release type                                                                                                    |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------- |
| `fix: stop graphite breaking when too much pressure applied`                                                                                                                                     | ~~Patch~~ Fix Release                                                                                           |
| `feat: add 'graphiteWidth' option`                                                                                                                                                               | ~~Minor~~ Feature Release                                                                                       |
| `breaking: add 'graphiteWidth' option`                                                                                                                                                           | ~~Major~~ Feature Release                                                                                       |
| `perf: remove graphiteWidth option`<br><br>`BREAKING CHANGE: The graphiteWidth option has been removed.`<br>`The default graphite width of 10mm is always used for performance reasons.`         | ~~Major~~ Breaking Release <br /> (Note that the `BREAKING CHANGE: ` token must be in the footer of the commit) |


**[link a la fuente.](https://github.com/semantic-release/semantic-release?tab=readme-ov-file#Commit%20message%20format)**

dentro de la documentación de angular sobre convenciones de mensajes se tienen estos adicionales:

**breaking:** Aumento de **major** version debido a cambio significante. `v1.0.0 --> v2.0.0`<br>
**update:** Aumento de **minor** version debido a cambio moderado. `v1.0.0 --> v1.1.0`<br>
**upgrade:** Aumento de **minor** version debido a cambio moderado. `v1.0.0 --> v1.1.0`<br>
**refactor:** Aumento de **minor** version debido a refactorización de código. `v1.0.0 --> v1.1.0`<br>
**chore:** Aumento de **minor** version debido a conjunto de cambios moderados. `v1.0.0 --> v1.1.0`<br>
**docs:** Aumento de **minor** version debido a La documentación. `v1.0.0 --> v1.0.1`<br>
**ci:** Aumento de **patch** version debido a cambios en CI. `v1.0.0 --> v1.0.1`<br>
**test:** Aumento de **patch** version debido a agregar pruebas faltantes o corregir pruebas existentes. `v1.0.0 --> v1.0.1`<br>
**perf:** Aumento de **patch** version debido a Un cambio de código que mejora el rendimiento. `v1.0.0 --> v1.0.1`

## Excluir commit del análisis del plugin:

Todas las confirmaciones que contengan [skip release] or [release skip] en su mensaje se excluirán del análisis de confirmación y no participarán en la determinación del tipo de versión.

## Ejemplos

### major version example
**commit message**<br>
`fix: some message`

`BREAKING CHANGE: It will be significant" # passes`

### minor version example
**commit message**<br>
`feat: some message` ó `refactor: some message` ó `update: some message`

### patch version example
**commit message**<br>
`fix: some message` ó `ci: some message` ó `test: some message`

**[link a mas ejemplos.](https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/config-conventional#type-enum)**