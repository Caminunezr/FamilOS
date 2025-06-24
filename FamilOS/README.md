# FamilOS 💰

**Sistema Avanzado de Gestión Financiera Familiar - Aplicación Nativa para macOS**

FamilOS es la evolución nativa para macOS de Familion, una aplicación integral de gestión financiera familiar desarrollada originalmente con React + Django. Esta versión nativa conserva todas las funcionalidades del sistema original pero implementadas con tecnologías de Apple para una experiencia optimizada en Mac.

## 🚀 Instalación

1. Descarga la app desde la sección [Releases](releases) o compílala desde Xcode.
2. Ejecuta el archivo `.app` en tu Mac.
3. ¡Listo para usar, sin dependencias externas!

## 🌟 Funcionalidades Principales

### 💳 Gestión Inteligente de Cuentas
- **Dashboard principal** con vista de cuentas por períodos mensuales
- **Sistema de categorías**: Luz, Agua, Gas, Internet, Arriendo, Gasto Común, Seguros, Otros
- **Gestión de proveedores** organizados por categoría (Enel, Aguas Andinas, Lipigas, Mundo, etc.)
- **Estados dinámicos**: Pagadas, pendientes, vencidas con códigos de color
- **Creación de cuentas** con formulario completo y validaciones
- **Gestión de archivos**: Subida y visualización de facturas/comprobantes (PDF, imágenes)
- **Detalles expandidos**: Modal con información completa de cada cuenta
- **Sistema de pagos**: Registro de pagos con comprobantes y fechas

### 📊 Sistema de Presupuestos Avanzado
- **Dashboard de presupuesto** con múltiples pestañas de análisis
- **Resumen financiero**: Ingresos, gastos, saldo disponible y ahorros
- **Gráficos interactivos**:
  - Gastos por categoría (gráfico de barras)
  - Evolución mensual de gastos (gráfico de líneas)
  - Distribución de gastos por proveedor
- **Análisis comparativo** entre períodos
- **Gestión de ahorros** con transferencias entre meses
- **Control de presupuesto** con límites y alertas

### 📈 Análisis e Historial Avanzado
- **Módulo de historial** con búsqueda y filtros avanzados
- **Filtros por**:
  - Rango de fechas personalizable
  - Categorías específicas
  - Estados de pago
  - Proveedores
- **Exportación de datos** a CSV con filtros aplicados
- **Estadísticas detalladas** por período
- **Comparativas históricas** entre diferentes meses/años

### 🎨 Experiencia de Usuario
- **Modo nocturno/diurno** con toggle automático
- **Diseño responsivo** adaptado a diferentes tamaños de pantalla
- **Navegación intuitiva** con breadcrumbs y menús contextuales
- **Animaciones suaves** en transiciones y carga de datos
- **Sistema de notificaciones** para acciones importantes
- **Visor de archivos integrado** para PDFs e imágenes

### 🔐 Sistema de Autenticación
- **Autenticación JWT** con tokens de acceso y refresh
- **Gestión de sesiones** con renovación automática
- **Protección de rutas** según nivel de acceso
- **Sistema de perfiles** con información personalizada
- **Logout seguro** con limpieza de tokens

### 🛡️ Panel de Administración (Básico)
- **Gestión de usuarios**: Crear, editar, activar/desactivar usuarios
- **Vista general de cuentas** del sistema
- **Gestión de proveedores** y categorías
- **Estadísticas del sistema** y métricas de uso
- **Acceso exclusivo** para usuarios administradores

### 🔧 Características Técnicas Implementadas
- **API RESTful** completa con Django REST Framework
- **Base de datos SQLite** con modelos relacionales
- **Sistema de archivos** para almacenamiento de documentos
- **Validaciones frontend y backend** robustas
- **Manejo de errores** completo con mensajes informativos
- **Optimización de rendimiento** con lazy loading y caching

## 🏗️ Arquitectura y Tecnologías

