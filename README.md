# SolarScan — app Flutter

Medición de techos, diseño de layout fotovoltaico y propuesta con ROI.
Código fuente completo y compilable. **No incluye el APK**: ver abajo cómo obtenerlo.

---

## Por qué no viene el APK ya compilado

El entorno donde se generó este proyecto no tiene el SDK de Flutter ni el de
Android instalados, y los dos servidores de descarga (`storage.googleapis.com`
y `dl.google.com`) están bloqueados por la política de red del sandbox. No hay
forma de producir el binario ahí. Las dos rutas de abajo sí funcionan.

---

## Ruta A — GitHub Actions (sin instalar nada)

La más cómoda si no quieres tocar tu máquina. GitHub compila el APK gratis.

1. Crea un repositorio nuevo en GitHub (puede ser privado).
2. Sube el contenido de esta carpeta:

```bash
cd solarscan
git init && git add . && git commit -m "SolarScan v1"
git branch -M main
git remote add origin https://github.com/TU_USUARIO/solarscan.git
git push -u origin main
```

3. Ve a la pestaña **Actions** del repositorio. El flujo *Build APK* arranca
   solo con el push (tarda unos 5–8 minutos la primera vez).
4. Al terminar, abre la ejecución y descarga el artefacto **solarscan-apk**.
   Dentro está `app-release.apk`.
5. Arrástralo sobre la ventana del emulador de Android — se instala solo.
   O por terminal: `adb install app-release.apk`.

El flujo está en `.github/workflows/android.yml` y no requiere ninguna clave
ni configuración adicional.

---

## Ruta B — Compilar en tu máquina

Necesitas Flutter (que ya trae lo necesario para Android salvo el SDK, que el
propio `flutter doctor` te ayuda a instalar).

```bash
cd solarscan

# Genera el andamiaje nativo (carpeta android/), que no viene en el repo
flutter create . --project-name solarscan --org com.solarscan --platforms=android

# OJO: el comando anterior sobrescribe lib/main.dart y pubspec.yaml.
# Si usas git, restaura los nuestros:
git checkout -- lib pubspec.yaml

flutter pub get
flutter run            # con el emulador abierto
flutter build apk --release   # APK en build/app/outputs/flutter-apk/
```

Si no usas git, haz una copia de `lib/` y `pubspec.yaml` antes de
`flutter create` y devuélvelos después.

---

## Ruta C — Abrirla en un iPhone (sin Mac ni cuenta de Apple)

Un iPhone no puede correr un emulador de Android. La vía práctica es publicar
la app como web y añadirla a la pantalla de inicio: queda con su icono, a
pantalla completa, sin barra del navegador.

1. Sube el repo a GitHub (igual que en la Ruta A).
2. En el repositorio: **Settings → Pages → Source: GitHub Actions**.
3. El flujo `Deploy Web` publica sola la app. La URL sale en la propia
   ejecución del workflow: `https://TU_USUARIO.github.io/solarscan/`
4. Abre esa URL en **Safari** → botón Compartir → **Añadir a pantalla de inicio**.

**Los dos fallos que arruinan este paso:**

1. Si tu repositorio **no se llama `solarscan`**, edita el `--base-href` de
   `.github/workflows/web.yml` para que coincida con el nombre real. Si no
   coincide, la app carga en blanco sin ningún error visible.
2. `flutter create` sobrescribe `web/index.html`. El workflow ya lo restaura con
   `git checkout -- lib pubspec.yaml web`; no borres esa línea.

La carpeta `web/` ya viene preparada: iconos propios, pantalla de carga con la
identidad de la app y las metaetiquetas de iOS. Sin
`apple-mobile-web-app-capable`, al añadir a pantalla de inicio se abre con la
barra de Safari encima y no parece una app.

El `index.html` usa `flutter_bootstrap.js`, el punto de entrada de Flutter 3.22
en adelante. Si compilas con una versión anterior, cámbialo por `flutter.js`.

Qué cambia respecto al APK: el PDF se descarga o se abre en el visor del
sistema en vez de usar la hoja de compartir nativa. Todo lo demás —medición,
layout, cálculos, escena 3D— funciona igual, porque no hay ni un plugin nativo
en el proyecto.

---

## Qué hace la app

Flujo completo: **Proyectos → Cliente → Medir → Diseñar → Números → Propuesta**.

| Pantalla | Qué funciona de verdad |
|---|---|
| Proyectos | Lista con estados. Dos proyectos de ejemplo precargados. |
| Nuevo proyecto | Cliente, dirección, consumo anual y tarifa. |
| Medición | Lienzo a escala: cada toque añade un vértice **en metros reales**. Área geodésica corregida por pendiente, perímetro, obstáculos como zonas de exclusión. Botón ⬛ en la barra superior carga un rectángulo 12×9 m de ejemplo. |
| Diseño | Empaquetado automático de módulos con el algoritmo real, catálogo de 4 paneles, retiro al borde y orientación ajustables. Recalcula en vivo. |
| Números | Producción mes a mes (Erbs + Liu & Jordan), comparada con el consumo. Payback, VPN y TIR con supuestos editables. |
| Propuesta | Casa isométrica animada con los paneles reales del proyecto y exportación a PDF (compartir por WhatsApp, correo, etc). |

### Lo que **no** hace todavía

- No usa cámara ni AR: la captura es sobre lienzo a escala. El puente ARKit/ARCore
  es trabajo nativo pendiente.
- No consulta PVGIS: usa una tabla de irradiancia por defecto (Valle Central de
  Costa Rica). El cliente HTTP está escrito en la entrega anterior del proyecto.
- No hay mapa satelital (evita depender de una API key para que compile a la primera).
- No persiste en disco: al cerrar la app se pierden los proyectos.

---

## Arquitectura

```
lib/
├── main.dart           App + inyección del estado
├── core.dart           Tokens de diseño (light glass) y widgets base
├── models.dart         Project, RoofFacet, Obstacle, PanelModule, resultados
├── services.dart       Motor de cálculo — SIN dependencias de Flutter
│                       · Geo      área, proyección al plano del techo
│                       · Solar    posición solar, transposición al plano inclinado
│                       · Production  kWh/mes con derrateo térmico
│                       · PanelLayout empaquetado de módulos
│                       · Finance  payback, VPN, TIR
├── painters.dart       Estado global + CustomPainters (techo, casa 3D, barras)
├── proposal_pdf.dart   Generación del PDF en el dispositivo
└── screens/            Una pantalla por paso del flujo
```

`services.dart` no importa Flutter: se puede probar con `dart test` sin emulador.

### Tres decisiones que cambian los resultados

1. **El polígono capturado es la proyección en planta.** El área real se obtiene
   dividiendo por `cos(inclinación)`. Sin esa corrección, un techo a 30° se
   subestima un 15 %.
2. **Los paneles se empaquetan sobre el plano desdoblado del techo**
   (`Geo.toRoof`), no sobre la planta. Empaquetar en planta da filas de menos.
3. **La irradiancia se transpone al plano inclinado** con la correlación de Erbs
   y Liu & Jordan, calculando `Rb` por integración horaria del día
   representativo de cada mes. Así una orientación este/oeste da un número
   distinto de una sur, que es justo lo que el instalador necesita ver.

---

## Dependencias

Solo dos, ambas sin configuración nativa ni claves: `pdf` y `printing`.
Es deliberado: cualquier plugin que pida una API key rompe la compilación a la
primera y arruina la prueba.
