import Foundation
import SwiftUI
import Combine

// MARK: - Estructuras para el cruce de datos
struct CategoriaFinanciera: Identifiable {
    let id = UUID()
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
    let categorias: [CategoriaFinanciera]
    let alertas: [AlertaFinanciera]
    
    var excedePresupuesto: Bool {
        gastoActual > presupuestoTotal
    }
    
    var proyeccionExcede: Bool {
        (gastoActual + gastoProyectado) > presupuestoTotal
    }
}

struct AlertaFinanciera: Identifiable {
    let id = UUID()
    let tipo: TipoAlerta
    let mensaje: String
    let categoria: String?
    let urgencia: NivelUrgencia
    
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
}

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
        presupuestosPorCategoria = [
            "Luz": 1200.0,
            "Agua": 400.0,
            "Gas": 500.0,
            "Internet": 600.0,
            "Arriendo": 8500.0,
            "Alimentación": 3000.0,
            "Transporte": 1500.0,
            "Salud": 800.0,
            "Entretenimiento": 1000.0,
            "Otros": 500.0
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
    
    func eliminarAporte(id: UUID) {
        aportes.removeAll(where: { $0.id == id })
        objectWillChange.send()
    }
    
    func eliminarDeuda(id: UUID) {
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
}