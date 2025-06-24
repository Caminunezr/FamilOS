import Foundation
import SwiftUI
import Combine

class CuentasViewModel: ObservableObject {
    @Published var cuentas: [Cuenta] = []
    @Published var filtroCategorias: Set<String> = []
    @Published var filtroEstado: Cuenta.EstadoCuenta? = nil
    @Published var filtroFechaDesde: Date? = nil
    @Published var filtroFechaHasta: Date? = nil
    @Published var busquedaTexto: String = ""
    
    // Dashboard por períodos mensuales
    @Published var mesSeleccionado: Date = Date()
    @Published var vistaDashboard: VistaDashboard = .mensual
    
    // Organización temporal
    @Published var añoSeleccionado: Int? = nil
    @Published var vistaOrganizacion: VistaOrganizacion = .porAño
    @Published var filtroEstadoOrganizacion: FiltroEstadoOrganizacion = .todas
    
    enum VistaOrganizacion: String, CaseIterable {
        case porAño = "Por Año"
        
        var icono: String {
            return "calendar.circle.fill"
        }
    }
    
    enum FiltroEstadoOrganizacion: String, CaseIterable {
        case todas = "Todas"
        case pendientes = "Pendientes"
        case pagadas = "Pagadas"
        case vencidas = "Vencidas"
        
        var icono: String {
            switch self {
            case .todas: return "circle.grid.3x3"
            case .pendientes: return "clock"
            case .pagadas: return "checkmark.circle"
            case .vencidas: return "exclamationmark.triangle"
            }
        }
        
        var estadoCuenta: Cuenta.EstadoCuenta? {
            switch self {
            case .todas: return nil
            case .pendientes: return .pendiente
            case .pagadas: return .pagada
            case .vencidas: return .vencida
            }
        }
    }
    
    enum VistaDashboard: String, CaseIterable {
        case mensual = "Mensual"
        case trimestral = "Trimestral"
        case anual = "Anual"
        
        var icono: String {
            switch self {
            case .mensual: return "calendar"
            case .trimestral: return "calendar.badge.clock"
            case .anual: return "calendar.circle"
            }
        }
    }
    
    // MARK: - Datos de ejemplo mejorados
    func cargarDatosEjemplo() {
        let ahora = Date()
        let calendario = Calendar.current
        
        cuentas = []
        
        // Generar cuentas para los últimos 3 meses
        for mesOffset in -2...1 {
            guard let mesBase = calendario.date(byAdding: .month, value: mesOffset, to: ahora) else { continue }
            
            // CFE (Luz)
            let cfe = Cuenta(
                monto: Double.random(in: 800...1200),
                proveedor: "CFE",
                fechaVencimiento: calendario.date(byAdding: .day, value: 15, to: mesBase)!,
                categoria: Cuenta.CategoriasCuentas.luz.rawValue,
                creador: "Usuario",
                fechaEmision: calendario.date(byAdding: .day, value: 1, to: mesBase),
                descripcion: "Consumo eléctrico del hogar",
                fechaPago: mesOffset < 0 ? calendario.date(byAdding: .day, value: 12, to: mesBase) : nil
            )
            cuentas.append(cfe)
            
            // Totalplay (Internet)
            let internet = Cuenta(
                monto: 599.0,
                proveedor: "Totalplay",
                fechaVencimiento: calendario.date(byAdding: .day, value: 5, to: mesBase)!,
                categoria: Cuenta.CategoriasCuentas.internet.rawValue,
                creador: "Usuario",
                descripcion: "Internet fibra óptica 200MB",
                fechaPago: mesOffset < 0 ? calendario.date(byAdding: .day, value: 3, to: mesBase) : nil
            )
            cuentas.append(internet)
            
            // Conagua (Agua)
            let agua = Cuenta(
                monto: Double.random(in: 200...400),
                proveedor: "Conagua",
                fechaVencimiento: calendario.date(byAdding: .day, value: 20, to: mesBase)!,
                categoria: Cuenta.CategoriasCuentas.agua.rawValue,
                creador: "Usuario",
                descripcion: "Servicio de agua potable",
                fechaPago: mesOffset < 0 ? calendario.date(byAdding: .day, value: 18, to: mesBase) : nil
            )
            cuentas.append(agua)
            
            // Naturgy (Gas)
            let gas = Cuenta(
                monto: Double.random(in: 300...600),
                proveedor: "Naturgy",
                fechaVencimiento: calendario.date(byAdding: .day, value: 10, to: mesBase)!,
                categoria: Cuenta.CategoriasCuentas.gas.rawValue,
                creador: "Usuario",
                descripcion: "Gas natural",
                fechaPago: mesOffset < 0 ? calendario.date(byAdding: .day, value: 8, to: mesBase) : nil
            )
            cuentas.append(gas)
            
            // Arriendo (solo si es mes actual o anterior)
            if mesOffset >= -1 {
                let arriendo = Cuenta(
                    monto: 8500.0,
                    proveedor: "Propietario",
                    fechaVencimiento: calendario.date(byAdding: .day, value: 1, to: mesBase)!,
                    categoria: Cuenta.CategoriasCuentas.arriendo.rawValue,
                    creador: "Usuario",
                    descripcion: "Renta mensual del departamento",
                    fechaPago: mesOffset < 0 ? calendario.date(byAdding: .day, value: 1, to: mesBase) : nil
                )
                cuentas.append(arriendo)
            }
        }
    }
    
