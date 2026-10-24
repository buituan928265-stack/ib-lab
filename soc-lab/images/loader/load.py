"""Загрузка синтетических журналов в учебный SIEM (OpenSearch + Dashboards).

Повторный запуск безопасен: если данные этой версии уже загружены, ничего не делает.
Перезагрузить с нуля: docker compose down -v && docker compose up -d
"""
import json
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

OS = "http://opensearch:9200"
OSD = "http://dashboards:5601"
DATA = Path("/data")
VERSION = "soc-lab-2026-10-20-v3"
SOURCES = ["windows", "sysmon", "linux", "dns", "proxy", "vpn", "mail", "zeek", "suricata", "heartbeat"]
IP_FIELDS = [("source", "ip"), ("destination", "ip"), ("vpn", "assigned_ip")]


def call(method, url, body=None, headers=None, ok=(200, 201)):
    data = None
    hdrs = {"Content-Type": "application/json"}
    hdrs.update(headers or {})
    if body is not None:
        data = body.encode() if isinstance(body, str) else json.dumps(body).encode()
    req = urllib.request.Request(url, data=data, method=method, headers=hdrs)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        if e.code in ok:
            return e.code, {}
        return e.code, json.loads(e.read() or b"{}")


def wait(url, what):
    for _ in range(120):
        try:
            with urllib.request.urlopen(url, timeout=5) as r:
                if r.status == 200:
                    return
        except Exception:
            pass
        print(f"жду {what}…", flush=True)
        time.sleep(5)
    raise SystemExit(f"{what} не ответил")


TEMPLATE = {
    "index_patterns": ["logs-*"],
    "template": {
        "settings": {"number_of_shards": 1, "number_of_replicas": 0},
        "mappings": {
            "dynamic_templates": [{"strings": {"match_mapping_type": "string",
                                               "mapping": {"type": "keyword", "ignore_above": 2048}}}],
            "properties": {
                "@timestamp": {"type": "date"},
                "message": {"type": "text", "fields": {"keyword": {"type": "keyword", "ignore_above": 2048}}},
                "source": {"properties": {"ip": {"type": "ip"}}},
                "destination": {"properties": {"ip": {"type": "ip"}}},
                "vpn": {"properties": {"assigned_ip": {"type": "ip"}}},
                "network": {"properties": {"bytes_out": {"type": "long"}, "bytes_in": {"type": "long"}}},
                "event": {"properties": {"duration": {"type": "float"}}},
            },
        },
    },
}


def clean(doc):
    for parent, field in IP_FIELDS:
        if doc.get(parent, {}).get(field) == "-":
            del doc[parent][field]
    return doc


SA = f"{OS}/_plugins/_security_analytics"
# Правила Sigma для журналов Windows ссылаются на поля Image, CommandLine и т. п.;
# Security Analytics ищет их под именами winlog.*. Сопоставляем с полями наших событий Sysmon.
SIGMA_ALIASES = {
    "winlog.event_id": "event.code",
    "winlog.computer_name": "host.name",
    "winlog.event_data.Image": "process.executable",
    "winlog.event_data.ParentImage": "process.parent.executable",
    "winlog.event_data.User": "user.name",
}
DETECTOR = "LAB Sysmon"


