# Changelog

## v1.1

Выпуск для любых проектов, не только исследовательских. Убраны модули `clusters` и
`research-experiments` и отсылки к ним; примеры и поля в CORE, PROJECT и STATUS
переписаны под обычную разработку (ресурсы и расходы вместо GPU, выпуски и сборки вместо
чекпойнтов). Файл `docs/NAMES.md` из раскладки убран. v1.0 заменён этим выпуском и
удалён из дерева; проект, созданный на v1.0, переводится навыком `/kit-upgrade`.

- SHA-256 `releases/v1.1/MANIFEST.sha256`: `95a04fccdd4c29d490dd567c75dda06eaeb822cbf823be641c2d8dcf8db8485a`

## Среда вокруг kit

Добавлены: `SETUP.md` (сборка среды по шагам), вход
сопровождающего `AGENTS.md`, `LESSONS.md`, шаблон репозитория памяти `templates/notes/`
с навыком `/new-notes`, навык `/kit-upgrade`, `scripts/release.sh`, шаблоны инструкций
проекта, службы Remote Control и рутины. Скрипты плагина находят kit и тогда, когда плагин
установлен копией (`AGENT_KIT_DIR` или `~/code/agent-kit`).

## v1.0 (заменён v1.1)

Первый выпуск стартового набора: CORE, PROJECT, STATUS, модули `clusters` и
`research-experiments`; плагин для Claude Code (проверка копии kit при старте сессии,
навык `new-project`). В дереве до коммита 22957db.

- SHA-256 `releases/v1.0/MANIFEST.sha256`: `ba0e4f8a330af5ef05079bf6b912f85a86c14ccbaf6dc8c55e998a1bc9388f0d`
