# FamilOS - Sistema Financiero Integrado

## Descripción
FamilOS es una aplicación de gestión financiera familiar para macOS que integra presupuestos y cuentas por pagar en un dashboard unificado.

## Características Principales

### Dashboard Integrado
- **Análisis en tiempo real**: Cruza automáticamente datos de presupuestos y cuentas
- **Alertas inteligentes**: Notificaciones cuando se exceden límites o hay vencimientos próximos
- **Visualización por categorías**: Muestra el estado de cada categoría financiera
- **Proyecciones**: Calcula gastos proyectados basado en cuentas pendientes

### Módulos Integrados

#### 1. Cuentas por Pagar
- Gestión de cuentas con categorización automática
- Estados: Pendiente, Pagada, Vencida
- Filtros y búsqueda avanzada
- Alertas de vencimiento

#### 2. Presupuestos
- Configuración de límites por categoría
- Seguimiento de aportes familiares
- Gestión de deudas y cuotas
- Transferencia de sobrantes entre meses

#### 3. Dashboard Financiero
- Resumen global de ingresos vs gastos
- Análisis por categoría con estados visuales
- Alertas contextuales y recomendaciones
- Gráficos de distribución de gastos

## Estructura de Integración

### Estados de Presupuesto por Categoría
- **En Rango** (< 70%): Verde ✅
- **Atención** (70-90%): Amarillo ⚠️
- **Cerca del Límite** (90-100%): Naranja 🔶
- **Excedido** (> 100%): Rojo ❌
- **Sin Presupuesto**: Gris ⚪

### Tipos de Alertas
- **Presupuesto Excedido**: Urgencia crítica
- **Cerca del Límite**: Urgencia alta
- **Proyección Excede**: Urgencia alta
- **Vencimiento Próximo**: Urgencia media
- **Sin Presupuesto**: Urgencia baja

## Uso de la Aplicación

### Navegación Principal
1. **Dashboard**: Vista principal con análisis integrado
2. **Cuentas**: Gestión detallada de cuentas por pagar
3. **Presupuesto**: Configuración de aportes y límites
4. **Historial**: Análisis de tendencias (por implementar)
5. **Configuración**: Ajustes de usuario

### Flujo de Trabajo Recomendado
1. Configurar categorías y presupuestos mensuales
2. Registrar cuentas por pagar con sus categorías
3. Revisar el dashboard para análisis integrado
4. Configurar alertas y ajustar presupuestos según necesidad
5. Marcar cuentas como pagadas para actualizar el seguimiento

### Configuración de Presupuestos
- Accede a "Configuración de Presupuesto" desde el dashboard
- Define límites mensuales por categoría
- El sistema sugiere presupuestos basado en historial
- Guarda cambios para ver análisis actualizado

## Tecnologías
- **SwiftUI**: Framework de UI
- **Combine**: Programación reactiva
- **Core Data**: Persistencia de datos (preparado)
- **Charts**: Visualizaciones gráficas

## Instalación y Ejecución
1. Abrir el proyecto en Xcode
2. Seleccionar destino macOS
3. Ejecutar con ⌘+R
4. Los datos de ejemplo se cargan automáticamente

## Próximas Funcionalidades
- Persistencia en Core Data
- Sincronización entre dispositivos
- Exportación de reportes
- Análisis predictivo
- Categorización automática con IA