    // MARK: - Computed Properties para Dashboard
    
    // Cuentas del mes seleccionado
    var cuentasDelMes: [Cuenta] {
        let calendar = Calendar.current
        return cuentas.filter { cuenta in
            calendar.isDate(cuenta.fechaVencimiento, equalTo: mesSeleccionado, toGranularity: .month)
        }
    }
    
    // Resumen financiero del mes
    var resumenMensual: ResumenFinanciero {
        let cuentasMes = cuentasDelMes
        
        return ResumenFinanciero(
            totalCuentas: cuentasMes.count,
            totalMonto: cuentasMes.reduce(0) { $0 + $1.monto },
            pagadas: cuentasMes.filter { $0.estado == .pagada }.count,
            pendientes: cuentasMes.filter { $0.estado == .pendiente }.count,
            vencidas: cuentasMes.filter { $0.estado == .vencida }.count,
            montoPagado: cuentasMes.filter { $0.estado == .pagada }.reduce(0) { $0 + $1.monto },
            montoPendiente: cuentasMes.filter { $0.estado == .pendiente }.reduce(0) { $0 + $1.monto },
            montoVencido: cuentasMes.filter { $0.estado == .vencida }.reduce(0) { $0 + $1.monto }
        )
    }
    
    // Cuentas próximas a vencer (próximos 7 días)
    var cuentasProximasVencer: [Cuenta] {
        let calendar = Calendar.current
        let hoy = Date()
        let en7Dias = calendar.date(byAdding: .day, value: 7, to: hoy)!
        
        return cuentas.filter { cuenta in
            cuenta.estado == .pendiente &&
            cuenta.fechaVencimiento >= hoy &&
            cuenta.fechaVencimiento <= en7Dias
        }.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
    }
    
    // Análisis por categorías
    var gastosPorCategoria: [GastoCategoria] {
        let cuentasMes = cuentasDelMes
        let grouped = Dictionary(grouping: cuentasMes) { $0.categoria }
        
        return grouped.map { categoria, cuentas in
            GastoCategoria(
                categoria: categoria,
                total: cuentas.reduce(0) { $0 + $1.monto },
                cuentas: cuentas.count,
                pagadas: cuentas.filter { $0.estado == .pagada }.count
            )
        }.sorted { $0.total > $1.total }
    }
    
    // MARK: - Propiedades computadas adicionales
    var cuentasMesActual: [Cuenta] {
        let calendar = Calendar.current
        return cuentas.filter { cuenta in
            calendar.isDate(cuenta.fechaVencimiento, equalTo: mesSeleccionado, toGranularity: .month)
        }
    }
    
    // MARK: - Análisis por categoría
    struct AnalisisCategoria {
        let categoria: String
        let total: Double
        let cantidad: Int
        let porcentaje: Double
    }
    