- **Lenguaje:** Swift 5, SwiftUI
- **Persistencia:** Core Data (equivalente a los modelos Django)
- **Gráficos:** Swift Charts (equivalente a Chart.js)
- **Autenticación:** Keychain Services para tokens seguros
- **UI/UX:** Diseño nativo macOS con modo oscuro
- **Exportación:** CSV, PDF nativo

## 📁 Estructura del Proyecto Nativo

```
FamilOS/
├── ContentView.swift           # Vista principal con navegación
├── FamilOSApp.swift           # Punto de entrada
├── Models/                    # Modelos (Cuenta, Presupuesto, Usuario, Proveedor)
├── ViewModels/               # Lógica de negocio 
├── Views/
│   ├── Auth/                 # Login, Signup
│   ├── Dashboard/            # Gestión de cuentas principal
│   ├── Presupuesto/         # Análisis y gráficos
│   ├── Historial/           # Búsqueda y filtros
│   └── Admin/               # Panel de administración
├── Services/                # Persistencia, exportación
├── Utils/                   # Helpers y extensiones
└── Assets.xcassets/         # Recursos gráficos
```

## 📊 Modelos de Datos Principales

```swift
struct Cuenta: Identifiable, Codable {
    var id: UUID
    var monto: Double
    var proveedor: String
    var categoria: String
    var fechaEmision: Date?
    var fechaVencimiento: Date
    var descripcion: String
    var facturaURL: URL?
    var comprobanteURL: URL?
    var creador: String
    var estado: EstadoCuenta
    var fechaPago: Date?
    var montoPagado: Double?
    
    enum EstadoCuenta: String, Codable, CaseIterable {
        case pagada = "Pagada"
        case pendiente = "Pendiente" 
        case vencida = "Vencida"
    }
}

struct Presupuesto: Identifiable, Codable {
    var id: UUID
    var mes: Int
    var año: Int
    var ingresos: Double
    var gastosFijos: Double
    var gastosVariables: Double
    var ahorros: Double
    var usuario: String
}

struct Proveedor: Identifiable, Codable {
    var id: UUID
    var nombre: String
    var categoria: String
    var icono: String?
}
```

## 🔐 Seguridad y Privacidad
- **Autenticación local** con Keychain Services
- **Datos cifrados** en Core Data
- **Tokens JWT** para comunicación segura (si se mantiene API)
- **Sandbox de macOS** para aislamiento de datos

## 🎯 Funcionalidades Específicas de macOS
- **Integración con Spotlight** para búsqueda de cuentas
- **Notificaciones nativas** para recordatorios de vencimiento
- **Drag & Drop** para subida de archivos
- **Quick Look** para previsualización de documentos
- **Shortcuts de teclado** para acciones rápidas

## 📱 Funcionalidades del Sistema Original Conservadas
- ✅ **Timeline de cuentas** con navegación por períodos
- ✅ **Formularios complejos** con validación en tiempo real
- ✅ **Sistema de archivos** completo para documentos
- ✅ **Gráficos estadísticos** interactivos
- ✅ **Filtros avanzados** por múltiples criterios
- ✅ **Exportación de datos** con filtros aplicados
- ✅ **Gestión de usuarios** y permisos
- ✅ **Modo nocturno** con persistencia de preferencias

## 🛠️ Extensibilidad
- Arquitectura MVVM para escalabilidad
- Protocolos Swift para funcionalidades modulares
- SwiftUI para interfaces reactivas y reutilizables

## 🧪 Testing
- Pruebas unitarias con XCTest
- Pruebas de UI automatizadas
- Pruebas de Core Data y persistencia

## 📄 Licencia

**MIT License** - Proyecto de código abierto basado en Familion

---

**¿Listo para llevar la gestión financiera familiar a tu Mac?**
FamilOS conserva toda la potencia de Familion con la fluidez nativa de macOS 🚀
