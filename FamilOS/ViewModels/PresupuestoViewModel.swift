import Foundation
import SwiftUI
import Combine

// MARK: - Estructuras para el cruce de datos
struct CategoriaPresupuestoAnalisis: Identifiable {
    let id = UUID().uuidString
    let nombre: String
    let icono: String
    let presupuestoMensual: Double
    let gastoActual: Double
    let gastoProyectado: Double
    let porcentajeUsado: Double
    let estado: EstadoPresupuesto
    let cuentasPendientes: Int
    let cuentasPagadas: Int
    
    var diferencia: Double {
        presupuestoMensual - gastoActual
    }
    
    var proyeccionFinal: Double {
        gastoActual + gastoProyectado
    }
    
    var excedeProyeccion: Bool {
        proyeccionFinal > presupuestoMensual
    }
}

enum EstadoPresupuesto: CaseIterable {
    case enRango        // < 70% del presupuesto
    case atencion       // 70-90% del presupuesto
    case cerca          // 90-100% del presupuesto
    case excedido       // > 100% del presupuesto
    case sinPresupuesto // No hay límite definido
    
    var color: Color {
        switch self {
        case .enRango: return .green
        case .atencion: return .yellow
        case .cerca: return .orange
        case .excedido: return .red
        case .sinPresupuesto: return .gray
        }
    }
    
    var mensaje: String {
        switch self {
        case .enRango: return "En rango"
        case .atencion: return "Atención"
        case .cerca: return "Cerca del límite"
        case .excedido: return "Excedido"
        case .sinPresupuesto: return "Sin presupuesto"
        }
    }
    
    var icono: String {
        switch self {
        case .enRango: return "checkmark.circle.fill"
        case .atencion: return "exclamationmark.triangle.fill"
        case .cerca: return "exclamationmark.triangle.fill"
        case .excedido: return "xmark.circle.fill"
        case .sinPresupuesto: return "questionmark.circle.fill"
        }
    }
}

struct ResumenFinancieroIntegrado {
    let presupuestoTotal: Double
    let gastoActual: Double
    let gastoProyectado: Double
    let disponible: Double
    let porcentajeUsado: Double
    let categorias: [CategoriaPresupuestoAnalisis]
    let alertas: [AlertaFinanciera]
    
    var excedePresupuesto: Bool {
        gastoActual > presupuestoTotal
    }
    
    var proyeccionExcede: Bool {
        (gastoActual + gastoProyectado) > presupuestoTotal
    }
}

struct AlertaFinanciera: Identifiable {
    let id = UUID().uuidString
    let tipo: TipoAlerta
    let mensaje: String
    let categoria: String?
    let urgencia: NivelUrgencia
}

enum TipoAlerta {
    case presupuestoExcedido
    case cercaDelLimite
    case proyeccionExcede
    case sinPresupuesto
    case vencimientoProximo
}

enum NivelUrgencia {
    case bajo, medio, alto, critico
    
    var color: Color {
        switch self {
        case .bajo: return .blue
        case .medio: return .yellow
        case .alto: return .orange
        case .critico: return .red
        }
    }
}

// MARK: - PresupuestoViewModel
class PresupuestoViewModel: ObservableObject {
    @Published var presupuestos: [PresupuestoMensual] = []
    @Published var aportes: [Aporte] = []
    @Published var deudas: [DeudaPresupuesto] = []
    @Published var mesSeleccionado: Date = Date()
    @Published var mostrarMesesAnteriores: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // MARK: - Nuevas propiedades para integración con cuentas
    @Published var presupuestosPorCategoria: [String: Double] = [:]
    private var cuentasViewModel: CuentasViewModel?
    private let firebaseService = FirebaseService()
    private var familiaId: String?
    
    // MARK: - Configuración
    
    func configurarFamilia(_ familiaId: String) {
        self.familiaId = familiaId
        cargarDatosFamiliares()
    }
    
    // MARK: - Configuración de integración con cuentas
    func configurarIntegracionCuentas(_ cuentasVM: CuentasViewModel) {
        self.cuentasViewModel = cuentasVM
    }
    
    // MARK: - Carga de datos familiares
    
