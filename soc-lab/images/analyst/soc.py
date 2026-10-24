#!/usr/bin/env python3
"""soc — задания и проверки учебной лаборатории SOC.

  soc              список заданий
  soc 02           показать задание 02 и создать файл ответов
  soc check 02     проверить ответы задания 02
  soc data         где лежат журналы и справочники
  soc replay       заново прогнать события Sysmon через детектор Security Analytics
"""
import glob
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

LABS = "/opt/soc/labs"
HOME = os.path.expanduser("~")
ANSWERS = os.path.join(HOME, "answers")
STATE = os.path.join(HOME, ".soc")
GREEN, RED, YELLOW, BOLD, RESET = "\033[32m", "\033[31m", "\033[33m", "\033[1m", "\033[0m"
SYNONYMS = {"yes": "да", "y": "да", "д": "да", "no": "нет", "n": "нет", "н": "нет"}


def norm(value):
    """Должна совпадать с norm() в teacher/build_tasks.py."""
    v = value.strip().lower().replace("ё", "е")
    v = re.sub(r"\s+", "", v).rstrip(".")
    v = re.sub(r"(мс|ms|мб|mb|сек|с|s)$", "", v)
    return SYNONYMS.get(v, v)


def digest(key, value):
    return hashlib.sha256(f"ib-soc:{key}:{norm(value)}".encode("utf-8")).hexdigest()


def tasks():
    return sorted(os.path.basename(p) for p in glob.glob(os.path.join(LABS, "[0-9][0-9]")))


def load_check(n):
    with open(os.path.join(LABS, n, "check.json"), encoding="utf-8") as f:
        return json.load(f)


def status_file():
    return os.path.join(STATE, "status.json")


def load_status():
    try:
        with open(status_file(), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_status(status):
    os.makedirs(STATE, exist_ok=True)
    with open(status_file(), "w", encoding="utf-8") as f:
        json.dump(status, f, ensure_ascii=False)


def task_arg(arg):
    n = arg.zfill(2)
    if n not in tasks():
        sys.exit(f"Нет задания «{arg}». Список: soc")
    return n


def cmd_list():
    status = load_status()
    print(f"{BOLD}Задания лаборатории SOC{RESET}  (SIEM: http://127.0.0.1:5601 в браузере)")
    for n in tasks():
        c = load_check(n)
        mark = f"{GREEN}✓ выполнено{RESET}" if status.get(n) == "passed" else ""
        print(f"  {n}  {c['title']}  [{c['lessons']}]  {mark}")
    print("\nОткрыть задание: soc 01    Проверить: soc check 01    Данные: soc data")


def cmd_show(n):
    with open(os.path.join(LABS, n, "task.md"), encoding="utf-8") as f:
        text = f.read()
    os.makedirs(ANSWERS, exist_ok=True)
    path = os.path.join(ANSWERS, f"{n}.txt")
    created = not os.path.exists(path)
    if created:
        shutil.copy(os.path.join(LABS, n, "answers.txt"), path)
    footer = (f"\n----\nФайл ответов: {path}" + (" (создан)" if created else "") +
              f"\nОткрыть: nano ~/answers/{n}.txt    Проверить: soc check {n}\n")
    if sys.stdout.isatty():
        subprocess.run(["less", "-R", "-F", "-X"], input=(text + footer).encode("utf-8"))
    else:
        print(text + footer)


def cmd_check(n):
    path = os.path.join(ANSWERS, f"{n}.txt")
    if not os.path.exists(path):
        sys.exit(f"Сначала откройте задание: soc {n}")
    answers = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.split("#", 1)[0]
            if "=" in line:
                k, v = line.split("=", 1)
                answers[k.strip()] = v.strip()
    check = load_check(n)
    ok = 0
    print(f"{BOLD}Проверка задания {n}: {check['title']}{RESET}")
    for item in check["items"]:
        value = answers.get(item["key"], "")
        if not value:
            print(f"  {YELLOW}·{RESET} {item['key']}: нет ответа")
        elif digest(item["key"], value) in item["hashes"]:
            ok += 1
            print(f"  {GREEN}✓{RESET} {item['key']}")
        else:
            print(f"  {RED}✗{RESET} {item['key']}: {item['hint']}")
    total = len(check["items"])
    status = load_status()
    print()
    if ok == total:
        print(f"{GREEN}Всё верно: {ok} из {total}.{RESET}")
        if check.get("selfcheck"):
            print("\nПроверьте себя по чек-листу (автоматически не проверяется):")
            for line in check["selfcheck"]:
                print(f"  □ {line}")
        status[n] = "passed"
    else:
        print(f"Верно {ok} из {total}. Исправьте ~/answers/{n}.txt и запустите soc check {n} снова.")
        status.pop(n, None)
    save_status(status)
    if ok != total:
        sys.exit(1)  # код возврата нужен внешней проверке (например, шагу сценария Killercoda)


def cmd_data():
    print(f"""{BOLD}Где что лежит{RESET}
  /lab/data/*.ndjson     события по источникам (одна строка — одно событие JSON); те же, что в SIEM
  /lab/data/raw/auth.log журнал Linux-сервера SRV-WEB-01 в исходном виде
  /lab/data/raw/eve.json алерты Suricata в исходном виде
  /lab/data/users.csv    сотрудники: отдел, рабочая станция, адрес, удалённая работа
  /lab/data/assets.csv   активы: роль, критичность (A — самые важные), владелец, есть ли Sysmon
  /lab/data/tickets.csv  согласованные изменения (заявки)
  SIEM в браузере        http://127.0.0.1:5601  (Discover — поиск по событиям)
  SIEM из терминала      curl -s "$OPENSEARCH_URL/logs-*/_count"

Время в событиях хранится в UTC. Интерфейс SIEM показывает его по Москве (UTC+3),
в заданиях время указано тоже по Москве. В файлах .ndjson — UTC.""")


def cmd_replay():
    """Детектор проверяет только новые события; переиндексация делает старые «новыми»."""
    import urllib.request
    url = os.environ.get("OPENSEARCH_URL", "http://opensearch:9200")
    req = urllib.request.Request(f"{url}/logs-sysmon/_update_by_query?conflicts=proceed&refresh=true", method="POST")
    with urllib.request.urlopen(req, timeout=120) as r:
        n = json.loads(r.read()).get("updated")
    print(f"События Sysmon поданы детектору заново: {n}. Срабатывания появятся через 1–2 минуты")
    print("в Security Analytics → Findings. Старые срабатывания учебных правил тоже повторятся.")


def main(argv):
    if not argv or argv[0] in ("list", "ls"):
        return cmd_list()
    if argv[0] in ("help", "-h", "--help"):
        return print(__doc__)
    if argv[0] == "data":
        return cmd_data()
    if argv[0] == "replay":
        return cmd_replay()
    if argv[0] == "check" and len(argv) > 1:
        return cmd_check(task_arg(argv[1]))
    if argv[0] == "show" and len(argv) > 1:
        return cmd_show(task_arg(argv[1]))
    if argv[0].isdigit():
        return cmd_show(task_arg(argv[0]))
    print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
