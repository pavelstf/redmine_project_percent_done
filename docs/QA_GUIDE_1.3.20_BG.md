# PPD 1.3.20 — повторен QA

Build **r2, 2026-11-25** е от локален QA tag `qa-v1.3.20-r2`. Manifest записва
точния source commit/ref, branch, source snapshot digest и SHA-256 за всеки файл.
Текстовите файлове са LF. Това е QA кандидат, без нов production approval.

## Какво да предадете на QA

- `redmine_project_percent_done-1.3.20-install-20261125-r2.zip`: инсталационен
  payload с един корен redmine_project_percent_done/. Без CI, AGENTS, prompts,
  тестове, development scripts и локални файлове. README вътре съдържа
  конкретния install/update/rollback скрипт.
- `redmine_project_percent_done-1.3.20-source-20261125-r2.zip`: код, тестове,
  документация и development tooling за анализ; не е инсталационният ZIP.
- `QA_RETEST_MATRIX.md`, `QA_TEST_RESULTS.txt`, `QA_BENCHMARK.txt` и manifest.

Инструкциите за изолирания QA host са в install README и в source файла
docs/INSTALL_1.3.20.md. Не наслагвайте файлове при upgrade. Запазете DB backup
и старата plugin папка извън plugins/.

## Ключови проверки за повторния QA

Follow-up R-01–R-03: NULL lft/rgt не води до изключение в summary/details,
API/evidence или Overview; редовете са изключени, без автоматично поправяне
на данните. Проверете и трите комбинации (NULL/NULL, NULL/стойност,
стойност/NULL). Всички source/install текстове са LF, manifest сочи конкретния
QA commit/tag, а CHANGELOG съдържа историческия release 1.3.19.

1. PPD-01: 0.1h@70% + 0.2h@70% → raw 70, floor 70. 0.2h@10% +
   0.05h@50% → raw 18, ceil 18. Повторете summary/details/API/evidence,
   nearest и average-estimate imputation. Реални дробни стойности близо до
   integer граница не бива да се закръглят предварително до нея.
2. PPD-02: родител с подзадача само в друг проект е изключен. Чуждата задача
   не влиза в текущия проект. Evidence трябва да показва is_parent=true,
   children_count и parent_issue_excluded. Новият алгоритъм е 1.2; старите
   snapshots остават с предишните стойности и provenance.
3. PPD-03: Set membership; сравнете summary/details на голям проект.
   Приложеният benchmark е синтетичен CPU тест и не измерва SQL/DB/host latency.
4. PPD-04/05: root key за no е String, Norwegian зарежда/fallback-ва към EN.
   EN/BG са пълни; останалите локали са partial English compatibility fallback.
5. PPD-06: само в disposable test DB, down на migration 002 отказва преди
   промяна на schema/data. Weekly/monthly еднакъв period_end се запазват.
   Не изпълнявайте други down/purge операции като обикновен rollback.
6. PPD-07: тестов email с HTML/SMTP грешка показва фиксиран локализиран текст,
   без външен HTML или подробности. Достъпът остава admin-only и guarded при PPH.
7. PPD-08: изключен по подразбиране е menu tab. Details HTML/CSV е достъпен,
   когато overview, sidebar ИЛИ tab са активни. REST е отделно изключен.
   Проверете runtime-only инсталационния ZIP и отделния source payload.

Контролен базов пример: 2h@50% + 6h@100% → raw 87.5 и nearest 88.
Проверете parent/status/tracker exclusions, closed issue режими, всички режими
за липсващи estimates, 0% и липса на eligible issues. UI/диагностичен CSV
показва само видимите issue редове, а агрегатите остават проектни. Evidence
е trusted in-process API и не прилага viewer permissions; не го излагайте
на потребител без собствена authorization проверка.

## Тестове и докладване

Пълният локален Redmine 6.1.2 резултат е в QA_TEST_RESULTS.txt. Source ZIP
съдържа AGENTS.md, .redmine-test.yml, тестове и wrapper scripts за външния
shared runtime; прочетете ги преди локално изпълнение. Не пускайте suites
едновременно върху общата SQLite база. В Redmine test host използвайте:

```bash
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake redmine:plugins:migrate NAME=redmine_project_percent_done
RAILS_ENV=test bundle exec rake redmine:plugins:test NAME=redmine_project_percent_done
```

След автоматичните проверки остават отделни staging gates: MySQL/MariaDB,
реална PB/PPH integration, UI/GCR тема/клавиатура, private issue permissions,
изолиран SMTP и cron, performance на представителен голям проект.

Докладвайте по PPD ID: environment, dataset, настройки, очакван/реален
резултат, минимални стъпки и evidence. Отделяйте defects от blocked/not-run
проверки. Вижте матрицата за пълните acceptance критерии.
