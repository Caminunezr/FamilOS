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
    let totalAportes: Double
    let totalGastos: Double
    let saldoDisponible: Double
    let cantidadTransacciones: Int
    let estaCerrado: Bool
    let alertas: [AlertaFinancieraCalendario]
    
    // Computed properties
    var tienePresupuesto: Bool {
        presupuesto != nil
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
    func formatearComoMoneda() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "€0"
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