    var analisisPorCategoria: [AnalisisCategoria] {
        let cuentasMes = cuentasMesActual
        let totalMonto = cuentasMes.reduce(0) { $0 + $1.monto }
        
        let grouped = Dictionary(grouping: cuentasMes, by: { $0.categoria })
        
        return grouped.map { categoria, cuentas in
            let total = cuentas.reduce(0) { $0 + $1.monto }
            let porcentaje = totalMonto > 0 ? (total / totalMonto) * 100 : 0
            
            return AnalisisCategoria(
                categoria: categoria,
                total: total,
                cantidad: cuentas.count,
                porcentaje: porcentaje
            )
        }.sorted { $0.total > $1.total }
    }
    
    // MARK: - Top proveedores
    struct AnalisisProveedor {
        let proveedor: String
        let total: Double
        let cantidad: Int
    }
    
    var topProveedores: [AnalisisProveedor] {
        let cuentasMes = cuentasMesActual
        let grouped = Dictionary(grouping: cuentasMes, by: { $0.proveedor })
        
        return grouped.map { proveedor, cuentas in
            let total = cuentas.reduce(0) { $0 + $1.monto }
            
            return AnalisisProveedor(
                proveedor: proveedor,
                total: total,
                cantidad: cuentas.count
            )
        }.sorted { $0.total > $1.total }
    }
    
    struct ResumenFinanciero {
        let totalCuentas: Int
        let totalMonto: Double
        let pagadas: Int
        let pendientes: Int
        let vencidas: Int
        let montoPagado: Double
        let montoPendiente: Double
        let montoVencido: Double
        
        var porcentajePagado: Double {
            totalMonto > 0 ? (montoPagado / totalMonto) * 100 : 0
        }
    }
    
    struct GastoCategoria: Identifiable {
        let id = UUID()
        let categoria: String
        let total: Double
        let cuentas: Int
        let pagadas: Int
        
        var icono: String {
            if let categoriaEnum = Cuenta.CategoriasCuentas(rawValue: categoria) {
                return categoriaEnum.icono
            }
            return "questionmark.circle"
        }
        
        var porcentajePagado: Double {
            cuentas > 0 ? (Double(pagadas) / Double(cuentas)) * 100 : 0
        }
    }
    
    // MARK: - Navegación temporal
    func irMesAnterior() {
        let calendar = Calendar.current
        if let nuevoMes = calendar.date(byAdding: .month, value: -1, to: mesSeleccionado) {
            mesSeleccionado = nuevoMes
        }
    }
    
    func irMesSiguiente() {
        let calendar = Calendar.current
        if let nuevoMes = calendar.date(byAdding: .month, value: 1, to: mesSeleccionado) {
            mesSeleccionado = nuevoMes
        }
    }
    
    func irMesActual() {
        mesSeleccionado = Date()
    }
    
    // MARK: - Filtros y búsqueda
    var cuentasFiltradas: [Cuenta] {
        return cuentas.filter { cuenta in
            // Filtro por categoría
            if !filtroCategorias.isEmpty && !filtroCategorias.contains(cuenta.categoria) {
                return false
            }
            
            // Filtro por estado
            if let estado = filtroEstado, cuenta.estado != estado {
                return false
            }
            
            // Filtro por fecha
            if let fechaDesde = filtroFechaDesde, cuenta.fechaVencimiento < fechaDesde {
                return false
            }
            
            if let fechaHasta = filtroFechaHasta, cuenta.fechaVencimiento > fechaHasta {
                return false
            }
            
            // Filtro por texto
            if !busquedaTexto.isEmpty {
                let textoBusqueda = busquedaTexto.lowercased()
                return cuenta.nombre.lowercased().contains(textoBusqueda) ||
                       cuenta.proveedor.lowercased().contains(textoBusqueda) ||
                       cuenta.categoria.lowercased().contains(textoBusqueda) ||
                       cuenta.descripcion.lowercased().contains(textoBusqueda)
            }
            
            return true
        }
    }
    
    // Obtener categorías disponibles
    var categoriasDisponibles: [String] {
        return Cuenta.CategoriasCuentas.allCases.map { $0.rawValue }
    }
    
    // MARK: - Operaciones CRUD
    func agregarCuenta(_ cuenta: Cuenta) {
        cuentas.append(cuenta)
        // Aquí se implementaría la persistencia real
    }
    
