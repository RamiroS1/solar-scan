#!/usr/bin/env bash
# Requiere permisos admin en el repo. Ejecutar como owner.
set -euo pipefail
REPO="${1:-RamiroS1/solar-scan}"

create_label() {
  gh label create "$1" --repo "$REPO" --color "$2" --description "$3" 2>/dev/null || echo "  (exists) $1"
}

create_label epic 5319E7 "Epica de producto"
create_label fase-1 0E8A16 "Fase 1 — Credibilidad tecnica"
create_label fase-2 1D76DB "Fase 2 — Cierre comercial"
create_label fase-3 5319E7 "Fase 3 — Plataforma B2B"
create_label fase-4 6F42C1 "Fase 4 — Ecosistema"
create_label priority:p0 B60205 "P0 — Critico"
create_label priority:p1 D93F0B "P1 — Alto"
create_label priority:p2 FBCA04 "P2 — Medio"
create_label priority:p3 0E8A16 "P3 — Bajo"
create_label area:medicion 1D76DB "Medicion y sitio"
create_label area:diseño 006B75 "Diseno tecnico"
create_label area:ventas C5DEF5 "Propuesta y ventas"
create_label area:plataforma D4C5F9 "CRM, cloud, sync"
create_label area:datos BFDADC "Datos solares y persistencia"
create_label area:ops FEF2C0 "Post-venta"

for spec in \
  "Fase 1 — Credibilidad técnica|Sitio real, PVGIS, persistencia" \
  "Fase 2 — Cierre comercial|Variantes, firma, financiamiento" \
  "Fase 3 — Plataforma B2B|CRM, cloud, stringing" \
  "Fase 4 — Ecosistema|EV, heat pump, post-venta"; do
  IFS='|' read -r t d <<< "$spec"
  gh api "repos/$REPO/milestones" -f title="$t" -f description="$d" 2>/dev/null || echo "  (exists) $t"
done

echo "Labels y milestones listos."