def setup_sigma():
    """Учебные правила Sigma и детектор в Security Analytics (задание 14)."""
    # убрать то, что осталось от прошлой загрузки
    _, res = call("POST", f"{SA}/detectors/_search", {"query": {"match_all": {}}}, ok=(200, 404))
    for hit in res.get("hits", {}).get("hits", []):
        if hit["_source"].get("name") == DETECTOR:
            call("DELETE", f"{SA}/detectors/{hit['_id']}")
    _, res = call("POST", f"{SA}/rules/_search?pre_packaged=false", {"size": 100, "query": {"match_all": {}}})
    for hit in res.get("hits", {}).get("hits", []):
        if hit["_source"].get("title", "").startswith("LAB:"):
            call("DELETE", f"{SA}/rules/{hit['_id']}?forced=true")
    status, res = call("POST", f"{SA}/mappings", {
        "index_name": "logs-sysmon", "rule_topic": "windows", "partial": True,
        "alias_mappings": {"properties": {k: {"type": "alias", "path": v} for k, v in SIGMA_ALIASES.items()}}})
    if status != 200:
        raise SystemExit(f"Не удалось сопоставить поля для Sigma: {res}")
    rule_ids = []
    for path in sorted(Path("/sigma").glob("*.yml")):
        status, res = call("POST", f"{SA}/rules?category=windows", path.read_text(encoding="utf-8"))
        if status != 201:
            raise SystemExit(f"Правило {path.name} не принято: {res}")
        rule_ids.append(res["_id"])
        print(f"правило Sigma: {res['rule']['title']}", flush=True)
    status, res = call("POST", f"{SA}/detectors", {
        "type": "detector", "detector_type": "windows", "name": DETECTOR, "enabled": True,
        "schedule": {"period": {"interval": 1, "unit": "MINUTES"}},
        "inputs": [{"detector_input": {"description": "Учебный детектор: события Sysmon компании LAB",
                                       "indices": ["logs-sysmon"], "custom_rules": [{"id": i} for i in rule_ids],
                                       "pre_packaged_rules": []}}],
        "triggers": [{"name": "Любое срабатывание", "severity": "1", "types": ["windows"], "ids": rule_ids,
                      "sev_levels": [], "tags": [], "actions": []}]})
    if status != 201:
        raise SystemExit(f"Детектор не создан: {res}")
    detector_id = res["_id"]
    # Детектор проверяет только события, поступившие после его запуска,
    # поэтому даём ему стартовать и «переподаём» события Sysmon.
    print("жду первый запуск детектора…", flush=True)
    time.sleep(75)
    call("POST", f"{OS}/logs-sysmon/_update_by_query?conflicts=proceed&refresh=true")
    for _ in range(20):
        time.sleep(15)
        _, res = call("GET", f"{SA}/findings/_search?detector_id={detector_id}&size=50")
        total = res.get("total_findings") or 0
        if total >= 5:
            break
    print(f"Security Analytics: срабатываний {total}", flush=True)


def main():
    wait(f"{OS}/_cluster/health", "OpenSearch")
    status, meta = call("GET", f"{OS}/lab-meta/_doc/state", ok=(200, 404))
    if status == 200 and meta.get("_source", {}).get("version") == VERSION:
        print("Данные уже загружены.")
    else:
        call("PUT", f"{OS}/_index_template/logs-lab", TEMPLATE)
        for src in SOURCES:
            call("DELETE", f"{OS}/logs-{src}", ok=(200, 404))
            lines = (DATA / f"{src}.ndjson").read_text(encoding="utf-8").splitlines()
            for start in range(0, len(lines), 2000):
                chunk = []
                for line in lines[start:start + 2000]:
                    chunk.append(json.dumps({"index": {"_index": f"logs-{src}"}}))
                    chunk.append(json.dumps(clean(json.loads(line)), ensure_ascii=False))
                status, res = call("POST", f"{OS}/_bulk?refresh=false", "\n".join(chunk) + "\n",
                                   headers={"Content-Type": "application/x-ndjson"})
                if res.get("errors"):
                    bad = [i for i in res["items"] if i["index"].get("error")][:2]
                    raise SystemExit(f"Ошибка загрузки {src}: {json.dumps(bad, ensure_ascii=False)}")
            print(f"logs-{src}: {len(lines)} событий", flush=True)
        call("POST", f"{OS}/logs-*/_refresh")
        setup_sigma()
        call("PUT", f"{OS}/lab-meta/_doc/state?refresh=true", {"version": VERSION})

    wait(f"{OSD}/api/status", "OpenSearch Dashboards")
    h = {"osd-xsrf": "true"}
    patterns = [("logs-all", "logs-*")] + [(f"logs-{s}", f"logs-{s}") for s in SOURCES]
    for pid, title in patterns:
        # список полей нужен Dashboards сразу, иначе сортировка по времени выдаёт ошибку
        query = urllib.parse.urlencode([("pattern", title), ("meta_fields", "_source"), ("meta_fields", "_id"),
                                        ("meta_fields", "_index"), ("meta_fields", "_score")])
        status, res = call("GET", f"{OSD}/api/index_patterns/_fields_for_wildcard?{query}", headers=h)
        fields = res.get("fields", [])
        call("POST", f"{OSD}/api/saved_objects/index-pattern/{pid}?overwrite=true",
             {"attributes": {"title": title, "timeFieldName": "@timestamp",
                             "fields": json.dumps(fields, ensure_ascii=False)}}, headers=h)
        print(f"шаблон {title}: {len(fields)} полей", flush=True)
    status, res = call("POST", f"{OSD}/api/opensearch-dashboards/settings", {"changes": {
        "dateFormat:tz": "Europe/Moscow",
        "defaultIndex": "logs-all",
        "timepicker:timeDefaults": json.dumps({"from": "2026-10-19T21:00:00.000Z", "to": "2026-10-20T20:59:59.999Z"}),
        "theme:darkMode": False,
    }}, headers=h)
    print("Интерфейс SIEM настроен:", status)
    print("Готово. Откройте http://127.0.0.1:5601")


if __name__ == "__main__":
    main()
