import Foundation
import SwiftUI

// MARK: - Estructuras para el Calendario de Presupuesto

struct MesPresupuestoInfo: Identifiable, Hashable {
    let id = UUID()
    let mes: Int
    let año: Int
    let fecha: Date
    let nombre: String
    let presupuesto: PresupuestoMensual?
    let totalAportes: Double          // Suma de todos los montos aportados
    let totalAportesUtilizados: Double // Suma de todos los montos utilizados
    let totalGastos: Double
    let saldoDisponible: Double       // totalAportes - totalAportesUtilizados
    let cantidadTransacciones: Int
    let estaCerrado: Bool
    let alertas: [AlertaFinancieraCalendario]
    
    // Computed properties
    var tienePresupuesto: Bool {
        presupuesto != nil
    }
    
    var totalAportesDisponibles: Double {
        saldoDisponible
    }
    
    var saldoFinal: Double {
        totalAportes - totalGastos
    }
    
    var estadoMes: EstadoMes {
        if estaCerrado {
            return .cerrado
        } else if tienePresupuesto {
            return .activo
        } else {
            return .vacio
        }
    }
    
    var colorIndicador: Color {
        switch estadoMes {
        case .cerrado:
            return .green
        case .activo:
            return saldoFinal >= 0 ? .blue : .red
        case .vacio:
            return .gray.opacity(0.3)
        }
    }
    
    var porcentajeGastado: Double {
        guard totalAportes > 0 else { return 0 }
        return min(totalGastos / totalAportes, 1.0)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MesPresupuestoInfo, rhs: MesPresupuestoInfo) -> Bool {
        lhs.id == rhs.id
    }
}

enum EstadoMes: String, CaseIterable {
    case vacio = "Sin presupuesto"
    case activo = "Activo"
    case cerrado = "Cerrado"
}

struct AlertaFinancieraCalendario: Identifiable, Hashable {
    let id = UUID()
    let tipo: TipoAlertaCalendario
    let mensaje: String
    let color: Color
    let icono: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AlertaFinancieraCalendario, rhs: AlertaFinancieraCalendario) -> Bool {
        lhs.id == rhs.id
    }
}

enum TipoAlertaCalendario: String, CaseIterable {
    case saldoBajo = "Saldo bajo"
    case sinAportes = "Sin aportes"
    case excedido = "Presupuesto excedido"
    case sinGastos = "Sin gastos registrados"
}

// MARK: - Extensiones para facilitar el trabajo con fechas

extension Date {
    func inicioDelMes() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
    
    func finDelMes() -> Date {
        let calendar = Calendar.current
        let inicioDelMes = self.inicioDelMes()
        let siguienteMes = calendar.date(byAdding: .month, value: 1, to: inicioDelMes) ?? inicioDelMes
        return calendar.date(byAdding: .day, value: -1, to: siguienteMes) ?? inicioDelMes
    }
    
    func esMismoMes(que otraFecha: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: otraFecha, toGranularity: .month)
    }
}

// MARK: - Helpers para formateo

extension Double {
    @MainActor
    func formatearComoMoneda() -> String {
        let configuracion = ConfiguracionService.shared
        let moneda = configuracion.monedaSeleccionada
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = moneda.codigo
        formatter.locale = Locale(identifier: moneda.localeIdentifier)
        
        // Configurar decimales según la moneda
        switch moneda {
        case .yen:
            formatter.maximumFractionDigits = 0
        case .chileno, .peso_colombiano, .peso_argentino:
            formatter.maximumFractionDigits = 0
        default:
            formatter.maximumFractionDigits = 2
        }
        
        return formatter.string(from: NSNumber(value: self)) ?? "\(moneda.simbolo)\(self)"
    }
}

extension Int {
    func nombreMes() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(month: self)) ?? Date()
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Extensión para previews

extension MesPresupuestoInfo {
    /// Crea un ejemplo de MesPresupuestoInfo para usar en previews
    static var ejemplo: MesPresupuestoInfo {
        let fechaActual = Date()
        let calendar = Calendar.current
        let mes = calendar.component(.month, from: fechaActual)
        let año = calendar.component(.year, from: fechaActual)
        
        return MesPresupuestoInfo(
            mes: mes,
            año: año,
            fecha: fechaActual,
            nombre: mes.nombreMes(),
            presupuesto: nil,
            totalAportes: 300000,
            totalAportesUtilizados: 120000,
            totalGastos: 150000,
            saldoDisponible: 180000,
            cantidadTransacciones: 12,
            estaCerrado: false,
            alertas: [
                AlertaFinancieraCalendario(
                    tipo: .saldoBajo,
                    mensaje: "Ejemplo de alerta para previews",
                    color: .orange,
                    icono: "exclamationmark.triangle.fill"
                )
            ]
        )
    }
}