    func actualizarCuenta(_ cuenta: Cuenta) {
        if let index = cuentas.firstIndex(where: { $0.id == cuenta.id }) {
            cuentas[index] = cuenta
            // Aquí se implementaría la persistencia real
        }
    }
    
    func eliminarCuenta(id: UUID) {
        cuentas.removeAll { $0.id == id }
        // Aquí se implementaría la persistencia real
    }
    
    func marcarComoPagada(_ cuenta: Cuenta, fechaPago: Date = Date(), montoPagado: Double? = nil) {
        if let index = cuentas.firstIndex(where: { $0.id == cuenta.id }) {
            cuentas[index].fechaPago = fechaPago
            cuentas[index].montoPagado = montoPagado ?? cuenta.monto
            cuentas[index].estado = .pagada
        }
    }
    
    // MARK: - Gestión de Pagos
    func registrarPago(cuenta: Cuenta, monto: Double, fecha: Date, notas: String, tieneComprobante: Bool) {
        if let index = cuentas.firstIndex(where: { $0.id == cuenta.id }) {
            cuentas[index].estado = .pagada
            cuentas[index].montoPagado = monto
            cuentas[index].fechaPago = fecha
            cuentas[index].descripcion = notas.isEmpty ? cuentas[index].descripcion : "\(cuentas[index].descripcion)\n\nNotas de pago: \(notas)"
            
            if tieneComprobante {
                // Simular URL de comprobante
                cuentas[index].comprobanteURL = URL(string: "file://comprobante_\(cuenta.id)")
            }
        }
    }
    
    // MARK: - Operaciones CRUD Avanzadas
    func duplicarCuenta(_ cuenta: Cuenta) {
        let calendario = Calendar.current
        let nuevaFechaVencimiento = calendario.date(byAdding: .month, value: 1, to: cuenta.fechaVencimiento) ?? cuenta.fechaVencimiento
        
        let cuentaDuplicada = Cuenta(
            monto: cuenta.monto,
            proveedor: cuenta.proveedor,
            fechaVencimiento: nuevaFechaVencimiento,
            categoria: cuenta.categoria,
            creador: cuenta.creador,
            fechaEmision: calendario.date(byAdding: .month, value: 1, to: cuenta.fechaEmision ?? Date()),
            descripcion: cuenta.descripcion,
            nombre: "\(cuenta.nombre) (Copia)"
        )
        
        cuentas.append(cuentaDuplicada)
    }
    
    func eliminarCuenta(_ cuenta: Cuenta) {
        cuentas.removeAll { $0.id == cuenta.id }
    }
    
    func actualizarCuenta(
        _ cuenta: Cuenta,
        monto: Double,
        proveedor: String,
        fechaVencimiento: Date,
        categoria: String,
        descripcion: String,
        nombre: String,
        fechaEmision: Date?
    ) {
        if let index = cuentas.firstIndex(where: { $0.id == cuenta.id }) {
            cuentas[index].monto = monto
            cuentas[index].proveedor = proveedor
            cuentas[index].fechaVencimiento = fechaVencimiento
            cuentas[index].categoria = categoria
            cuentas[index].descripcion = descripcion
            cuentas[index].nombre = nombre
            cuentas[index].fechaEmision = fechaEmision
        }
    }
    
    // MARK: - Organización Temporal
    
    // Años disponibles en las cuentas
    var añosDisponibles: [Int] {
        let años = Set(cuentas.compactMap { cuenta in
            Calendar.current.component(.year, from: cuenta.fechaVencimiento)
        })
        return años.sorted(by: >)
    }
    
