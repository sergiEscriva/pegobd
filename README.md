# PegOBD

Aplicación móvil Flutter para diagnóstico de vehículos en tiempo real mediante el protocolo OBD-II a través de adaptadores ELM327 vía Bluetooth.

## Características

- **Conexión Bluetooth** — Descubrimiento, emparejado y gestión de adaptadores ELM327
- **Lectura OBD-II** — 9 sensores principales: RPM, temperatura de refrigerante, carga del motor, presión de combustible, posición del acelerador, MAF, temperatura de admisión, sensores de oxígeno
- **Dashboard en tiempo real** — Gauges y gráficas con histórico de tendencias
- **Modo simulador** — Desarrollo y pruebas sin hardware físico
- **Sistema de logging** — Logs persistentes con 5 niveles de severidad y rotación automática a 5 MB
- **Gestión de temas** — Claro, oscuro y automático con persistencia
- **Reconexión automática** — Backoff exponencial con hasta 5 intentos

## Stack Tecnológico

| Categoría | Tecnología |
|---|---|
| Framework | Flutter 3.7.2+ / Dart |
| Bluetooth | flutter_bluetooth_serial ^0.4.0 |
| Visualización | syncfusion_flutter_gauges ^27.1.48, syncfusion_flutter_charts ^27.1.48 |
| Almacenamiento | shared_preferences ^2.5.3 |
| Permisos | permission_handler ^12.0.0+1 |
| Archivos | path_provider ^2.1.1, share_plus ^7.2.1 |
| Build | Gradle 8+ con Kotlin DSL, NDK 27.0.12077973 |

## Arquitectura

Clean Architecture con organización por features:

```
lib/
├── features/
│   ├── bluetooth/       # Descubrimiento y emparejado
│   ├── dashboard/       # UI principal con sensores
│   ├── obd/             # Implementación del protocolo OBD-II
│   └── logging/         # Visor de logs
├── shared/
│   ├── services/        # ConnectionManager, BluetoothService (real/mock)
│   ├── widgets/         # Componentes reutilizables
│   └── models/          # Modelos de datos compartidos
├── core/
│   ├── theme/           # Design tokens y configuración de tema
│   └── utils/           # AppLogger, StorageHelper
└── main.dart
```

El servicio `BluetoothService` es una clase abstracta con dos implementaciones (`RealBluetoothService` y `MockBluetoothService`) que permite cambiar entre modo real y simulador sin modificar la UI.

## Requisitos

- Flutter 3.7.2+
- Android SDK 21+ (Android 5.0 Lollipop)
- Adaptador ELM327 Bluetooth (para modo real)
- Compilación: Android SDK 34, NDK 27.0.12077973

## Configuración y arranque

```bash
flutter pub get
flutter run
```

### Android — Permisos necesarios

El `AndroidManifest.xml` requiere:
- `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`

### Signing de Release

> **IMPORTANTE:** El build actual usa el keystore de debug para releases. Antes de publicar en tienda hay que configurar un keystore de producción en `android/app/build.gradle.kts`.

## Uso

### Modo Real (adaptador físico)
1. Conectar el adaptador ELM327 al puerto OBD-II del vehículo
2. Emparejar el dispositivo Bluetooth desde ajustes del sistema
3. Abrir la app y seleccionar el dispositivo en la pantalla Bluetooth
4. El dashboard mostrará los sensores en tiempo real

### Modo Simulador
Activar desde el menú principal para desarrollo y pruebas sin hardware.

## Protocolo OBD-II

La comunicación con el ELM327 sigue esta secuencia:

1. Inicialización: `ATZ` → `ATE0` → `ATL0` → `ATH0` → `ATSP0`
2. Polling de PIDs cada 2 segundos (Service 0x01)
3. Health check cada 10 segundos mediante comando `ATI`
4. Timeout por comando: 5 segundos

## Logging

Los logs se guardan en `app_errors.log` con rotación automática:
- **DEBUG** — Flujo detallado de ejecución
- **INFO** — Eventos de estado normal
- **WARNING** — Situaciones anómalas no críticas
- **ERROR** — Fallos recuperables
- **CRITICAL** — Fallos que requieren atención inmediata

El visor de logs está accesible desde el menú de la app.
