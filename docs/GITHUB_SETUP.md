# Setup del backlog en GitHub

El agente cloud creó los **issues** (#3–#33) pero no pudo crear **labels** ni **milestones** (permisos del token). El maintainer del repo debe completar este setup una sola vez.

## 1. Labels (Settings → Labels → New label)

| Label | Color | Descripción |
|-------|-------|-------------|
| `epic` | `#5319E7` | Épica de producto |
| `fase-1` | `#0E8A16` | Fase 1 — Credibilidad técnica |
| `fase-2` | `#1D76DB` | Fase 2 — Cierre comercial |
| `fase-3` | `#5319E7` | Fase 3 — Plataforma B2B |
| `fase-4` | `#6F42C1` | Fase 4 — Ecosistema |
| `priority:p0` | `#B60205` | Crítico |
| `priority:p1` | `#D93F0B` | Alto |
| `priority:p2` | `#FBCA04` | Medio |
| `priority:p3` | `#0E8A16` | Bajo |
| `area:medicion` | `#1D76DB` | Medición y sitio |
| `area:diseño` | `#006B75` | Diseño técnico |
| `area:ventas` | `#C5DEF5` | Propuesta y ventas |
| `area:plataforma` | `#D4C5F9` | CRM, cloud, sync |
| `area:datos` | `#BFDADC` | Datos solares y persistencia |
| `area:ops` | `#FEF2C0` | Post-venta |

O ejecutar (como owner):

```bash
./scripts/setup_github_labels.sh
```

## 2. Milestones (Issues → Milestones → New milestone)

| Título | Descripción |
|--------|-------------|
| Fase 1 — Credibilidad técnica | Sitio real, PVGIS, persistencia, layout PDF |
| Fase 2 — Cierre comercial | Variantes, firma, financiamiento, catálogo |
| Fase 3 — Plataforma B2B | CRM, cloud, stringing, diagramas |
| Fase 4 — Ecosistema | EV, heat pump, post-venta |

Asignar issues por prefijo `[F1]` → Fase 1, `[F2]` → Fase 2, etc.

## 3. GitHub Project (opcional)

Crear board **SolarScan Roadmap** con columnas:

`Backlog → Ready → In Progress → In Review → Done`

Automatización sugerida:
- PR merged → issue linked closes
- Issue opened with `[Epic]` → column Backlog

## 4. Migración a GitLab (si aplica)

Si el repo se mueve a GitLab, mapeo:

| GitHub | GitLab |
|--------|--------|
| Milestone | Milestone |
| Epic issue | Epic (Premium) o label `epic` |
| Issue | Issue |
| `[F1][P0]` prefix | Weight + label |

Importar con: GitLab → Settings → Repository → Mirroring, o herramienta de migración de issues.
