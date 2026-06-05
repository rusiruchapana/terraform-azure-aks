# Stage 08 - Dev App Expansion, Capacity Planning, Pay-As-You-Go, and Terraform Import

## මේ stage එකේදී මොකක්ද කරන්නේ?

මෙම stage එකේදී අපි Capstone Store dev app එක minimal setup එකෙන් තවත් real-world workload එකකට expand කරනවා.

කලින් dev app එකේ තිබුණේ:

- store-front
- product-service
- order-service
- rabbitmq

මෙම stage එකේදී add කරනවා:

- mongodb
- makeline-service

මේකෙන් app එක event-driven microservices flow එකකට යනවා:

store-front
→ order-service
→ rabbitmq
→ makeline-service
→ mongodb

## මෙම stage එකේ වැදගත්ම lesson එක

මෙම stage එක application deployment එකක් විතරක් නෙවෙයි.

මෙතන අපිට real cloud engineering issue එකක් ආවා:

- MongoDB pod එක Pending වුණා
- makeline-service එක CrashLoopBackOff වුණා
- root cause එක app bug එකක් නෙවෙයි
- root cause එක cluster capacity / Azure quota limitation එකක්

ඊට පස්සේ අපි:

1. issue එක troubleshoot කළා
2. Azure Free Trial quota limitation identify කළා
3. subscription එක Pay-As-You-Go වලට upgrade කළා
4. cost budget guardrails set කළා
5. quota නැවත check කළා
6. correct VM family choose කළා
7. apps node pool එක add කළා
8. app healthy කළා
9. CLI-created node pool එක Terraform state එකට import කළා
10. Terraform config update කරලා drift clean කළා

මේක real production-style workflow එකක්.

---

# Part 1 - Add MongoDB and makeline-service to GitOps

## 1.1 Extract MongoDB and makeline-service manifests

App source repo එකේ full manifest එකෙන් MongoDB සහ makeline-service resources extract කරනවා.

```bash
cd /Users/andrewferdinandus/projcts/aks-capstone-gitops

python3 - <<'PY'
from pathlib import Path
import re

src = Path("/Users/andrewferdinandus/projcts/aks-capstone-store-app/aks-store-all-in-one.yaml")
out = Path("/Users/andrewferdinandus/projcts/aks-capstone-gitops/apps/capstone-store/base/makeline-mongodb.yaml")

text = src.read_text()
docs = re.split(r"\n---\s*\n", text)

wanted = {
    ("StatefulSet", "mongodb"),
    ("Service", "mongodb"),
    ("Deployment", "makeline-service"),
    ("Service", "makeline-service"),
}

selected = []

for doc in docs:
    kind_match = re.search(r"(?m)^kind:\s*(\S+)\s*$", doc)
    name_match = re.search(r"(?m)^metadata:\s*\n(?:[^\n]*\n)*?\s{2}name:\s*([A-Za-z0-9-]+)\s*$", doc)

    if not kind_match or not name_match:
        continue

    kind = kind_match.group(1)
    name = name_match.group(1)

    if (kind, name) in wanted:
        selected.append(doc.strip())

if len(selected) != 4:
    raise SystemExit(f"Expected 4 resources, found {len(selected)}")

out.write_text("---\n" + "\n---\n".join(selected) + "\n")
print(f"Wrote {len(selected)} resources to {out}")
PY
