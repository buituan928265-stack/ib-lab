#!/usr/bin/env python3
"""lab — задания и проверки учебной лаборатории.

  lab                 список заданий
  lab 02              показать задание урока 02 и создать файл ответов
  lab check 02        проверить ответы урока 02
  lab break dns       сломать настройку DNS (уроки 03 и 08)
  lab reset           вернуть сеть компьютера ученика в исходное состояние
"""
import glob
import hashlib
import json
import os
import re
import shutil
import socket
import struct
import subprocess
import sys

LABS = "/opt/lab/labs"
HOME = os.path.expanduser("~")
ANSWERS = os.path.join(HOME, "answers")
STATE = os.path.join(HOME, ".lab")
DNS_BROKEN_FLAG = os.path.join(STATE, "dns_was_broken")

GOOD_RESOLV = "nameserver 192.168.10.1\noptions timeout:2 attempts:2\n"
BAD_RESOLV = "nameserver 192.168.10.99\noptions timeout:1 attempts:1\n"

GREEN, RED, YELLOW, BOLD, RESET = "\033[32m", "\033[31m", "\033[33m", "\033[1m", "\033[0m"

SYNONYMS = {"yes": "да", "y": "да", "д": "да", "no": "нет", "n": "нет", "н": "нет"}


def norm(value):
    """Должна совпадать с norm() в teacher/tools/build_checks.py."""
    v = value.strip().lower().replace("ё", "е")
    v = re.sub(r"\s+", "", v).rstrip(".")
    v = re.sub(r"(мс|ms)$", "", v)
    return SYNONYMS.get(v, v)


def digest(key, value):
    return hashlib.sha256(f"ib-lab:{key}:{norm(value)}".encode("utf-8")).hexdigest()


def lessons():
    return sorted(os.path.basename(p) for p in glob.glob(os.path.join(LABS, "[0-9][0-9]")))


def load_check(n):
    with open(os.path.join(LABS, n, "check.json"), encoding="utf-8") as f:
        return json.load(f)


