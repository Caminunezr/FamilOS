import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

class CuentasViewModel: ObservableObject {
    @Published var cuentas: [Cuenta] = []
    @Published var filtroCategorias: Set<String> = []
    @Published var filtroEstado: Cuenta.EstadoCuenta? = nil
    @Published var filtroFechaDesde: Date? = nil
    @Published var filtroFechaHasta: Date? = nil
    @Published var busquedaTexto: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Dashboard por períodos mensuales
    @Published var mesSeleccionado: Date = Date()
    @Published var vistaDashboard: VistaDashboard = .mensual
    
    // Organización temporal
    @Published var añoSeleccionado: Int? = nil
    @Published var vistaOrganizacion: VistaOrganizacion = .porAño
    @Published var filtroEstadoOrganizacion: FiltroEstadoOrganizacion = .todas
    
    private let firebaseService = FirebaseService()
    private var familiaId: String?
    private var observadorCuentasHandle: DatabaseHandle?

    // Método seguro para detener el observador que puede llamarse desde cualquier contexto
    private func detenerObservadorCuentas() {
        guard let familiaIdUnwrapped = familiaId,
              let handle = observadorCuentasHandle else { return }
        firebaseService.detenerObservadorCuentas(familiaId: familiaIdUnwrapped, handle: handle)
        observadorCuentasHandle = nil
    }

    // Método nonisolated que maneja correctamente la desuscripción en deinit
    nonisolated private func detenerObservadorCuentasSeguro() {
        // Captura los valores necesarios antes de la desuscripción
        // para evitar acceder a propiedades aisladas
        if let familiaId = self.familiaId, let handle = self.observadorCuentasHandle {
            FirebaseService().detenerObservadorCuentas(familiaId: familiaId, handle: handle)
            // No actualizamos observadorCuentasHandle a nil porque el objeto se está destruyendo de todas formas
        }
    }

    deinit {
        detenerObservadorCuentasSeguro()
    }

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
    
    // MARK: - Configuración
    
    func configurarFamilia(_ familiaId: String) {
        self.familiaId = familiaId
        self.isLoading = true // Activar loading antes de iniciar el observador
        iniciarObservadorCuentas() // El observador cargará las cuentas automáticamente
    }
    
    // MARK: - Carga de datos familiares
    