    func cargarDatosFamiliares() {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                async let presupuestoTask = firebaseService.obtenerPresupuestosFamilia(familiaId: familiaId)
                async let aportesTask = firebaseService.obtenerAportesFamilia(familiaId: familiaId)
                async let deudasTask = firebaseService.obtenerDeudasFamilia(familiaId: familiaId)
                
                let (presupuestosCargados, aportesCargados, deudasCargadas) = try await (presupuestoTask, aportesTask, deudasTask)
                
                await MainActor.run {
                    self.presupuestos = presupuestosCargados
                    self.aportes = aportesCargados
                    self.deudas = deudasCargadas
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al cargar datos de presupuesto: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    // Propiedades calculadas
    var presupuestoActual: PresupuestoMensual? {
        let calendar = Calendar.current
        return presupuestos.first(where: { presupuesto in
            return calendar.isDate(presupuesto.fechaMes, equalTo: mesSeleccionado, toGranularity: .month)
        })
    }
    
    var aportesDelMes: [Aporte] {
        guard let presupuesto = presupuestoActual else { return [] }
        return aportes.filter { $0.presupuestoId == presupuesto.id }
    }
    
    var deudasDelMes: [DeudaPresupuesto] {
        guard let presupuesto = presupuestoActual else { return [] }
        return deudas.filter { $0.presupuestoId == presupuesto.id }
    }
    
    var totalAportes: Double {
        return aportesDelMes.reduce(0) { $0 + $1.monto }
    }
    
    var totalDeudasMensuales: Double {
        return deudasDelMes.reduce(0) { $0 + $1.montoCuotaMensual }
    }
    
    var saldoDisponible: Double {
        return totalAportes - totalDeudasMensuales + (presupuestoActual?.sobranteTransferido ?? 0)
    }
    
    // MARK: - Gestión de presupuestos
    
    func crearPresupuestoMensual(_ presupuesto: PresupuestoMensual) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.crearPresupuesto(presupuesto, familiaId: familiaId)
                await cargarDatosFamiliares()
            } catch {
                await MainActor.run {
                    self.error = "Error al crear presupuesto: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func agregarAporte(_ aporte: Aporte) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.crearAporte(aporte, familiaId: familiaId)
                await cargarDatosFamiliares()
            } catch {
                await MainActor.run {
                    self.error = "Error al agregar aporte: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func agregarDeuda(_ deuda: DeudaPresupuesto) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.crearDeuda(deuda, familiaId: familiaId)
                await cargarDatosFamiliares()
            } catch {
                await MainActor.run {
                    self.error = "Error al agregar deuda: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func eliminarAporte(id: String) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.eliminarAporte(aporteId: id, familiaId: familiaId)
                await cargarDatosFamiliares()
            } catch {
                await MainActor.run {
                    self.error = "Error al eliminar aporte: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func eliminarDeuda(id: String) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.eliminarDeuda(deudaId: id, familiaId: familiaId)
                await cargarDatosFamiliares()
            } catch {
                await MainActor.run {
                    self.error = "Error al eliminar deuda: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func transferirSobrante() {
        guard let presupuestoActual = presupuestoActual,
              let siguienteIndex = presupuestos.firstIndex(where: { $0.id == presupuestoActual.id })?.advanced(by: 1),
              siguienteIndex < presupuestos.count else {
            // Crear nuevo presupuesto para el próximo mes
            let calendar = Calendar.current
            if let siguienteMes = calendar.date(byAdding: .month, value: 1, to: mesSeleccionado) {
                var nuevoPresupuesto = PresupuestoMensual(
                    fechaMes: siguienteMes,
                    creador: "Usuario",
                    cerrado: false,
                    sobranteTransferido: saldoDisponible > 0 ? saldoDisponible : 0
                )
                presupuestos.append(nuevoPresupuesto)
            }
            return
        }
        
        // Actualizar el sobrante transferido al siguiente mes
        presupuestos[siguienteIndex].sobranteTransferido += saldoDisponible > 0 ? saldoDisponible : 0
        
        // Cerrar el presupuesto actual
        if let index = presupuestos.firstIndex(where: { $0.id == presupuestoActual.id }) {
            presupuestos[index].cerrado = true
        }
        
        objectWillChange.send()
    }
    
    func cambiarMes(avanzar: Bool) {
        let calendar = Calendar.current
        if let nuevaFecha = calendar.date(byAdding: .month, value: avanzar ? 1 : -1, to: mesSeleccionado) {
            mesSeleccionado = nuevaFecha
        }
    }
    
    // MARK: - Datos para gráficos
    
    func datosGraficoAportes() -> [(String, Double)] {
        var datos: [(String, Double)] = []
        let aportesAgrupados = Dictionary(grouping: aportesDelMes, by: { $0.usuario })
        
        for (usuario, aportes) in aportesAgrupados {
            let total = aportes.reduce(0) { $0 + $1.monto }
            datos.append((usuario, total))
        }
        
        return datos
    }
    
    func datosGraficoGastos() -> [(String, Double)] {
        var datos: [(String, Double)] = []
        let deudasAgrupadas = Dictionary(grouping: deudasDelMes, by: { $0.categoria })
        
        for (categoria, deudas) in deudasAgrupadas {
            let total = deudas.reduce(0) { $0 + $1.montoCuotaMensual }
            datos.append((categoria, total))
        }
        
        return datos
    }
    
    // MARK: - Análisis integrado de presupuesto vs cuentas
    func analisisPresupuestoVsCuentas() -> [CategoriaPresupuestoAnalisis] {
        guard let cuentasVM = cuentasViewModel else { return [] }
        
        let calendario = Calendar.current
        let cuentasDelMes = cuentasVM.cuentas.filter { cuenta in
            calendario.isDate(cuenta.fechaVencimiento, equalTo: mesSeleccionado, toGranularity: .month)
        }
        
        return presupuestosPorCategoria.map { (categoria, presupuesto) in
            let cuentasCategoria = cuentasDelMes.filter { $0.categoria == categoria }
            
            // Calcular gastos reales (cuentas pagadas)
            let gastoActual = cuentasCategoria
                .filter { $0.estado == .pagada }
                .reduce(0) { $0 + $1.monto }
            
            // Calcular gastos proyectados (pendientes + vencidas)
            let gastoProyectado = cuentasCategoria
                .filter { $0.estado != .pagada }
                .reduce(0) { $0 + $1.monto }
            
            let porcentajeUsado = presupuesto > 0 ? gastoActual / presupuesto : 0
            let estado = calcularEstadoPresupuesto(porcentajeUsado, gastoProyectado: gastoProyectado, presupuesto: presupuesto)
            
            let cuentasPendientes = cuentasCategoria.filter { $0.estado != .pagada }.count
            let cuentasPagadas = cuentasCategoria.filter { $0.estado == .pagada }.count
            
            // Obtener icono de la categoría
            let icono = obtenerIconoCategoria(categoria)
            
            return CategoriaPresupuestoAnalisis(
                nombre: categoria,
                icono: icono,
                presupuestoMensual: presupuesto,
                gastoActual: gastoActual,
                gastoProyectado: gastoProyectado,
                porcentajeUsado: porcentajeUsado,
                estado: estado,
                cuentasPendientes: cuentasPendientes,
                cuentasPagadas: cuentasPagadas
            )
        }.sorted { $0.porcentajeUsado > $1.porcentajeUsado }
    }
    
    func resumenFinancieroIntegrado() -> ResumenFinancieroIntegrado {
        let categorias = analisisPresupuestoVsCuentas()
        
        let presupuestoTotal = presupuestosPorCategoria.values.reduce(0, +)
        let gastoActual = categorias.reduce(0) { $0 + $1.gastoActual }
        let gastoProyectado = categorias.reduce(0) { $0 + $1.gastoProyectado }
        let disponible = presupuestoTotal - gastoActual
        let porcentajeUsado = presupuestoTotal > 0 ? gastoActual / presupuestoTotal : 0
        
        let alertas = generarAlertas(categorias: categorias)
        
        return ResumenFinancieroIntegrado(
            presupuestoTotal: presupuestoTotal,
            gastoActual: gastoActual,
            gastoProyectado: gastoProyectado,
            disponible: disponible,
            porcentajeUsado: porcentajeUsado,
            categorias: categorias,
            alertas: alertas
        )
    }
    
    private func calcularEstadoPresupuesto(_ porcentajeUsado: Double, gastoProyectado: Double, presupuesto: Double) -> EstadoPresupuesto {
        if presupuesto == 0 {
            return .sinPresupuesto
        }
        
        let proyeccionTotal = porcentajeUsado + (gastoProyectado / presupuesto)
        
        if porcentajeUsado > 1.0 {
            return .excedido
        } else if proyeccionTotal > 1.0 || porcentajeUsado > 0.9 {
            return .cerca
        } else if porcentajeUsado > 0.7 {
            return .atencion
        } else {
            return .enRango
        }
    }
    
    private func obtenerIconoCategoria(_ categoria: String) -> String {
        // Usar el nuevo enum de categorías
        if let categoriaEnum = CategoriaFinanciera.allCases.first(where: { $0.rawValue == categoria }) {
            return categoriaEnum.icono
        }
        
        // Fallback para categorías que no estén en el nuevo enum
        switch categoria {
        case "Arriendo": return "house.fill"
        case "Alimentación": return "fork.knife"
        case "Transporte": return "car.fill"
        case "Salud": return "cross.case.fill"
        case "Entretenimiento": return "tv.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func generarAlertas(categorias: [CategoriaPresupuestoAnalisis]) -> [AlertaFinanciera] {
        var alertas: [AlertaFinanciera] = []
        
        for categoria in categorias {
            switch categoria.estado {
            case .excedido:
                alertas.append(AlertaFinanciera(
                    tipo: .presupuestoExcedido,
                    mensaje: "\(categoria.nombre): Presupuesto excedido en $\(String(format: "%.0f", -categoria.diferencia))",
                    categoria: categoria.nombre,
                    urgencia: .critico
                ))
                
            case .cerca:
                if categoria.excedeProyeccion {
                    alertas.append(AlertaFinanciera(
                        tipo: .proyeccionExcede,
                        mensaje: "\(categoria.nombre): Proyección excederá presupuesto en $\(String(format: "%.0f", categoria.proyeccionFinal - categoria.presupuestoMensual))",
                        categoria: categoria.nombre,
                        urgencia: .alto
                    ))
                } else {
                    alertas.append(AlertaFinanciera(
                        tipo: .cercaDelLimite,
                        mensaje: "\(categoria.nombre): Cerca del límite (\(String(format: "%.0f", categoria.porcentajeUsado * 100))%)",
                        categoria: categoria.nombre,
                        urgencia: .medio
                    ))
                }
                
            case .atencion:
                alertas.append(AlertaFinanciera(
                    tipo: .cercaDelLimite,
                    mensaje: "\(categoria.nombre): Atención - \(String(format: "%.0f", categoria.porcentajeUsado * 100))% usado",
                    categoria: categoria.nombre,
                    urgencia: .medio
                ))
                
            case .sinPresupuesto:
                if categoria.gastoActual > 0 {
                    alertas.append(AlertaFinanciera(
                        tipo: .sinPresupuesto,
                        mensaje: "\(categoria.nombre): Sin presupuesto definido ($\(String(format: "%.0f", categoria.gastoActual)) gastado)",
                        categoria: categoria.nombre,
                        urgencia: .bajo
                    ))
                }
                
            case .enRango:
                break // No genera alertas
            }
        }
        
        // Agregar alertas de vencimientos próximos si hay acceso a cuentasViewModel
        if let cuentasVM = cuentasViewModel {
            let cuentasProximasVencer = cuentasVM.cuentasProximasVencer
            if !cuentasProximasVencer.isEmpty {
                alertas.append(AlertaFinanciera(
                    tipo: .vencimientoProximo,
                    mensaje: "\(cuentasProximasVencer.count) cuenta(s) vencen pronto",
                    categoria: nil,
                    urgencia: .alto
                ))
            }
        }
        
        return alertas.sorted { $0.urgencia.hashValue > $1.urgencia.hashValue }
    }
    
    // MARK: - Métodos de gestión de presupuestos por categoría
    func actualizarPresupuestoCategoria(_ categoria: String, monto: Double) {
        presupuestosPorCategoria[categoria] = monto
        objectWillChange.send()
    }
    
    func obtenerPresupuestoCategoria(_ categoria: String) -> Double {
        return presupuestosPorCategoria[categoria] ?? 0.0
    }
    
    func categoriasConGastosSinPresupuesto() -> [String] {
        guard let cuentasVM = cuentasViewModel else { return [] }
        
        let calendario = Calendar.current
        let cuentasDelMes = cuentasVM.cuentas.filter { cuenta in
            calendario.isDate(cuenta.fechaVencimiento, equalTo: mesSeleccionado, toGranularity: .month)
        }
        
        let categoriasConGastos = Set(cuentasDelMes.map { $0.categoria })
        let categoriasConPresupuesto = Set(presupuestosPorCategoria.keys)
        
        return Array(categoriasConGastos.subtracting(categoriasConPresupuesto))
    }
    
    func sugerirPresupuestoParaCategoria(_ categoria: String) -> Double {
        guard let cuentasVM = cuentasViewModel else { return 0 }
        
        // Calcular promedio de gastos de los últimos 3 meses para esta categoría
        let calendario = Calendar.current
        var totalGastos: Double = 0
        var mesesConGastos = 0
        
        for i in 0..<3 {
            if let fecha = calendario.date(byAdding: .month, value: -i, to: Date()) {
                let gastosDelMes = cuentasVM.cuentas
                    .filter { cuenta in
                        cuenta.categoria == categoria &&
                        calendario.isDate(cuenta.fechaVencimiento, equalTo: fecha, toGranularity: .month)
                    }
                    .reduce(0) { $0 + $1.monto }
                
                if gastosDelMes > 0 {
                    totalGastos += gastosDelMes
                    mesesConGastos += 1
                }
            }
        }
        
        if mesesConGastos > 0 {
            let promedio = totalGastos / Double(mesesConGastos)
            // Agregar un 10% de margen
            return promedio * 1.1
        }
        
        return 0
    }
}