def load_status():
    try:
        with open(os.path.join(STATE, "status.json"), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_status(status):
    os.makedirs(STATE, exist_ok=True)
    with open(os.path.join(STATE, "status.json"), "w", encoding="utf-8") as f:
        json.dump(status, f, ensure_ascii=False, indent=1)


def lesson_arg(arg):
    n = arg.zfill(2)
    if n not in lessons():
        sys.exit(f"Нет задания для урока «{arg}». Список: lab")
    return n


def answers_path(n):
    return os.path.join(ANSWERS, f"{n}.txt")


# ---------- команды

def cmd_list():
    status = load_status()
    print(f"{BOLD}Задания лаборатории{RESET}")
    for n in lessons():
        title = load_check(n)["title"]
        mark = f"{GREEN}✓ выполнено{RESET}" if status.get(n) == "passed" else ""
        print(f"  {n}  {title}  {mark}")
    print("\nОткрыть задание: lab 02    Проверить: lab check 02")


def cmd_show(n):
    with open(os.path.join(LABS, n, "task.md"), encoding="utf-8") as f:
        text = f.read()
    os.makedirs(ANSWERS, exist_ok=True)
    path = answers_path(n)
    created = False
    if not os.path.exists(path):
        shutil.copy(os.path.join(LABS, n, "answers.txt"), path)
        created = True
    footer = (f"\n----\nФайл ответов: {path}" + (" (создан)" if created else "") +
              f"\nОткрыть его: nano ~/answers/{n}.txt    Проверить: lab check {n}\n")
    if sys.stdout.isatty():
        subprocess.run(["less", "-R", "-F", "-X"], input=(text + footer).encode("utf-8"))
    else:
        print(text + footer)


def read_answers(n):
    path = answers_path(n)
    if not os.path.exists(path):
        sys.exit(f"Сначала откройте задание: lab {n}")
    answers = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.split("#", 1)[0]
            if "=" in line:
                key, value = line.split("=", 1)
                answers[key.strip()] = value.strip()
    return answers


def cmd_check(n):
    check = load_check(n)
    answers = read_answers(n)
    ok_count, total = 0, 0
    print(f"{BOLD}Проверка урока {n}: {check['title']}{RESET}")
    for item in check["items"]:
        total += 1
        key = item["key"]
        value = answers.get(key, "")
        if not value:
            print(f"  {YELLOW}·{RESET} {key}: нет ответа")
        elif digest(key, value) in item["hashes"]:
            ok_count += 1
            print(f"  {GREEN}✓{RESET} {key}")
        else:
            print(f"  {RED}✗{RESET} {key}: {item['hint']}")
    for name in check.get("live", []):
        total += 1
        ok, message = LIVE[name]()
        ok_count += ok
        print(f"  {GREEN + '✓' if ok else RED + '✗'}{RESET} {message}")
    print()
    status = load_status()
    if ok_count == total:
        print(f"{GREEN}Всё верно: {ok_count} из {total}.{RESET}")
        if check.get("selfcheck"):
            print("\nОсталось проверить себя по чек-листу (это автоматически не проверяется):")
            for line in check["selfcheck"]:
                print(f"  □ {line}")
        status[n] = "passed"
    else:
        print(f"Верно {ok_count} из {total}. Исправьте ответы в ~/answers/{n}.txt и запустите lab check {n} снова.")
        if status.get(n) == "passed":
            del status[n]
    save_status(status)
    if ok_count != total:
        sys.exit(1)  # код возврата нужен внешней проверке (например, шагу сценария Killercoda)


def write_resolv(content):
    subprocess.run(["sudo", "tee", "/etc/resolv.conf"], input=content.encode(),
                   stdout=subprocess.DEVNULL, check=True)


def cmd_break(what):
    if what != "dns":
        sys.exit("Сейчас можно сломать только DNS: lab break dns")
    write_resolv(BAD_RESOLV)
    os.makedirs(STATE, exist_ok=True)
    open(DNS_BROKEN_FLAG, "w").close()
    print("Готово: на компьютере ученика что-то сломалось. Сайты по имени больше не открываются.")
    print("Найдите причину и исправьте её сами. Подсказка — задание урока 03 или 08.")


def cmd_reset(quiet=False):
    write_resolv(GOOD_RESOLV)
    subprocess.run(["sudo", "ip", "route", "replace", "default", "via", "192.168.10.1"], check=True)
    if os.path.exists(DNS_BROKEN_FLAG):
        os.remove(DNS_BROKEN_FLAG)
    if not quiet:
        print("Сеть компьютера ученика возвращена в исходное состояние.")


# ---------- живые проверки: смотрят на состояние стенда, а не на текст ответа

def live_dns_fixed():
    if not os.path.exists(DNS_BROKEN_FLAG):
        return False, "DNS: сначала выполните lab break dns, найдите и исправьте поломку"
    with open("/etc/resolv.conf", encoding="utf-8") as f:
        servers = re.findall(r"^\s*nameserver\s+(\S+)", f.read(), re.M)
    try:
        resolved = socket.gethostbyname("portal.test")
    except OSError:
        resolved = None
    if resolved == "192.168.10.10" and servers[:1] == ["192.168.10.1"]:
        return True, "DNS исправлен: portal.test снова находится по имени"
    return False, "DNS всё ещё не работает: проверьте, какой DNS-сервер указан в /etc/resolv.conf"


def pcap_packets(path):
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 24:
        return
    magic = data[:4]
    endian = "<" if magic in (b"\xd4\xc3\xb2\xa1", b"\x4d\x3c\xb2\xa1") else ">"
    linktype = struct.unpack(endian + "I", data[20:24])[0]
    offset = {1: 14, 101: 0, 113: 16, 276: 20}.get(linktype)
    if offset is None:
        return
    pos = 24
    while pos + 16 <= len(data):
        caplen = struct.unpack(endian + "I", data[pos + 8:pos + 12])[0]
        frame = data[pos + 16:pos + 16 + caplen]
        pos += 16 + caplen
        ip = frame[offset:]
        if len(ip) >= 24 and ip[0] >> 4 == 4:
            yield ip


def live_own_capture():
    files = glob.glob(os.path.join(HOME, "captures", "*.pcap"))
    target = socket.inet_aton("192.168.10.10")
    for path in files:
        for ip in pcap_packets(path):
            ihl = (ip[0] & 15) * 4
            if ip[9] == 6 and target in (ip[12:16], ip[16:20]):
                ports = struct.unpack(">HH", ip[ihl:ihl + 4])
                if 80 in ports:
                    return True, f"Своя запись найдена: {os.path.basename(path)} содержит обмен с portal.test:80"
    return False, "Своя запись: в ~/captures/ нет .pcap с обменом с portal.test по порту 80"


LIVE = {"dns_fixed": live_dns_fixed, "own_capture": live_own_capture}


def main(argv):
    if not argv or argv[0] in ("list", "ls"):
        return cmd_list()
    if argv[0] in ("help", "-h", "--help"):
        return print(__doc__)
    if argv[0] == "check" and len(argv) > 1:
        return cmd_check(lesson_arg(argv[1]))
    if argv[0] == "break" and len(argv) > 1:
        return cmd_break(argv[1])
    if argv[0] == "reset":
        return cmd_reset(quiet="--quiet" in argv)
    if argv[0] == "show" and len(argv) > 1:
        return cmd_show(lesson_arg(argv[1]))
    if argv[0].isdigit():
        return cmd_show(lesson_arg(argv[0]))
    print(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
