# Proceso de desarrollo — SolarScan

Documento formal de workflow para priorizar, ejecutar y entregar trabajo en SolarScan.

## 1. Objetivo del producto

SolarScan es la app más rápida para **medir, cotizar y cerrar** un sistema fotovoltaico en campo, evolucionando hacia una plataforma operativa para instaladores (estilo Reonic, pero liviana y offline-first).

## 2. Estructura del backlog

| Nivel | GitHub | Propósito |
|-------|--------|-----------|
| **Fase** | Milestone | Horizonte de entrega (Fase 1–4) |
| **Épica** | Issue con label `epic` | Capability de negocio completa |
| **Historia / Ticket** | Issue estándar | Entregable implementable en 1–5 días |
| **Tarea técnica** | Checklist dentro del issue | Subpasos de implementación |

## 3. Flujo de estados

```
Backlog → Ready → In Progress → In Review → Done
```

| Estado | Criterio |
|--------|----------|
| **Backlog** | Idea registrada, sin owner ni estimación |
| **Ready** | Criterios de aceptación claros, dependencias resueltas, prioridad asignada |
| **In Progress** | Branch `cursor/<slug>-4560` o `feat/<slug>` abierto |
| **In Review** | PR abierto, CI verde, demo/screenshot si aplica |
| **Done** | Merge a `main`, issue cerrado, docs actualizadas si cambió comportamiento |

## 4. Convenciones

### Commits (Conventional Commits)

```
feat: ...
fix: ...
chore: ...
docs: ...
refactor: ...
test: ...
```

Referenciar issue: `feat: add PVGIS client (#12)`

### Pull Requests

- Título claro en imperativo
- Descripción: qué, por qué, cómo probar
- Enlazar issue: `Closes #12`
- Draft hasta que pase CI y tenga criterios de aceptación cubiertos

### Definición de Done (DoD)

Un ticket está **Done** cuando:

1. Código mergeado en `main`
2. Criterios de aceptación verificados
3. Sin regresiones obvias en flujo principal (Proyecto → Medición → Diseño → Números → Propuesta)
4. Tests agregados si toca lógica de dominio (`lib/domain/`)
5. README o docs actualizados si cambia comportamiento visible

## 5. Priorización

Matriz usada para ordenar el backlog:

```
Impacto comercial / confianza del cliente
        ▲
        │  P0 — Bloquea venta o credibilidad
        │  P1 — Diferenciador vs competencia
        │  P2 — Mejora operativa
        │  P3 — Nice to have
        └──────────────────────────────► Esfuerzo
```

## 6. Arquitectura (recordatorio)

Nuevas features deben respetar la capa de dominio:

```
lib/
  catalog/     Equipos extensibles
  domain/      Lógica pura (sin Flutter)
  widgets/     UI reutilizable
  screens/     Flujo por pantalla
```

Regla: **toda lógica de negocio nueva va en `domain/`**, no en widgets ni screens.

## 7. Ceremonias mínimas

| Ceremonia | Frecuencia | Output |
|-----------|------------|--------|
| Refinamiento de backlog | Semanal | Issues movidos a Ready |
| Demo de fase | Al cerrar milestone | Video o screenshots en PR |
| Retrospectiva | Al cerrar fase | Ajustes en PROCESS.md o prioridades |

## 8. Referencias

- Backlog maestro: [PRODUCT_BACKLOG.md](./PRODUCT_BACKLOG.md)
- Comparativa competitiva: ver discusión Reonic vs SolarScan en PRs/issues
- Arquitectura actual: [README.md](../README.md)
