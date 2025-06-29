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
    
    // MARK: - Nuevas propiedades para integración con cuentas
    @Published var presupuestosPorCategoria: [String: Double] = [:]
    private var cuentasViewModel: CuentasViewModel?
    
    // MARK: - Configuración de integración
    func configurarIntegracionCuentas(_ cuentasVM: CuentasViewModel) {
        self.cuentasViewModel = cuentasVM
        cargarPresupuestosPorCategoriaEjemplo()
    }
    
    private func cargarPresupuestosPorCategoriaEjemplo() {
        // Usar las nuevas categorías predefinidas
        presupuestosPorCategoria = [
            CategoriaFinanciera.luz.rawValue: 1200.0,
            CategoriaFinanciera.agua.rawValue: 400.0,
            CategoriaFinanciera.gas.rawValue: 500.0,
            CategoriaFinanciera.internet.rawValue: 600.0,
            CategoriaFinanciera.mascotas.rawValue: 300.0,
            CategoriaFinanciera.hogar.rawValue: 2000.0
        ]
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
    
    // MARK: - Métodos de carga de datos
    
    func cargarDatosEjemplo() {
        let calendar = Calendar.current
        let hoy = Date()
        
        // Crear presupuestos para los últimos 3 meses
        for i in 0...2 {
            if let fecha = calendar.date(byAdding: .month, value: -i, to: hoy) {
                let presupuesto = PresupuestoMensual(
                    fechaMes: fecha,
                    creador: "Usuario",
                    cerrado: i > 0,  // Solo el mes actual está abierto
                    sobranteTransferido: i == 0 ? 1500.0 : 0.0  // El mes actual tiene un sobrante transferido
                )
                presupuestos.append(presupuesto)
                
                // Agregar aportes para este presupuesto
                let aporte1 = Aporte(
                    presupuestoId: presupuesto.id,
                    usuario: "Usuario Principal",
                    monto: 15000.0,
                    comentario: "Sueldo mensual"
                )
                
                let aporte2 = Aporte(
                    presupuestoId: presupuesto.id,
                    usuario: "Usuario Secundario",
                    monto: 8000.0,
                    comentario: "Aporte familiar"
                )
                
                aportes.append(contentsOf: [aporte1, aporte2])
                
                // Agregar deudas para el presupuesto actual
                if i == 0 {
                    let deuda1 = DeudaPresupuesto(
                        presupuestoId: presupuesto.id,
                        categoria: "Préstamo Hipotecario",
                        montoTotal: 120000.0,
                        cuotasTotales: 12,
                        tasaInteres: 5.5,
                        fechaInicio: fecha,
                        descripcion: "Préstamo para renovación de cocina"
                    )
                    
                    let deuda2 = DeudaPresupuesto(
                        presupuestoId: presupuesto.id,
                        categoria: "Servicios",
                        montoTotal: 5000.0,
                        cuotasTotales: 1,
                        tasaInteres: 0.0,
                        fechaInicio: fecha,
                        descripcion: "Gastos fijos mensuales"
                    )
                    
                    deudas.append(contentsOf: [deuda1, deuda2])
                }
            }
        }
    }
    
    // MARK: - Métodos de gestión
    
    func agregarAporte(_ aporte: Aporte) {
        aportes.append(aporte)
        objectWillChange.send()
    }
    
    func agregarDeuda(_ deuda: DeudaPresupuesto) {
        deudas.append(deuda)
        objectWillChange.send()
    }
    
    func eliminarAporte(id: String) {
        aportes.removeAll(where: { $0.id == id })
        objectWillChange.send()
    }
    
    func eliminarDeuda(id: String) {
        deudas.removeAll(where: { $0.id == id })
        objectWillChange.send()
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
