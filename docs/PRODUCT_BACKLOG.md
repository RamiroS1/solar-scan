# Product Backlog — SolarScan

Backlog formal derivado del gap analysis vs Reonic y herramientas similares.

**Estado actual:** Fase 0 completada (arquitectura modular + mejoras QA básicas, PR #1).

---

## Visión por fases

| Fase | Milestone | Objetivo | Meta |
|------|-----------|----------|------|
| **1** | Fase 1 — Credibilidad técnica | Sitio real + datos solares confiables | El instalador confía en medición y producción |
| **2** | Fase 2 — Cierre comercial | Propuesta que cierra ventas | Cliente entiende, elige y firma |
| **3** | Fase 3 — Plataforma B2B | CRM + cloud + diseño eléctrico | El instalador opera todo en un solo lugar |
| **4** | Fase 4 — Ecosistema | EV, heat pump, post-venta | Mismo flujo para energía completa del hogar |

---

## Fase 1 — Credibilidad técnica

### Épica E1: Persistencia y continuidad de datos
**Problema:** Al cerrar la app se pierden proyectos. Imposible retomar visitas.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E1.1 | Persistencia local (SQLite/Drift) | P0 | Proyectos sobreviven reinicio; CRUD completo |
| E1.2 | Migraciones de schema | P1 | Versionado de DB; upgrades sin pérdida |
| E1.3 | Export/import JSON de proyecto | P2 | Backup manual; compartir entre dispositivos |

### Épica E2: Medición con sitio real
**Problema:** Lienzo abstracto no representa el techo real del cliente.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E2.1 | Geocoding de dirección → lat/lon | P0 | Pin en mapa; coords persistidas en Project |
| E2.2 | Vista satelital en captura | P0 | Imagen de fondo escalable; alinear contorno |
| E2.3 | Multi-faldón (varias aguas) | P1 | Lista de facets; suma kWp/área total |
| E2.4 | Edición de vértices (drag) | P1 | Mover puntos existentes; snap configurable |

### Épica E3: Datos solares reales
**Problema:** Irradiancia fija por keywords; imprecisa entre regiones.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E3.1 | Cliente PVGIS (HTTP) | P0 | GHI/temp mensual por lat/lon; cache offline |
| E3.2 | Fallback a tablas regionales | P0 | Sin red → usa último cache o regional |
| E3.3 | UI de supuestos solares editables | P1 | Override manual GHI; visible en propuesta |

### Épica E4: Diseño técnico creíble
**Problema:** Layout de paneles sin sombras ni export al PDF.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E4.1 | Análisis de sombras básico | P1 | Trayectoria solar; pérdida % por obstáculo |
| E4.2 | Layout 2D exportado al PDF | P0 | Plano con paneles en propuesta |
| E4.3 | Heatmap de irradiancia en techo | P2 | Visual en pantalla Diseño |

---

## Fase 2 — Cierre comercial

### Épica E5: Propuesta con variantes
**Problema:** Una sola opción; cliente no compara con/sin batería o tiers.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E5.1 | Modelo ProposalVariant | P0 | N variantes por proyecto; BOM/capex propio |
| E5.2 | UI comparativa en propuesta | P0 | Tabs o cards: Básico / Estándar / Premium |
| E5.3 | PDF multi-variante | P1 | Todas las opciones en un documento |

### Épica E6: Aceptación digital
**Problema:** PDF estático; no hay firma ni tracking de aceptación.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E6.1 | Link web de propuesta (PWA) | P0 | URL única; cliente ve propuesta sin app |
| E6.2 | Firma digital del cliente | P0 | Canvas de firma; timestamp; estado APROBADO |
| E6.3 | Notificación al instalador | P2 | Email/push cuando cliente firma |

### Épica E7: Financiamiento
**Problema:** Solo capex total; cliente piensa en cuota mensual.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E7.1 | Calculadora de cuota (préstamo) | P1 | Plazo, tasa, cuota mensual en propuesta |
| E7.2 | Comparativa contado vs financiado | P2 | Tabla en PDF |

### Épica E8: Catálogo del instalador
**Problema:** Precios y equipos hardcodeados; cada empresa usa otros productos.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E8.1 | CRUD catálogo paneles/inversores/baterías | P1 | Precio compra, margen, activo/inactivo |
| E8.2 | Reglas de margen por categoría | P2 | % default por tipo de equipo |

---

## Fase 3 — Plataforma B2B

### Épica E9: CRM y pipeline
**Problema:** Lista plana de proyectos; sin seguimiento comercial.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E9.1 | Pipeline Kanban (Lead → Instalado) | P1 | Drag estados; filtros |
| E9.2 | Tareas y recordatorios | P1 | Due date; vinculadas a proyecto |
| E9.3 | Historial de actividad | P2 | Log: propuesta enviada, vista, firmada |

### Épica E10: Cloud sync y equipos
**Problema:** Un solo dispositivo; sin colaboración.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E10.1 | Backend API + auth | P1 | Login; sync proyectos |
| E10.2 | Roles (vendedor, técnico, admin) | P2 | Permisos por proyecto |
| E10.3 | Resolución de conflictos offline | P2 | Last-write-wins o merge manual |

### Épica E11: Diseño eléctrico
**Problema:** Sin strings ni diagramas; no sirve para permisos.

| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E11.1 | Stringing automático | P1 | Strings por inversor; validación Voc/Isc |
| E11.2 | Diagrama unifilar PDF | P1 | Export estándar simplificado |
| E11.3 | Optimizadores / microinversores | P2 | Modo por panel; yield vs string |

---

## Fase 4 — Ecosistema energético

### Épica E12: Post-venta e instalación
| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E12.1 | Checklists de instalación | P2 | Templates; fotos por ítem |
| E12.2 | Calendario de obra | P3 | Fecha instalación; asignación técnico |
| E12.3 | Handover document pack | P3 | PDF final: garantías, manual, monitoreo |

### Épica E13: Productos adicionales
| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E13.1 | Wallbox / EV charging en BOM | P3 | Catálogo + cotización |
| E13.2 | Heat pump básico | P3 | Consumo térmico + integración propuesta |

### Épica E14: Integraciones
| ID | Ticket | Prioridad | Criterios de aceptación |
|----|--------|-----------|-------------------------|
| E14.1 | WhatsApp Business share mejorado | P2 | Template mensaje + link propuesta |
| E14.2 | Webhook/API para CRM externo | P3 | Eventos: propuesta enviada, firmada |

---

## Matriz de prioridad global (top 10)

| Rank | Ticket | Fase | Por qué ahora |
|------|--------|------|---------------|
| 1 | E1.1 Persistencia local | 1 | Sin esto nada más importa en producción |
| 2 | E2.1 Geocoding + pin | 1 | Base para PVGIS y satélite |
| 3 | E3.1 Cliente PVGIS | 1 | Credibilidad del kWh/año |
| 4 | E4.2 Layout 2D en PDF | 1 | Cierra gap QA restante |
| 5 | E2.2 Vista satelital | 1 | Diferenciador vs "dibujar a mano" |
| 6 | E5.1 Variantes de propuesta | 2 | Cierra más ventas que features técnicas |
| 7 | E6.1 Link web propuesta | 2 | Flujo de aceptación moderno |
| 8 | E6.2 Firma digital | 2 | Convierte propuesta en contrato |
| 9 | E8.1 Catálogo instalador | 2 | Cada cliente B2B lo pide |
| 10 | E11.1 Stringing | 3 | Credibilidad técnica pro |

---

## Métricas de éxito por fase

| Fase | KPI |
|------|-----|
| 1 | Tiempo medición→propuesta < 10 min; error producción vs PVGIS < 5% |
| 2 | Tasa conversión propuesta→firma medible; 2+ variantes por proyecto |
| 3 | 2+ usuarios por cuenta; 80% proyectos con estado actualizado |
| 4 | 1+ producto adicional (EV/batería) en 30% de propuestas |

---

## Issues en GitHub

Issues creados en el repositorio (ver [#3–#33](https://github.com/RamiroS1/solar-scan/issues)):

| Épica | Issue | Tickets clave |
|-------|-------|---------------|
| E1 Persistencia | [#3](https://github.com/RamiroS1/solar-scan/issues/3) | [#7](https://github.com/RamiroS1/solar-scan/issues/7) |
| E2 Medición sitio real | [#4](https://github.com/RamiroS1/solar-scan/issues/4) | [#8](https://github.com/RamiroS1/solar-scan/issues/8), [#11](https://github.com/RamiroS1/solar-scan/issues/11) |
| E3 PVGIS | [#5](https://github.com/RamiroS1/solar-scan/issues/5) | [#9](https://github.com/RamiroS1/solar-scan/issues/9) |
| E4 Diseño técnico | [#6](https://github.com/RamiroS1/solar-scan/issues/6) | [#10](https://github.com/RamiroS1/solar-scan/issues/10), [#12](https://github.com/RamiroS1/solar-scan/issues/12) |
| E5 Variantes | [#13](https://github.com/RamiroS1/solar-scan/issues/13) | [#17](https://github.com/RamiroS1/solar-scan/issues/17) |
| E6 Firma digital | [#14](https://github.com/RamiroS1/solar-scan/issues/14) | [#18](https://github.com/RamiroS1/solar-scan/issues/18), [#19](https://github.com/RamiroS1/solar-scan/issues/19) |
| E7 Financiamiento | [#15](https://github.com/RamiroS1/solar-scan/issues/15) | [#20](https://github.com/RamiroS1/solar-scan/issues/20) |
| E8 Catálogo | [#16](https://github.com/RamiroS1/solar-scan/issues/16) | [#21](https://github.com/RamiroS1/solar-scan/issues/21) |
| E9 CRM | [#22](https://github.com/RamiroS1/solar-scan/issues/22) | [#25](https://github.com/RamiroS1/solar-scan/issues/25) |
| E10 Cloud | [#23](https://github.com/RamiroS1/solar-scan/issues/23) | [#26](https://github.com/RamiroS1/solar-scan/issues/26) |
| E11 Stringing | [#24](https://github.com/RamiroS1/solar-scan/issues/24) | [#27](https://github.com/RamiroS1/solar-scan/issues/27), [#28](https://github.com/RamiroS1/solar-scan/issues/28) |
| E12 Post-venta | [#29](https://github.com/RamiroS1/solar-scan/issues/29) | [#31](https://github.com/RamiroS1/solar-scan/issues/31) |
| E13 Ecosistema | [#30](https://github.com/RamiroS1/solar-scan/issues/30) | [#32](https://github.com/RamiroS1/solar-scan/issues/32) |

Setup de labels/milestones: [GITHUB_SETUP.md](./GITHUB_SETUP.md)
