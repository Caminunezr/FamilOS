import Foundation

struct PresupuestoMensual: Identifiable, Codable {
    var id: String = UUID().uuidString
    var fechaMes: Date
    var creador: String
    var cerrado: Bool = false
    var sobranteTransferido: Double = 0.0
    
    // Propiedades calculadas
    var nombreMes: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        dateFormatter.locale = Locale(identifier: "es_ES")
        return dateFormatter.string(from: fechaMes).capitalized
    }
}

struct Aporte: Identifiable, Codable {
    var id: String = UUID().uuidString
    var presupuestoId: String
    var usuario: String
    var monto: Double
    var comentario: String = ""
    var fecha: Date = Date()
}

struct DeudaPresupuesto: Identifiable, Codable {
    var id: String = UUID().uuidString
    var presupuestoId: String
    var categoria: String
    var montoTotal: Double
    var cuotasTotales: Int
    var tasaInteres: Double = 0.0
    var fechaInicio: Date
    var descripcion: String = ""
    
    // Propiedades calculadas
    var montoCuotaMensual: Double {
        if tasaInteres > 0 {
            // Cálculo con interés compuesto
            let tasaDecimal = tasaInteres / 100 / 12
            let factor = pow(1 + tasaDecimal, Double(cuotasTotales))
            return montoTotal * tasaDecimal * factor / (factor - 1)
        } else {
            // Sin interés
            return montoTotal / Double(cuotasTotales)
        }
    }
    
    var fechaFinal: Date {
        Calendar.current.date(byAdding: .month, value: cuotasTotales - 1, to: fechaInicio) ?? fechaInicio
    }
}