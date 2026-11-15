# <Название проекта> — вход для агентов

<Два-три предложения: что это за проект, для чего он и что в нём решает владелец.>

## Что читать

Всегда: [`agent-kit/CORE.md`](agent-kit/CORE.md), этот файл и `## Project summary` в
[`docs/STATUS.md`](docs/STATUS.md). Дальше — по задаче:

| Задача | Что читать |
|---|---|
| план, интерпретация, изменение проекта | открытые записи [`docs/LESSONS.md`](docs/LESSONS.md) по теме; `docs/DIRECTION.md`, когда он появится |
| вопрос владельцу, действие под ограничением | [`docs/DECISIONS.md`](docs/DECISIONS.md) |
| запись статуса | [`agent-kit/STATUS.md`](agent-kit/STATUS.md) §2 |
| прошлые события | [`docs/HISTORY.md`](docs/HISTORY.md), `git log` |
| создание или правка любого из этих файлов | [`agent-kit/PROJECT.md`](agent-kit/PROJECT.md), нужный раздел |

<!-- Если проект запускает эксперименты или работает на кластере, добавь строки:
| выбор, запуск, мониторинг или интерпретация эксперимента | [`agent-kit/modules/research-experiments.md`](agent-kit/modules/research-experiments.md); `docs/RULES.md` |
| любая операция на кластере | [`agent-kit/modules/clusters.md`](agent-kit/modules/clusters.md); `docs/OPERATIONS.md` |
-->

## Действующие ограничения

- Приёмку, публикацию и деплой даёт только владелец, своими словами; молчание, прошедшее
  время и зелёные проверки — не согласие.
- Секретов, токенов и личных данных в репозитории нет.
- Завершённый проверенный шаг коммитится (только свои изменения) и пушится в `main`
  без отдельной просьбы; без force-push.
<!-- Сюда — другие запреты проекта, каждый со ссылкой на решение D-… в docs/DECISIONS.md. -->

## Agent kit
- modules: none
- extensions: none
- deviations: none
