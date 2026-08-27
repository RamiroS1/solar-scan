#!/usr/bin/env bash
# Crea issues del backlog (solo requiere permiso issues:write).
set -euo pipefail
REPO="${1:-RamiroS1/solar-scan}"

issue() {
  gh issue create --repo "$REPO" --title "$1" --body "$2"
}

echo "==> Fase 1 — Epics"
E1=$(issue "[Epic E1] Persistencia y continuidad de datos" "**Milestone:** Fase 1 — Credibilidad técnica
**Labels:** epic, fase-1, priority:p0, area:datos

## Problema
Al cerrar la app se pierden todos los proyectos.

## Resultado esperado
Proyectos persisten entre sesiones; CRUD completo; base para sync futuro.

## Tickets hijos
- E1.1 Persistencia local (SQLite/Drift)
- E1.2 Migraciones de schema
- E1.3 Export/import JSON")

E2=$(issue "[Epic E2] Medición con sitio real" "**Milestone:** Fase 1
**Labels:** epic, fase-1, priority:p0, area:medicion

## Problema
Medición sobre lienzo abstracto no representa el techo real.

## Tickets hijos
- E2.1 Geocoding + pin
- E2.2 Vista satelital
- E2.3 Multi-faldón
- E2.4 Edición de vértices")

E3=$(issue "[Epic E3] Datos solares reales (PVGIS)" "**Milestone:** Fase 1
**Labels:** epic, fase-1, priority:p0, area:datos

## Problema
Irradiancia por keywords; imprecisa entre regiones.

## Tickets hijos
- E3.1 Cliente PVGIS + cache
- E3.2 Fallback offline
- E3.3 UI supuestos editables")

E4=$(issue "[Epic E4] Diseño técnico creíble" "**Milestone:** Fase 1
**Labels:** epic, fase-1, priority:p1, area:diseño

## Tickets hijos
- E4.1 Análisis sombras básico
- E4.2 Layout 2D en PDF
- E4.3 Heatmap irradiancia")

echo "E1=$E1 E2=$E2 E3=$E3 E4=$E4"

echo "==> Fase 1 — Tickets P0"
issue "[F1][P0] E1.1 — Persistencia local (SQLite/Drift)" "**Epic:** $E1
**Labels:** fase-1, priority:p0, area:datos

## User story
Como instalador, quiero que mis proyectos se guarden automáticamente, para retomar una visita al día siguiente.

## Criterios de aceptación
- [ ] Proyectos persisten al cerrar y reabrir la app
- [ ] CRUD: crear, editar, eliminar proyectos
- [ ] Capa \`lib/data/\` desacoplada del domain
- [ ] Tests de repositorio

## Técnico
- Evaluar Drift o sqflite
- Migrar AppState a repositorio"

issue "[F1][P0] E2.1 — Geocoding y pin de ubicación" "**Epic:** $E2
**Labels:** fase-1, priority:p0, area:medicion

## User story
Como instalador, quiero que la dirección se convierta en coordenadas en mapa.

## Criterios de aceptación
- [ ] Geocoding al crear proyecto
- [ ] lat/lon persistidos en Project
- [ ] Pin ajustable manualmente
- [ ] Visible en supuestos de propuesta

## Técnico
- \`lib/domain/geocoding.dart\`
- Extender SolarSiteResolver"

issue "[F1][P0] E3.1 — Cliente PVGIS con cache offline" "**Epic:** $E3
**Labels:** fase-1, priority:p0, area:datos

## Criterios de aceptación
- [ ] HTTP a PVGIS por lat/lon
- [ ] GHI/temp mensual cacheados
- [ ] Production.estimate usa PVGIS
- [ ] Fallback regional sin red
- [ ] Tests con mock HTTP

## Técnico
- \`lib/domain/pvgis_client.dart\`"

issue "[F1][P0] E4.2 — Exportar layout 2D al PDF" "**Epic:** $E4
**Labels:** fase-1, priority:p0, area:diseño

## Criterios de aceptación
- [ ] Plano con paneles en PDF
- [ ] Leyenda de módulos y área
- [ ] Reutiliza RoofPainter

## Técnico
- \`lib/domain/layout_export.dart\`"

issue "[F1][P1] E2.2 — Vista satelital en captura" "**Epic:** $E2
**Labels:** fase-1, priority:p1, area:medicion

## Criterios de aceptación
- [ ] Imagen satelital de fondo en CaptureScreen
- [ ] Escala alineada en metros
- [ ] Depende de E2.1"

issue "[F1][P1] E4.1 — Análisis de sombras básico" "**Epic:** $E4
**Labels:** fase-1, priority:p1, area:diseño

## Criterios de aceptación
- [ ] Trayectoria solar anual
- [ ] Pérdida % estimada por obstáculos
- [ ] Reflejado en producción"

echo "==> Fase 2 — Epics + tickets"
E5=$(issue "[Epic E5] Propuesta con variantes" "**Milestone:** Fase 2 — Cierre comercial
**Labels:** epic, fase-2, priority:p0, area:ventas

Variantes Básico/Estándar/Premium con BOM y capex independientes.")

E6=$(issue "[Epic E6] Aceptación digital (link + firma)" "**Milestone:** Fase 2
**Labels:** epic, fase-2, priority:p0, area:ventas

Link web PWA + firma del cliente + estado APROBADO.")

E7=$(issue "[Epic E7] Financiamiento y cuotas" "**Milestone:** Fase 2
**Labels:** epic, fase-2, priority:p1, area:ventas

Calculadora préstamo; cuota mensual en propuesta.")

E8=$(issue "[Epic E8] Catálogo editable del instalador" "**Milestone:** Fase 2
**Labels:** epic, fase-2, priority:p1, area:ventas

CRUD equipos y precios por empresa.")

issue "[F2][P0] E5.1 — Modelo ProposalVariant" "**Epic:** $E5

## Criterios de aceptación
- [ ] N variantes por Project
- [ ] BOM/capex/production por variante
- [ ] UI comparativa en ProposalScreen"

issue "[F2][P0] E6.1 — Link web de propuesta (PWA)" "**Epic:** $E6

## Criterios de aceptación
- [ ] URL única por propuesta
- [ ] Cliente ve propuesta sin app
- [ ] Responsive mobile"

issue "[F2][P0] E6.2 — Firma digital del cliente" "**Epic:** $E6

## Criterios de aceptación
- [ ] Canvas firma en PWA
- [ ] Timestamp
- [ ] status → approved
- [ ] Firma embebida en PDF"

issue "[F2][P1] E7.1 — Calculadora de cuota mensual" "**Epic:** $E7

## Criterios de aceptación
- [ ] Plazo, tasa, cuota en propuesta
- [ ] Comparativa vs contado"

issue "[F2][P1] E8.1 — CRUD catálogo del instalador" "**Epic:** $E8

## Criterios de aceptación
- [ ] Paneles/inversores/baterías editables
- [ ] Precio compra + margen
- [ ] Reemplaza catalog hardcodeado"

echo "==> Fase 3"
E9=$(issue "[Epic E9] CRM y pipeline de ventas" "**Milestone:** Fase 3 — Plataforma B2B
Kanban, tareas, historial.")

E10=$(issue "[Epic E10] Cloud sync y equipos" "**Milestone:** Fase 3
Backend API, auth, roles, sync offline.")

E11=$(issue "[Epic E11] Diseño eléctrico (stringing + diagramas)" "**Milestone:** Fase 3
Strings, validación inversor, unifilar PDF.")

issue "[F3][P1] E9.1 — Pipeline Kanban" "**Epic:** $E9
- [ ] Vista Kanban por estado
- [ ] Drag entre columnas
- [ ] Filtros"

issue "[F3][P1] E10.1 — Backend API + auth" "**Epic:** $E10
- [ ] Login
- [ ] Sync proyectos
- [ ] REST o Supabase"

issue "[F3][P1] E11.1 — Stringing automático" "**Epic:** $E11
- [ ] Strings por inversor
- [ ] Validación Voc/Isc
- [ ] Visual en DesignScreen"

issue "[F3][P2] E11.2 — Diagrama unifilar PDF" "**Epic:** $E11
- [ ] Export PDF simplificado
- [ ] Inversor, strings, protecciones"

echo "==> Fase 4"
E12=$(issue "[Epic E12] Post-venta e instalación" "**Milestone:** Fase 4
Checklists, calendario, handover pack.")

E13=$(issue "[Epic E13] Ecosistema (EV + heat pump)" "**Milestone:** Fase 4
Wallbox, bomba calor en BOM.")

issue "[F4][P2] E12.1 — Checklists de instalación" "**Epic:** $E12
- [ ] Templates checklist
- [ ] Fotos por ítem"

issue "[F4][P3] E13.1 — Wallbox en BOM y cotización" "**Epic:** $E13
- [ ] Catálogo EV charger
- [ ] Integración propuesta"

issue "[F4][P3] E14.1 — Integración WhatsApp + link propuesta" "**Milestone:** Fase 4
Template mensaje con URL de propuesta web."

echo "==> Done: https://github.com/$REPO/issues"