    func cargarCuentasFamiliares() {
        guard let familiaIdUnwrapped = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task { @MainActor in
            do {
                let cuentasFamiliares = try await firebaseService.obtenerCuentasFamilia(familiaId: familiaIdUnwrapped)
                
                self.cuentas = cuentasFamiliares
                self.isLoading = false
            } catch {
                self.error = "Error al cargar cuentas: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func iniciarObservadorCuentas() {
        guard let familiaIdUnwrapped = familiaId else { return }
        
        // Detener observador anterior si existe
        detenerObservadorCuentas()
        
        // Iniciar nuevo observador
        observadorCuentasHandle = firebaseService.observarCuentas(familiaId: familiaIdUnwrapped) { [weak self] cuentas in
            Task { @MainActor in
                guard let self = self else { return }
                self.cuentas = cuentas
                self.isLoading = false
                print("🔄 Cuentas actualizadas: \(cuentas.count) cuentas")
            }
        }
    }
    

    
    // MARK: - Gestión de cuentas
    
    func agregarCuenta(_ cuenta: Cuenta) {
        guard let familiaIdUnwrapped = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.crearCuenta(cuenta, familiaId: familiaIdUnwrapped)
                await MainActor.run {
                    // El observador actualizará automáticamente las cuentas
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al agregar cuenta: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func actualizarCuenta(_ cuenta: Cuenta) {
        guard let familiaIdUnwrapped = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.actualizarCuenta(cuenta, familiaId: familiaIdUnwrapped)
                self.isLoading = false
            } catch {
                self.error = "Error al actualizar cuenta: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func eliminarCuenta(_ cuenta: Cuenta) {
        guard let familiaIdUnwrapped = familiaId else { 
            error = "No se puede eliminar: familia no configurada"
            print("❌ Error en eliminarCuenta: familiaId es nil.")
            return 
        }
        
        // Verificar que la cuenta aún existe en nuestra lista local
        guard let cuentaIndex = cuentas.firstIndex(where: { $0.id == cuenta.id }) else {
            error = "La cuenta ya fue eliminada o no se encontró en la lista local."
            print("⚠️ Advertencia en eliminarCuenta: La cuenta con id \(cuenta.id) no se encontró en el array 'cuentas'.")
            return
        }
        
        let cuentaAEliminar = cuentas[cuentaIndex]
        print("ℹ️ Información de la cuenta a eliminar: \(cuentaAEliminar)")

        // Eliminar de la lista local primero para UI responsiva
        cuentas.remove(at: cuentaIndex)
        
        isLoading = true
        error = nil
        
        // Simplificación: usar Task normal sin timeout complejo
        Task {
            do {
                print("🗑️ Iniciando eliminación de cuenta en Firebase: \(cuentaAEliminar.nombre) con id \(cuentaAEliminar.id)")
                try await firebaseService.eliminarCuenta(cuentaId: cuentaAEliminar.id, familiaId: familiaIdUnwrapped)
                
                await MainActor.run {
                    self.isLoading = false
                    print("✅ Cuenta eliminada exitosamente de Firebase")
                }
                
            } catch {
                print("❌ Error eliminando cuenta desde Firebase: \(error.localizedDescription)")
                
                await MainActor.run {
                    // En caso de error, restaurar la cuenta en la lista local
                    self.cuentas.insert(cuentaAEliminar, at: cuentaIndex)
                    self.error = "Error al eliminar cuenta: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func marcarComoPagada(_ cuenta: Cuenta, monto: Double? = nil, usuario: String) {
        guard familiaId != nil else { return }
        
        Task {
            // TODO: Implementar registrarPagoCuenta usando crearTransaccionPago
            // try await firebaseService.registrarPagoCuenta(
            //     familiaId: familiaId,
            //     cuentaId: cuenta.id,
            //     monto: monto ?? cuenta.monto,
            //     usuario: usuario
            // )
            print("⚠️ Función registrarPagoCuenta no implementada aún")
            print("✅ Cuenta marcada como pagada: \(cuenta.nombre)")
        }
    }
    
    func marcarComoPagada(_ cuentaId: String) {
        guard let _ = familiaId,
              let cuentaIndex = cuentas.firstIndex(where: { $0.id == cuentaId }) else { return }
        
        var cuenta = cuentas[cuentaIndex]
        cuenta.fechaPago = Date()
        cuenta.estado = .pagada // Asegurar que el estado se actualice
        cuenta.montoPagado = cuenta.monto // Asumir que se paga el monto completo
        
        actualizarCuenta(cuenta)
    }
    
    // MARK: - Computed Properties para Dashboard
    
    // ESTADÍSTICAS GENERALES (todas las cuentas, no solo del mes)
    
    // Resumen financiero general de todas las cuentas
    var resumenGeneral: ResumenFinanciero {
        return ResumenFinanciero(
            totalCuentas: cuentas.count,
            totalMonto: cuentas.reduce(0) { $0 + $1.monto },
            pagadas: cuentas.filter { $0.estado == .pagada }.count,
            pendientes: cuentas.filter { $0.estado == .pendiente }.count,
            vencidas: cuentas.filter { $0.estado == .vencida }.count,
            montoPagado: cuentas.filter { $0.estado == .pagada }.reduce(0) { $0 + $1.monto },
            montoPendiente: cuentas.filter { $0.estado == .pendiente }.reduce(0) { $0 + $1.monto },
            montoVencido: cuentas.filter { $0.estado == .vencida }.reduce(0) { $0 + $1.monto }
        )
    }
    
    // Análisis por categorías de todas las cuentas
    var gastosPorCategoriaGeneral: [GastoCategoria] {
        let grouped = Dictionary(grouping: cuentas) { $0.categoria }
        
        return grouped.map { categoria, cuentas in
            GastoCategoria(
                categoria: categoria,
                total: cuentas.reduce(0) { $0 + $1.monto },
                cuentas: cuentas.count,
                pagadas: cuentas.filter { $0.estado == .pagada }.count
            )
        }.sorted { $0.total > $1.total }
    }
    
    // ESTADÍSTICAS MENSUALES (del mes seleccionado)
    
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
    
    // Análisis por categoría de todas las cuentas (no solo del mes)
    var analisisPorCategoriaGeneral: [AnalisisCategoria] {
        let totalMonto = cuentas.reduce(0) { $0 + $1.monto }
        
        let grouped = Dictionary(grouping: cuentas, by: { $0.categoria })
        
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
    
    // Top proveedores de todas las cuentas (no solo del mes)
    var topProveedoresGeneral: [AnalisisProveedor] {
        let grouped = Dictionary(grouping: cuentas, by: { $0.proveedor })
        
        return grouped.map { proveedor, cuentas in
            let total = cuentas.reduce(0) { $0 + $1.monto }
            
            return AnalisisProveedor(
                proveedor: proveedor,
                total: total,
                cantidad: cuentas.count
            )
        }.sorted { $0.total > $1.total }
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
    
    func marcarComoPagada(_ cuenta: Cuenta, fechaPago: Date = Date(), montoPagado: Double? = nil) {
        guard familiaId != nil else { return }
        
        // Actualizar localmente primero para UI responsiva
        if let index = cuentas.firstIndex(where: { $0.id == cuenta.id }) {
            cuentas[index].fechaPago = fechaPago
            cuentas[index].montoPagado = montoPagado ?? cuenta.monto
            cuentas[index].estado = .pagada
        }
        
        // Sincronizar con Firebase
        Task {
            // TODO: Implementar registrarPagoCuenta usando crearTransaccionPago
            // try await firebaseService.registrarPagoCuenta(
            //     familiaId: familiaId,
            //     cuentaId: cuenta.id,
            //     monto: montoPagado ?? cuenta.monto,
            //     usuario: "Usuario",
            //     fecha: fechaPago
            // )
            print("⚠️ Función registrarPagoCuenta no implementada aún")
            
            // El observador actualizará automáticamente las cuentas
        }
    }
    
    // MARK: - Gestión de Pagos
    func registrarPago(cuenta: Cuenta, monto: Double, fecha: Date, notas: String, tieneComprobante: Bool) {
        guard let familiaIdUnwrapped = familiaId else { return }
        
        // Actualizar localmente primero para UI responsiva
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
        
        // Sincronizar con Firebase
        Task {
            do {
                // TODO: Implementar registrarPagoCuenta usando crearTransaccionPago
                // try await firebaseService.registrarPagoCuenta(
                //     familiaId: familiaId,
                //     cuentaId: cuenta.id,
                //     monto: monto,
                //     usuario: "Usuario",
                //     fecha: fecha
                // )
                
                // Crear cuenta actualizada con toda la información
                var cuentaActualizada = cuenta
                cuentaActualizada.estado = .pagada
                cuentaActualizada.montoPagado = monto
                cuentaActualizada.fechaPago = fecha
                
                // Actualizar descripción si hay notas
                if !notas.isEmpty {
                    cuentaActualizada.descripcion = notas.isEmpty ? cuenta.descripcion : "\(cuenta.descripcion)\n\nNotas de pago: \(notas)"
                }
                
                // Agregar comprobante si existe
                if tieneComprobante {
                    cuentaActualizada.comprobanteURL = URL(string: "file://comprobante_\(cuenta.id)")
                }
                
                // Actualizar la cuenta completa en Firebase
                try await firebaseService.actualizarCuenta(cuentaActualizada, familiaId: familiaIdUnwrapped)
                
                print("✅ Pago registrado exitosamente para cuenta: \(cuenta.nombre)")
                
                // La recarga de cuentas no es necesaria aquí porque el observador de Firebase
                // se encargará de actualizar automáticamente las cuentas cuando cambien en la base de datos
                
            } catch {
                await MainActor.run {
                    self.error = "Error al registrar pago: \(error.localizedDescription)"
                    print("❌ Error al registrar pago: \(error.localizedDescription)")
                    
                    // Revertir cambios locales si falló la sincronización
                    if let index = self.cuentas.firstIndex(where: { $0.id == cuenta.id }) {
                        self.cuentas[index] = cuenta // Revertir al estado original
                    }
                }
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
                    año: añoCuentas.año,
                    nombreMes: DateFormatter().monthSymbols[mes - 1],
                    cuentas: cuentas.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
                )
            };
            
            let mesesOrdenados = mesesCuentas.sorted { $0.mes > $1.mes };
            
            return AñoCuentas(año: añoCuentas.año, cuentas: añoCuentas.cuentas, meses: mesesOrdenados)
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
        
        return agruparCuentasPorAñoYMesOrdenado(cuentasAFiltrar)
    }
    
    // Función auxiliar mejorada con ordenamiento cronológico inverso
    private func agruparCuentasPorAñoYMesOrdenado(_ cuentasFiltradas: [Cuenta]) -> [AñoCuentas] {
        let calendario = Calendar.current
        let fechaActual = Date()
        let añoActual = calendario.component(.year, from: fechaActual)
        let mesActual = calendario.component(.month, from: fechaActual)
        
        // Agrupar por año
        let cuentasAgrupadas = Dictionary(grouping: cuentasFiltradas) { cuenta in
            calendario.component(.year, from: cuenta.fechaVencimiento)
        }
        
        var resultado: [AñoCuentas] = []
        
        for (año, cuentasDelAño) in cuentasAgrupadas {
            // Agrupar por mes dentro del año
            let mesesAgrupados = Dictionary(grouping: cuentasDelAño) { cuenta in
                calendario.component(.month, from: cuenta.fechaVencimiento)
            }
            
            var meses: [MesCuentas] = []
            for (mes, cuentasDelMes) in mesesAgrupados {
                guard mes >= 1 && mes <= 12 else { continue }
                let nombreMes = DateFormatter().monthSymbols[mes - 1]
                
                let mesCuentas = MesCuentas(
                    mes: mes,
                    año: año,
                    nombreMes: nombreMes,
                    cuentas: cuentasDelMes.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
                )
                meses.append(mesCuentas)
            }
            
            // Ordenar meses cronológicamente inverso (más reciente primero)
            let mesesOrdenados = meses.sorted { mes1, mes2 in
                // Si son del mismo año, ordenar por mes (más reciente primero)
                if mes1.año == mes2.año {
                    return ordenarMesesCronologicamente(mes1: mes1.mes, mes2: mes2.mes, añoActual: añoActual, mesActual: mesActual)
                }
                // Años más recientes primero
                return mes1.año > mes2.año
            }
            
            let añoCuentas = AñoCuentas(
                año: año,
                cuentas: cuentasDelAño,
                meses: mesesOrdenados
            )
            
            resultado.append(añoCuentas)
        }
        
        // Ordenar los años (más recientes primero)
        return resultado.sorted { $0.año > $1.año }
    }
    
    // Función auxiliar para ordenar meses cronológicamente
    private func ordenarMesesCronologicamente(mes1: Int, mes2: Int, añoActual: Int, mesActual: Int) -> Bool {
        // Calcular "distancia" desde el mes actual
        let distancia1 = calcularDistanciaDesdeMesActual(mes: mes1, mesActual: mesActual)
        let distancia2 = calcularDistanciaDesdeMesActual(mes: mes2, mesActual: mesActual)
        
        return distancia1 < distancia2
    }
    
    private func calcularDistanciaDesdeMesActual(mes: Int, mesActual: Int) -> Int {
        if mes <= mesActual {
            return mesActual - mes  // Meses del año actual (0 = mes actual)
        } else {
            return (12 - mes) + mesActual + 12  // Meses del año anterior
        }
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

// MARK: - Estructuras para el análisis financiero

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
    
    var porcentajePendiente: Double {
        totalMonto > 0 ? (montoPendiente / totalMonto) * 100 : 0
    }
    
    var porcentajeVencido: Double {
        totalMonto > 0 ? (montoVencido / totalMonto) * 100 : 0
    }
}

struct GastoCategoria: Identifiable {
    let id = UUID()
    let categoria: String
    let total: Double
    let cuentas: Int
    let pagadas: Int
    
    var porcentajePagado: Double {
        cuentas > 0 ? Double(pagadas) / Double(cuentas) * 100 : 0
    }
}

// MARK: - Estructuras para agrupación temporal

struct MesCuentas: Identifiable {
    let id = UUID()
    let mes: Int
    let año: Int
    let nombreMes: String
    let cuentas: [Cuenta]
    
    var totalCuentas: Int {
        return cuentas.count
    }
    
    var totalMonto: Double {
        return cuentas.reduce(0) { $0 + $1.monto }
    }
    
    var cuentasPagadas: Int {
        return cuentas.filter { $0.estado == .pagada }.count
    }
    
    var cuentasPendientes: Int {
        return cuentas.filter { $0.estado == .pendiente }.count
    }
    
    var cuentasVencidas: Int {
        return cuentas.filter { $0.estado == .vencida }.count
    }
}

struct AñoCuentas: Identifiable {
    let id = UUID()
    let año: Int
    let cuentas: [Cuenta]
    var meses: [MesCuentas] = []
    
    var totalCuentas: Int {
        return cuentas.count
    }
    
    var totalMonto: Double {
        return cuentas.reduce(0) { $0 + $1.monto }
    }
    
    var cuentasPagadas: Int {
        return cuentas.filter { $0.estado == .pagada }.count
    }
    
    var cuentasPendientes: Int {
        return cuentas.filter { $0.estado == .pendiente }.count
    }
    
    var cuentasVencidas: Int {
        return cuentas.filter { $0.estado == .vencida }.count
    }
}
