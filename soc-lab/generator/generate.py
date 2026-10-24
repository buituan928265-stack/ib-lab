"""Генератор синтетических журналов учебной компании LAB за 20.10.2026.

Детерминированный: при одном и том же SEED данные и ответы всегда одинаковые.
Запуск: python generate.py  ->  ../data/*.ndjson, ../data/raw/*, ../data/*.csv
и ../../teacher/ground_truth.json (правильные ответы к заданиям).

Время в событиях — UTC (@timestamp). Местное время компании — UTC+3 (МСК).
Все имена, адреса и домены вымышленные.
"""
import csv
import datetime as dt
import hashlib
import json
import random
from collections import defaultdict
from pathlib import Path

SEED = 2026
R = random.Random(SEED)
HERE = Path(__file__).resolve().parent
DATA = HERE.parent / "data"
TEACHER = HERE.parents[1] / "teacher"
MSK = dt.timezone(dt.timedelta(hours=3))
DAY = dt.date(2026, 10, 20)

events = defaultdict(list)   # индекс -> список событий
truth = {}                   # правильные ответы


def t(hh, mm=0, ss=0, ms=0):
    return dt.datetime(DAY.year, DAY.month, DAY.day, hh, mm, ss, ms * 1000, tzinfo=MSK)


def iso(ts):
    return ts.astimezone(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.") + f"{ts.microsecond // 1000:03d}Z"


def rnd_time(start, end):
    a, b = start.timestamp(), end.timestamp()
    return dt.datetime.fromtimestamp(R.uniform(a, b), tz=MSK).replace(microsecond=R.randrange(0, 1000) * 1000)


def fake_hash(*parts):
    return hashlib.sha256("|".join(parts).encode()).hexdigest()


def guid(*parts):
    h = hashlib.md5("|".join(map(str, parts)).encode()).hexdigest().upper()
    return "{" + f"{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:32]}" + "}"


def add(index, ts, **fields):
    doc = {"@timestamp": iso(ts), "log": {"source": index}}
    doc.update(fields)
    events[index].append((ts, doc))
    return doc


# ---------------------------------------------------------------- компания
DEPTS = ["Бухгалтерия", "Продажи", "Маркетинг", "Юридический отдел", "Кадры", "Склад", "Закупки"]
FIRST = ["a", "b", "v", "g", "d", "e", "z", "i", "k", "l", "m", "n", "o", "p", "r", "s", "t", "u", "f", "y"]
LAST = ["ivanov", "petrova", "orlov", "smirnov", "lebedeva", "volkov", "belova", "sokolova", "morozov",
        "kozlova", "novikov", "popova", "vasiliev", "fedorova", "mikhailov", "egorova", "pavlov",
        "semenova", "golubev", "vinogradova", "bogdanov", "vorobieva", "fedotov", "melnikova",
        "zaitsev", "solovieva", "borisov", "yakovleva", "grigoriev", "romanova", "kuzmin", "frolova",
        "aleksandrov", "dmitrieva", "korolev", "gusev", "kiseleva", "ilin", "maksimova", "polyakov"]

USERS = {}
FIXED = [  # имя, отдел, компьютер, адрес, удалённый работник
    ("a.ivanov", "Бухгалтерия", "PC-03", "192.168.10.23", False),
    ("m.petrova", "Бухгалтерия", "PC-07", "192.168.10.27", False),
    ("k.smirnov", "Продажи", "PC-12", "192.168.10.32", True),
    ("s.orlov", "Продажи", "PC-15", "192.168.10.35", False),
    ("o.lebedeva", "Маркетинг", "PC-18", "192.168.10.38", True),
    ("d.volkov", "Юридический отдел", "PC-19", "192.168.10.39", False),
    ("e.belova", "Кадры", "PC-20", "192.168.10.40", False),
]
for name, dept, pc, ip, remote in FIXED:
    USERS[name] = dict(name=name, dept=dept, host=pc, ip=ip, remote=remote)
used = {u.split(".")[1] for u in USERS}
i = 21
for last in LAST:
    if last in used or len(USERS) >= 45:
        continue
    name = f"{R.choice(FIRST)}.{last}"
    USERS[name] = dict(name=name, dept=R.choice(DEPTS), host=f"PC-{i:02d}", ip=f"192.168.10.{i + 20}",
                       remote=R.random() < 0.35)
    i += 1
ADMINS = {"n.sokolova": dict(name="n.sokolova", dept="ИТ", host="ADM-WS01", ip="192.168.20.10", remote=False),
          "adm.kuznetsov": dict(name="adm.kuznetsov", dept="ИТ", host="ADM-WS01", ip="192.168.20.10", remote=False)}
SERVERS = {
    "DC-01": ("192.168.20.5", "Контроллер домена", "A", "n.sokolova"),
    "SRV-FS-01": ("192.168.20.20", "Файловый сервер", "A", "n.sokolova"),
    "PROXY-01": ("192.168.20.30", "Прокси-сервер", "B", "n.sokolova"),
    "SRV-BACKUP-01": ("192.168.20.40", "Сервер резервного копирования", "A", "n.sokolova"),
    "MAIL-01": ("192.168.20.50", "Почтовый сервер", "A", "n.sokolova"),
    "GW-VPN-01": ("192.168.20.60", "VPN-шлюз", "A", "n.sokolova"),
    "SRV-WEB-01": ("192.168.30.10", "Веб-сервер (Linux), опубликован в интернет", "B", "n.sokolova"),
}
NO_SYSMON = {"PC-12"}  # агент Sysmon на PC-12 не установлен — «слепое пятно»
VPN_GAP = (t(0, 58), t(5, 34))  # журналы VPN-шлюза не поступали

NORMAL_DOMAINS = ["portal.lab.test", "mail.lab.test", "crm.lab.test", "www.example.com", "news.example.org",
                  "docs.example.com", "update.example.net", "maps.example.org", "bank.example.com"]
DOMAIN_IP = {d: f"198.51.100.{10 + k}" for k, d in enumerate(NORMAL_DOMAINS)}
DOMAIN_IP.update({"portal.lab.test": "192.168.20.80", "mail.lab.test": "192.168.20.50", "crm.lab.test": "192.168.20.81"})
APPS = [("chrome.exe", r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        ("OUTLOOK.EXE", r"C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"),
        ("WINWORD.EXE", r"C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"),
        ("EXCEL.EXE", r"C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE"),
        ("notepad.exe", r"C:\Windows\System32\notepad.exe"),
        ("Teams.exe", r"C:\Program Files\Teams\Teams.exe")]


# ---------------------------------------------------------------- типовые события
def win(ts, host, code, action, outcome, user, **extra):
    fields = {"event": {"code": str(code), "action": action, "outcome": outcome, "provider": "Microsoft-Windows-Security-Auditing"},
              "host": {"name": host}, "user": {"name": user, "domain": "LAB"}}
    for key, value in extra.items():
        cur = fields
        parts = key.split("__")
        for p in parts[:-1]:
            cur = cur.setdefault(p, {})
        cur[parts[-1]] = value
    return add("windows", ts, **fields)


def logon_ok(ts, host, user, ltype, src=None, ws="-"):
    return win(ts, host, 4624, "logon", "success", user, winlog__logon_type=ltype,
               source__ip=src or "-", winlog__workstation=ws)


def logon_fail(ts, host, user, ltype, src=None, sub="0xC000006A", ws="-"):
    return win(ts, host, 4625, "logon-failed", "failure", user, winlog__logon_type=ltype,
               source__ip=src or "-", winlog__status="0xC000006D", winlog__substatus=sub, winlog__workstation=ws)


def sysmon_proc(ts, host, user, name, exe, cmd, parent_name, parent_exe, pguid, guid_, pid, ppid, signed=True, h=None):
    if host in NO_SYSMON:
        return None
    return add("sysmon", ts, event={"code": "1", "action": "process-create", "provider": "Microsoft-Windows-Sysmon"},
               host={"name": host}, user={"name": f"LAB\\{user}"},
               process={"name": name, "executable": exe, "command_line": cmd, "pid": pid, "entity_id": guid_,
                        "code_signature": {"signed": signed},
                        "hash": {"sha256": h or fake_hash(exe)},
                        "parent": {"name": parent_name, "executable": parent_exe, "pid": ppid, "entity_id": pguid}})


def sysmon_net(ts, host, user, name, exe, guid_, dst, port, src):
    if host in NO_SYSMON:
        return None
    return add("sysmon", ts, event={"code": "3", "action": "network-connection", "provider": "Microsoft-Windows-Sysmon"},
               host={"name": host}, user={"name": f"LAB\\{user}"},
               process={"name": name, "executable": exe, "entity_id": guid_},
               source={"ip": src}, destination={"ip": dst, "port": port}, network={"transport": "tcp"})


def sysmon_dns(ts, host, user, name, exe, guid_, query, answer):
    if host in NO_SYSMON:
        return None
    return add("sysmon", ts, event={"code": "22", "action": "dns-query", "provider": "Microsoft-Windows-Sysmon"},
               host={"name": host}, user={"name": f"LAB\\{user}"},
               process={"name": name, "executable": exe, "entity_id": guid_},
               dns={"question": {"name": query}, "answers": answer})


def dns(ts, client, query, answer, rcode="NOERROR", qtype="A"):
    return add("dns", ts, source={"ip": client}, dns={"question": {"name": query, "type": qtype},
               "response_code": rcode, "answers": answer}, host={"name": "DC-01"})


def proxy(ts, user, client, method, domain, status, bytes_out, bytes_in, action="allowed", category="Деловые", path="/"):
    return add("proxy", ts, user={"name": user}, source={"ip": client}, host={"name": "PROXY-01"},
               http={"request": {"method": method}, "response": {"status_code": status}},
               url={"domain": domain, "path": path}, network={"bytes_out": bytes_out, "bytes_in": bytes_in},
               event={"action": action}, proxy={"category": category})


def zeek(ts, src, dst, port, proto, duration, ob, rb, state="SF", service=None):
    uid = "C" + hashlib.md5(f"{ts}{src}{dst}{port}".encode()).hexdigest()[:17]
    return add("zeek", ts, zeek={"uid": uid, "conn_state": state, "service": service or "-"},
               source={"ip": src}, destination={"ip": dst, "port": port}, network={"transport": proto},
               event={"duration": round(duration, 3)}, zeek_bytes={"orig": ob, "resp": rb}, host={"name": "SENSOR-01"})


def vpn(ts, user, public_ip, action, assigned=None, country="RU", mfa="-", device="known", asn="Провайдер"):
    if VPN_GAP[0] <= ts < VPN_GAP[1]:
        return None
    return add("vpn", ts, user={"name": user}, source={"ip": public_ip, "geo": {"country_iso_code": country}, "as": {"organization": asn}},
               vpn={"assigned_ip": assigned or "-", "mfa_result": mfa, "device": device}, event={"action": action},
               host={"name": "GW-VPN-01"})


def mail(ts, sender, rcpt, subject, attachment, spf, dkim, dmarc, action, reply_to=None):
    return add("mail", ts, email={"from": sender, "to": rcpt, "reply_to": reply_to or sender, "subject": subject,
               "attachment": attachment or "-"}, mail_auth={"spf": spf, "dkim": dkim, "dmarc": dmarc},
               event={"action": action}, host={"name": "MAIL-01"})


def suricata(ts, src, sport, dst, dport, sid, sig, category, severity, action="allowed"):
    return add("suricata", ts, source={"ip": src, "port": sport}, destination={"ip": dst, "port": dport},
               suricata={"alert": {"signature_id": sid, "signature": sig, "category": category,
                                   "severity": severity, "action": action}}, host={"name": "SENSOR-01"})


linux_lines = []


def linux(ts, process, pid, message, action, user=None, src=None, outcome=None):
    stamp = ts.strftime("%b %d %H:%M:%S").replace(" 0", "  ", 1) if ts.day < 10 else ts.strftime("%b %d %H:%M:%S")
    line = f"{stamp} srv-web-01 {process}[{pid}]: {message}"
    linux_lines.append((ts, line))
    return add("linux", ts, host={"name": "SRV-WEB-01"}, process={"name": process, "pid": pid},
               message=line, event={"action": action, "outcome": outcome or "-"},
               user={"name": user or "-"}, source={"ip": src or "-"})


# ---------------------------------------------------------------- фон: обычный день
pid_seq = [4000]


def next_pid():
    pid_seq[0] += R.randrange(4, 40)
    return pid_seq[0]


for u in list(USERS.values()):
    start = rnd_time(t(8, 20), t(9, 40))
    end = rnd_time(t(17, 30), t(19, 10))
    working_remote = u["remote"] and R.random() < 0.85
    if working_remote:
        u["vpn_ip"] = f"203.0.113.{R.randrange(100, 160)}"
        u["vpn_assigned"] = f"10.8.0.{R.randrange(20, 120)}"
        vpn(start - dt.timedelta(minutes=2), u["name"], u["vpn_ip"], "connect", u["vpn_assigned"], mfa="approved",
            asn=R.choice(["Мобильный оператор", "Домашний провайдер"]))
        vpn(end + dt.timedelta(minutes=1), u["name"], u["vpn_ip"], "disconnect", u["vpn_assigned"])
        src_ip = u["vpn_assigned"]
    else:
        src_ip = u["ip"]
    u["work_ip"] = src_ip
    if R.random() < 0.15:
        logon_fail(start - dt.timedelta(seconds=R.randrange(5, 40)), u["host"], u["name"], 2)
    logon_ok(start, u["host"], u["name"], 2)
    win(start + dt.timedelta(seconds=1), "DC-01", 4624, "logon", "success", u["name"], winlog__logon_type=3, source__ip=src_ip)
    # explorer и приложения
    exp_guid = guid(u["host"], "explorer")
    exp_pid = next_pid()
    sysmon_proc(start + dt.timedelta(seconds=8), u["host"], u["name"], "explorer.exe", r"C:\Windows\explorer.exe",
                r"C:\Windows\explorer.exe", "userinit.exe", r"C:\Windows\System32\userinit.exe",
                guid(u["host"], "userinit"), exp_guid, exp_pid, next_pid())
    for k in range(R.randrange(4, 9)):
        name, exe = R.choice(APPS)
        ts = rnd_time(start + dt.timedelta(minutes=1), end)
        g = guid(u["host"], name, k)
        sysmon_proc(ts, u["host"], u["name"], name, exe, f'"{exe}"', "explorer.exe", r"C:\Windows\explorer.exe",
                    exp_guid, g, next_pid(), exp_pid)
    # файловый сервер
    for _ in range(R.randrange(2, 6)):
        ts = rnd_time(start, end)
        logon_ok(ts, "SRV-FS-01", u["name"], 3, src_ip)
        zeek(ts, src_ip, "192.168.20.20", 445, "tcp", R.uniform(5, 900), R.randrange(2_000, 900_000),
             R.randrange(10_000, 9_000_000), service="smb")
    # веб и DNS
    for _ in range(R.randrange(10, 25)):
        ts = rnd_time(start, end)
        d = R.choice(NORMAL_DOMAINS)
        dns(ts, src_ip, d, DOMAIN_IP[d])
        ob, ib = R.randrange(500, 60_000), R.randrange(5_000, 3_000_000)
        if not d.endswith("lab.test"):
            proxy(ts + dt.timedelta(milliseconds=120), u["name"], src_ip, R.choice(["GET", "GET", "GET", "POST"]),
                  d, 200, ob, ib)
            zeek(ts + dt.timedelta(milliseconds=110), src_ip, "192.168.20.30", 3128, "tcp", R.uniform(0.2, 30), ob, ib, service="http")
    # почта
    for _ in range(R.randrange(2, 7)):
        ts = rnd_time(t(8), t(19))
        sender = R.choice([v["name"] for v in USERS.values()]) + "@lab.test"
        mail(ts, sender, u["name"] + "@lab.test", R.choice(["Отчёт за неделю", "Встреча в 15:00", "Договор", "Вопрос по заказу", "Обед"]),
             None, "pass", "pass", "pass", "delivered")
    logoff = win(end, u["host"], 4634, "logoff", "success", u["name"], winlog__logon_type=2)

# админы
for a in ADMINS.values():
    ts = rnd_time(t(8, 30), t(9))
    logon_ok(ts, a["host"], a["name"], 2)

# heartbeat источников (каждые 5 минут)
SOURCES_HB = {"windows": "DC-01", "sysmon": "SENSOR-AGG", "linux": "SRV-WEB-01", "dns": "DC-01", "proxy": "PROXY-01",
              "vpn": "GW-VPN-01", "mail": "MAIL-01", "zeek": "SENSOR-01", "suricata": "SENSOR-01"}
cur = t(0)
while cur < t(23, 59, 59):
    for src, host in SOURCES_HB.items():
        if src == "vpn" and VPN_GAP[0] <= cur < VPN_GAP[1]:
            continue
        add("heartbeat", cur + dt.timedelta(seconds=R.randrange(0, 20)), host={"name": host},
            heartbeat={"source": src, "status": "ok"})
    cur += dt.timedelta(minutes=5)

# ---------------------------------------------------------------- СЦЕНАРИИ
# SC10. m.petrova: старый сохранённый пароль к общей папке (безобидно)
for k, ss in enumerate([40, 41, 41]):
    logon_fail(t(8, 15, ss, 100 * k), "SRV-FS-01", "m.petrova", 3, "192.168.10.27")
logon_ok(t(8, 15, 42), "SRV-FS-01", "m.petrova", 3, "192.168.10.27")
truth["T02"] = {"benign_chain_user": "m.petrova", "benign_chain_type": "3", "benign_chain_src": "192.168.10.27"}

# SC1. Подбор пароля a.ivanov
bf_src = "203.0.113.20"
n_bf = 212
for k in range(n_bf):
    ts = t(10, 32) + dt.timedelta(seconds=k * (14 * 60 + 50) / n_bf)
    logon_fail(ts, "DC-01", "a.ivanov", 3, bf_src, ws="-")
win(t(10, 47, 12), "DC-01", 4740, "account-locked", "success", "a.ivanov", winlog__caller_computer="GW-VPN-01",
    winlog__subject_user="SYSTEM")
truth["T02"].update({"bf_user": "a.ivanov", "bf_count": str(n_bf), "bf_src": bf_src, "lockout_time": "10:47:12"})

# SC2. Перебор одного пароля по многим записям
spray_src = "203.0.113.66"
targets = [u for u in USERS if u != "a.ivanov"][:40]
nonexist = ["admin", "test", "backup", "scanner", "1c"]
spray_names = targets + nonexist
R.shuffle(spray_names)
for k, name in enumerate(spray_names):
    ts = t(14, 0, 5) + dt.timedelta(seconds=k * 8)
    if name in nonexist:
        logon_fail(ts, "DC-01", name, 3, spray_src, sub="0xC0000064")
    elif name == "k.smirnov":
        continue
    else:
        logon_fail(ts, "DC-01", name, 3, spray_src)
logon_ok(t(14, 6, 31), "DC-01", "k.smirnov", 3, spray_src)
truth["T03"] = {"spray_src": spray_src, "spray_success_user": "k.smirnov", "spray_success_time": "14:06:31",
                "bf_src": bf_src}  # число записей считается ниже по самим событиям
# k.smirnov — не в списке неудачных: успешный вход с первой попытки (пароль подошёл)

# SC3. Фишинг и «маяк» на PC-07
ph_sender = "billing@examp1e-pay.test"
ph_rcpts = ["m.petrova", "a.ivanov", "e.belova", "s.orlov", "d.volkov"]
for k, r in enumerate(ph_rcpts):
    act = "quarantined" if r == "d.volkov" else "delivered"
    mail(t(9, 2, 11 + k), ph_sender, r + "@lab.test", "Счёт на оплату №4471", "invoice.zip", "pass", "none", "none", act,
         reply_to="pay-dept@examp1e-pay.test")
mail(t(9, 31, 5), "e.belova@lab.test", "soc@lab.test", "Подозрительное письмо «Счёт на оплату №4471»", "message.eml",
     "pass", "pass", "pass", "delivered")
pc7 = "PC-07"
upd = r"C:\Users\m.petrova\AppData\Local\Temp\invoice\update.exe"
upd_guid = guid(pc7, "update.exe")
exp_guid = guid(pc7, "explorer")
upd_pid = 7312
sysmon_proc(t(9, 14, 2), pc7, "m.petrova", "update.exe", upd, f'"{upd}" /silent', "explorer.exe",
            r"C:\Windows\explorer.exe", exp_guid, upd_guid, upd_pid, 3120, signed=False,
            h="5e3c1a0f9d2b7c4e8a6f1b3d5c7e9a0b2d4f6a8c0e1b3d5f7a9c1e3b5d7f9a1c")
sysmon_proc(t(9, 14, 5), pc7, "m.petrova", "cmd.exe", r"C:\Windows\System32\cmd.exe", "cmd.exe /c whoami",
            "update.exe", upd, upd_guid, guid(pc7, "cmd-whoami"), 7340, upd_pid)
sysmon_proc(t(9, 14, 6), pc7, "m.petrova", "powershell.exe",
            r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
            "powershell.exe -nop -w hidden -enc …", "update.exe", upd, upd_guid, guid(pc7, "ps-enc"), 7356, upd_pid)
c2_domain, c2_ip = "cdn-upd.test", "203.0.113.45"
sysmon_dns(t(9, 14, 58), pc7, "m.petrova", "update.exe", upd, upd_guid, c2_domain, c2_ip)
dns(t(9, 14, 58, 20), "192.168.10.27", c2_domain, c2_ip)
beacon = t(9, 15, 0)
n_beacon = 0
while beacon < t(11, 32):
    sysmon_net(beacon, pc7, "m.petrova", "update.exe", upd, upd_guid, c2_ip, 443, "192.168.10.27")
    zeek(beacon + dt.timedelta(milliseconds=40), "192.168.10.27", c2_ip, 443, "tcp", 0.31, 517, 389, service="ssl")
    n_beacon += 1
    beacon += dt.timedelta(seconds=60)
suricata(t(9, 20, 0, 40), "192.168.10.27", 50322, c2_ip, 443, 9000101,
         "LAB TRAINING Possible beacon: periodic TLS to newly observed domain", "Potentially Bad Traffic", 2)
truth["T04"] = {"proc": "update.exe", "parent": "explorer.exe", "children": "2", "c2_ip": c2_ip, "c2_domain": c2_domain,
                "user": "m.petrova", "host": pc7, "start": "09:14:02"}
truth["T05"] = {"interval": "60", "connections": str(n_beacon)}
truth["T06"] = {"sender_domain": "examp1e-pay.test", "delivered": "4", "quarantined_user": "d.volkov",
                "reported_by": "e.belova", "spf": "pass", "dmarc": "none"}
truth["T12"] = {"sid": "9000101", "zeek_service": "ssl", "c2_port": "443"}

# SC4. Ночная учётная запись с правами администратора домена
win(t(2, 13, 44), "DC-01", 4720, "user-created", "success", "helpdesk_tmp", winlog__subject_user="adm.kuznetsov")
win(t(2, 14, 10), "DC-01", 4728, "group-member-added", "success", "helpdesk_tmp", winlog__subject_user="adm.kuznetsov",
    group__name="Domain Admins")
vpn(t(2, 11, 40), "adm.kuznetsov", "198.51.100.140", "connect", "10.8.0.15", mfa="approved")  # попадёт в провал журналов VPN
logon_ok(t(2, 12, 30), "DC-01", "adm.kuznetsov", 10, "10.8.0.15")
logon_ok(t(2, 20, 3), "SRV-FS-01", "helpdesk_tmp", 10, "10.8.0.15")
zeek(t(2, 12, 29), "10.8.0.15", "192.168.20.5", 3389, "tcp", 540.2, 2_400_000, 18_900_000, service="rdp")
zeek(t(2, 20, 2), "10.8.0.15", "192.168.20.20", 3389, "tcp", 1820.7, 5_100_000, 61_000_000, service="rdp")
# легальное изменение по заявке
win(t(11, 5, 7), "DC-01", 4732, "group-member-added", "success", "n.sokolova", winlog__subject_user="adm.kuznetsov",
    group__name="Backup Operators")
truth["T07"] = {"account": "helpdesk_tmp", "creator": "adm.kuznetsov", "group": "Domain Admins", "created": "02:13:44",
                "ticket": "нет", "legit_ticket": "CHG-5512", "src": "10.8.0.15"}
truth["T11"] = {"gap_source": "vpn", "gap_start": "00:58", "gap_end": "05:34"}

# SC5. Утечка через облачное хранилище
for k in range(34):
    ts = t(19, 40) + dt.timedelta(seconds=k * 53)
    proxy(ts, "k.smirnov", "192.168.10.32", "PUT", "files.example-share.test", 201, 100_000_000, 2_400,
          category="Файлообменники", path=f"/upload/part{k:02d}")
for k in range(6):
    proxy(t(1, 0) + dt.timedelta(minutes=k * 9), "svc-backup", "192.168.20.40", "PUT", "backup.example.com", 201,
          7_500_000_000, 3_000, category="Резервное копирование", path=f"/vault/night/{k}")
truth["T08"] = {"user": "k.smirnov", "domain": "files.example-share.test", "mb": str(34 * 100), "expected_user": "svc-backup",
                "start": "19:40"}

# SC6. Linux: перебор SSH и обычная работа
names = ["admin", "test", "oracle", "ubuntu", "postgres", "user", "git", "deploy1"]
for k in range(60):
    ts = t(3, 0, 4) + dt.timedelta(seconds=k * 4)
    nm = names[k % len(names)]
    linux(ts, "sshd", 31000 + k, f"Failed password for invalid user {nm} from 198.51.100.23 port {40000 + k} ssh2",
          "ssh_login", nm, "198.51.100.23", "failure")
linux(t(9, 29, 50), "sshd", 32101, "Failed password for n.sokolova from 192.168.20.10 port 51544 ssh2",
      "ssh_login", "n.sokolova", "192.168.20.10", "failure")
linux(t(9, 30, 2), "sshd", 32102, "Accepted password for n.sokolova from 192.168.20.10 port 51551 ssh2",
      "ssh_login", "n.sokolova", "192.168.20.10", "success")
linux(t(10, 2, 15), "sudo", 32190, "n.sokolova : TTY=pts/0 ; PWD=/home/n.sokolova ; USER=root ; COMMAND=/usr/bin/systemctl restart nginx",
      "sudo", "n.sokolova", None, "success")
linux(t(16, 20, 0), "sshd", 33001, "Accepted publickey for deploy from 192.168.20.70 port 60112 ssh2: ED25519 SHA256:…",
      "ssh_login", "deploy", "192.168.20.70", "success")
linux(t(16, 20, 9), "sudo", 33010, "deploy : TTY=pts/1 ; PWD=/srv/app ; USER=www-data ; COMMAND=/usr/bin/git pull",
      "sudo", "deploy", None, "success")
truth["T09"] = {"src": "198.51.100.23", "failed": "60", "success": "нет", "sudo_cmd": "/usr/bin/systemctl restart nginx",
                "admin_first_fail": "09:29:50"}

# SC7. VPN: усталость от MFA и безобидная «география»
for k in range(5):
    vpn(t(22, 15) + dt.timedelta(seconds=k * 40), "o.lebedeva", "198.51.100.77", "mfa-push", mfa="denied",
        country="DE", device="new", asn="Хостинг-провайдер")
vpn(t(22, 19, 2), "o.lebedeva", "198.51.100.77", "connect", "10.8.0.201", mfa="approved", country="DE", device="new",
    asn="Хостинг-провайдер")
logon_ok(t(22, 20, 15), "DC-01", "o.lebedeva", 3, "10.8.0.201")
vpn(t(12, 40), "k.smirnov", "203.0.113.130", "connect", "10.8.0.44", mfa="approved", country="RU", device="known",
    asn="Мобильный оператор")
truth["T10"] = {"mfa_user": "o.lebedeva", "mfa_denied": "5", "approved_time": "22:19:02", "country": "DE",
                "benign_user": "k.smirnov"}

# SC8. Ложное срабатывание: ночное резервное копирование
for k in range(3):
    sysmon_proc(t(1, 0, 2) + dt.timedelta(minutes=k * 20), "SRV-BACKUP-01", "svc-backup", "powershell.exe",
                r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
                r"powershell.exe -NoProfile -File C:\Scripts\backup\job.ps1", "svchost.exe",
                r"C:\Windows\System32\svchost.exe", guid("SRV-BACKUP-01", "svchost"),
                guid("SRV-BACKUP-01", "job", k), 9100 + k, 1220)
    suricata(t(1, 0, 30) + dt.timedelta(minutes=k * 20), "192.168.20.40", 49800 + k, "198.51.100.200", 443, 9000220,
             "LAB TRAINING Large outbound transfer", "Policy Violation", 3)
truth["T13"] = {"fp_host": "SRV-BACKUP-01"}

# ---------------------------------------------------------------- запись
DATA.mkdir(parents=True, exist_ok=True)
(DATA / "raw").mkdir(exist_ok=True)
counts = {}
for index, items in events.items():
    items.sort(key=lambda x: x[0])
    with open(DATA / f"{index}.ndjson", "w", encoding="utf-8", newline="\n") as f:
        for _, doc in items:
            f.write(json.dumps(doc, ensure_ascii=False) + "\n")
    counts[index] = len(items)

linux_lines.sort()
(DATA / "raw" / "auth.log").write_text("\n".join(l for _, l in linux_lines) + "\n", encoding="utf-8", newline="\n")
with open(DATA / "raw" / "eve.json", "w", encoding="utf-8", newline="\n") as f:
    for ts, d in sorted(events["suricata"], key=lambda x: x[0]):
        f.write(json.dumps({"timestamp": ts.strftime("%Y-%m-%dT%H:%M:%S.%f")[:-3] + "+0300", "event_type": "alert",
                            "src_ip": d["source"]["ip"], "src_port": d["source"]["port"],
                            "dest_ip": d["destination"]["ip"], "dest_port": d["destination"]["port"], "proto": "TCP",
                            "alert": d["suricata"]["alert"]}, ensure_ascii=False) + "\n")

with open(DATA / "users.csv", "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerow(["user", "department", "workstation", "ip", "remote_worker"])
    for u in list(USERS.values()) + list(ADMINS.values()):
        w.writerow([u["name"], u["dept"], u["host"], u["ip"], "да" if u["remote"] else "нет"])
with open(DATA / "assets.csv", "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerow(["host", "ip", "role", "criticality", "owner", "sysmon"])
    for h, (ip, role, crit, owner) in SERVERS.items():
        w.writerow([h, ip, role, crit, owner, "да" if h.startswith(("DC", "SRV")) else "нет"])
    for u in USERS.values():
        w.writerow([u["host"], u["ip"], f"Рабочая станция ({u['dept']})", "C", u["name"],
                    "нет" if u["host"] in NO_SYSMON else "да"])
with open(DATA / "tickets.csv", "w", encoding="utf-8", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerow(["ticket", "date", "window", "change", "approved_by"])
    w.writerow(["CHG-5512", "20.10.2026", "11:00–11:30", "Добавить n.sokolova в Backup Operators на SRV-BACKUP-01 и DC-01", "ИТ-директор"])
    w.writerow(["CHG-5490", "20.10.2026", "01:00–02:00", "Ночное резервное копирование (svc-backup) в backup.example.com", "ИТ-директор"])
    w.writerow(["CHG-5520", "21.10.2026", "22:00–23:00", "Обновление nginx на SRV-WEB-01", "ИТ-директор"])

# ответы, которые надёжнее посчитать по готовым данным
fails_spray = [d for _, d in events["windows"] if d["event"]["code"] == "4625" and d["source"]["ip"] == spray_src]
truth["T03"]["spray_accounts"] = str(len({d["user"]["name"] for d in fails_spray}))
truth["T03"]["spray_nonexistent"] = str(sum(1 for d in fails_spray if d["winlog"]["substatus"] == "0xC0000064"))
truth["T02"]["bf_count"] = str(sum(1 for _, d in events["windows"] if d["event"]["code"] == "4625" and d["source"]["ip"] == bf_src))
truth["T05"]["connections"] = str(sum(1 for _, d in events["sysmon"] if d["event"]["code"] == "3" and d["destination"]["ip"] == c2_ip))
truth["T01"] = {"sources": str(len(counts) - 1), "win_4625": str(sum(1 for _, d in events["windows"] if d["event"]["code"] == "4625")),
                "tz": "UTC+3"}
TEACHER.mkdir(parents=True, exist_ok=True)
(TEACHER / "ground_truth.json").write_text(json.dumps({"counts": counts, "answers": truth}, ensure_ascii=False, indent=1),
                                           encoding="utf-8")
print(json.dumps(counts, ensure_ascii=False))
print(json.dumps(truth, ensure_ascii=False, indent=1))