    // Cuentas organizadas por año
    var cuentasPorAño: [AñoCuentas] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: cuentas) { cuenta in
            calendar.component(.year, from: cuenta.fechaVencimiento)
        }
        
        return grouped.map { año, cuentas in
            AñoCuentas(año: año, cuentas: cuentas.sorted { $0.fechaVencimiento < $1.fechaVencimiento })
        }.sorted { $0.año > $1.año }
    }
    
    // Cuentas organizadas por año y mes
    var cuentasPorAñoYMes: [AñoCuentas] {
        let calendar = Calendar.current
        
        return cuentasPorAño.map { añoCuentas in
            let mesesGrouped = Dictionary(grouping: añoCuentas.cuentas) { cuenta in
                calendar.component(.month, from: cuenta.fechaVencimiento)
            }
            
            let mesesCuentas = mesesGrouped.map { mes, cuentas in
                MesCuentas(
                    mes: mes,
                    nombreMes: DateFormatter().monthSymbols[mes - 1],
                    cuentas: cuentas.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
                )
            }.sorted { $0.mes > $1.mes }
            
            return AñoCuentas(año: añoCuentas.año, cuentas: añoCuentas.cuentas, meses: mesesCuentas)
        }
    }
    
    // Cuentas organizadas por año y mes con filtro de estado
    var cuentasPorAñoYMesFiltradas: [AñoCuentas] {
        let cuentasAFiltrar: [Cuenta]
        
        // Aplicar filtro por estado si está seleccionado
        if let estado = filtroEstadoOrganizacion.estadoCuenta {
            cuentasAFiltrar = cuentas.filter { $0.estado == estado }
        } else {
            cuentasAFiltrar = cuentas
        }
        
        return agruparCuentasPorAñoYMes(cuentasAFiltrar)
    }
    
    // Función auxiliar para agrupar cuentas filtradas
    private func agruparCuentasPorAñoYMes(_ cuentasFiltradas: [Cuenta]) -> [AñoCuentas] {
        let calendar = Calendar.current
        let cuentasAgrupadas = Dictionary(grouping: cuentasFiltradas) { cuenta in
            calendar.component(.year, from: cuenta.fechaVencimiento)
        }
        
        return cuentasAgrupadas.map { año, cuentasDelAño in
            let mesesAgrupados = Dictionary(grouping: cuentasDelAño) { cuenta in
                calendar.component(.month, from: cuenta.fechaVencimiento)
            }
            
            let meses = mesesAgrupados.map { mes, cuentasDelMes in
                MesCuentas(
                    mes: mes,
                    nombreMes: DateFormatter().monthSymbols[mes - 1],
                    cuentas: cuentasDelMes.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
                )
            }.sorted { $0.mes < $1.mes }
            
            return AñoCuentas(
                año: año,
                cuentas: cuentasDelAño.sorted { $0.fechaVencimiento < $1.fechaVencimiento },
                meses: meses
            )
        }.sorted { $0.año > $1.año }
    }
    
    // Cuentas del año seleccionado
    var cuentasDelAñoSeleccionado: [Cuenta] {
        guard let año = añoSeleccionado else { return [] }
        let calendar = Calendar.current
        return cuentas.filter { cuenta in
            calendar.component(.year, from: cuenta.fechaVencimiento) == año
        }.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
    }
    
    // MARK: - Métodos de filtro
    func limpiarFiltros() {
        filtroCategorias.removeAll()
        filtroEstado = nil
        filtroFechaDesde = nil
        filtroFechaHasta = nil
        busquedaTexto = ""
        filtroEstadoOrganizacion = .todas
    }
}

// MARK: - Estructuras auxiliares para organización temporal

struct AñoCuentas: Identifiable {
    let id = UUID()
    let año: Int
    let cuentas: [Cuenta]
    var meses: [MesCuentas] = []
    
    var totalMonto: Double {
        cuentas.reduce(0) { $0 + $1.monto }
    }
    
    var totalCuentas: Int {
        cuentas.count
    }
    
    var cuentasPagadas: Int {
        cuentas.filter { $0.estado == .pagada }.count
    }
    
    var cuentasPendientes: Int {
        cuentas.filter { $0.estado == .pendiente }.count
    }
}

struct MesCuentas: Identifiable {
    let id = UUID()
    let mes: Int
    let nombreMes: String
    let cuentas: [Cuenta]
    
    var totalMonto: Double {
        cuentas.reduce(0) { $0 + $1.monto }
    }
    
    var totalCuentas: Int {
        cuentas.count
    }
    
    var cuentasPagadas: Int {
        cuentas.filter { $0.estado == .pagada }.count
    }
    
    var cuentasPendientes: Int {
        cuentas.filter { $0.estado == .pendiente }.count
    }
}