import Foundation
import SwiftUI

// MARK: - Modelos para los items mostrados en las vistas
struct AporteItem: Identifiable {
    var id: String
    var usuario: String
    var monto: Double
    var montoUtilizado: Double
    var comentario: String
    var fecha: Date
    var saldoDisponible: Double {
        return monto - montoUtilizado
    }
    
    init(from aporte: Aporte) {
        self.id = aporte.id
        self.usuario = aporte.usuario
        self.monto = aporte.monto
        self.montoUtilizado = aporte.montoUtilizado
        self.comentario = aporte.comentario
        self.fecha = Date(timeIntervalSince1970: aporte.fecha)
    }
    
    // Para pruebas
    init(id: String = UUID().uuidString, usuario: String, monto: Double, montoUtilizado: Double = 0, comentario: String = "", fecha: Date = Date()) {
        self.id = id
        self.usuario = usuario
        self.monto = monto
        self.montoUtilizado = montoUtilizado
        self.comentario = comentario
        self.fecha = fecha
    }
}

// MARK: - Modelo de Deuda para la UI
struct DeudaItem: Identifiable, Codable {
    var id: String
    var descripcion: String
    var monto: Double
    var categoria: String
    var fechaRegistro: Date
    var esPagado: Bool
    var responsable: String
    
    init(from deuda: Deuda) {
        self.id = deuda.id
        self.descripcion = deuda.descripcion
        self.monto = deuda.monto
        self.categoria = deuda.categoria
        self.fechaRegistro = Date(timeIntervalSince1970: deuda.fechaRegistro)
        self.esPagado = deuda.esPagado
        self.responsable = deuda.responsable
    }
    
    // Para pruebas
    init(id: String = UUID().uuidString, descripcion: String, monto: Double, categoria: String = "General", fechaRegistro: Date = Date(), esPagado: Bool = false, responsable: String) {
        self.id = id
        self.descripcion = descripcion
        self.monto = monto
        self.categoria = categoria
        self.fechaRegistro = fechaRegistro
        self.esPagado = esPagado
        self.responsable = responsable
    }
}

// MARK: - Modelo de Gasto para la UI
struct GastoItem: Identifiable {
    var id: String
    var descripcion: String
    var monto: Double
    var categoria: String
    var fechaRegistro: Date
    var responsable: String
    
    init(from gasto: Gasto) {
        self.id = gasto.id
        self.descripcion = gasto.descripcion
        self.monto = gasto.monto
        self.categoria = gasto.categoria
        self.fechaRegistro = Date(timeIntervalSince1970: gasto.fechaRegistro)
        self.responsable = gasto.responsable
    }
    
    // Para pruebas
    init(id: String = UUID().uuidString, descripcion: String, monto: Double, categoria: String = "General", fechaRegistro: Date = Date(), responsable: String) {
        self.id = id
        self.descripcion = descripcion
        self.monto = monto
        self.categoria = categoria
        self.fechaRegistro = fechaRegistro
        self.responsable = responsable
    }
}

// MARK: - Modelo de Ahorro para la UI
struct AhorroItem: Identifiable {
    var id: String
    var descripcion: String
    var monto: Double
    var fechaRegistro: Date
    var responsable: String
    
    init(from ahorro: Ahorro) {
        self.id = ahorro.id
        self.descripcion = ahorro.descripcion
        self.monto = ahorro.monto
        self.fechaRegistro = Date(timeIntervalSince1970: ahorro.fechaRegistro)
        self.responsable = ahorro.responsable
    }
    
    // Para pruebas
    init(id: String = UUID().uuidString, descripcion: String, monto: Double, fechaRegistro: Date = Date(), responsable: String) {
        self.id = id
        self.descripcion = descripcion
        self.monto = monto
        self.fechaRegistro = fechaRegistro
        self.responsable = responsable
    }
}

// MARK: - Modelo de Resumen Financiero para la UI
struct ResumenFinanciero {
    var totalAportado: Double
    var totalGastado: Double
    var totalAhorrado: Double
    var totalDeuda: Double
    var saldoAportes: Double
    var porcentajeGastado: Double
    var porcentajeAhorrado: Double
    
    init(totalAportado: Double, totalGastado: Double, totalAhorrado: Double, totalDeuda: Double, 
         saldoAportes: Double, porcentajeGastado: Double, porcentajeAhorrado: Double) {
        self.totalAportado = totalAportado
        self.totalGastado = totalGastado
        self.totalAhorrado = totalAhorrado
        self.totalDeuda = totalDeuda
        self.saldoAportes = saldoAportes
        self.porcentajeGastado = porcentajeGastado
        self.porcentajeAhorrado = porcentajeAhorrado
    }
    
    // Constructor alternativo para compatibilidad
    init(totalAportes: Double = 0, totalGastos: Double = 0, totalDeudas: Double = 0, totalAhorros: Double = 0) {
        self.totalAportado = totalAportes
        self.totalGastado = totalGastos
        self.totalAhorrado = totalAhorros
        self.totalDeuda = totalDeudas
        self.saldoAportes = totalAportes - totalGastos - totalAhorros
        self.porcentajeGastado = totalAportes > 0 ? (totalGastos / totalAportes) * 100 : 0
        self.porcentajeAhorrado = totalAportes > 0 ? (totalAhorros / totalAportes) * 100 : 0
    }
}

// MARK: - Modelos base para datos

// Modelo base de Deuda
struct Deuda: Identifiable, Codable {
    var id: String = UUID().uuidString
    var descripcion: String
    var monto: Double
    var categoria: String = "General"
    var fechaRegistro: TimeInterval
    var esPagado: Bool = false
    var responsable: String
    
    init(descripcion: String, monto: Double, categoria: String = "General", responsable: String) {
        self.descripcion = descripcion
        self.monto = monto
        self.categoria = categoria
        self.fechaRegistro = Date().timeIntervalSince1970
        self.responsable = responsable
    }
}

// Modelo base de Gasto
struct Gasto: Identifiable, Codable {
    var id: String = UUID().uuidString
    var descripcion: String
    var monto: Double
    var categoria: String = "General"
    var fechaRegistro: TimeInterval
    var responsable: String
    
    init(descripcion: String, monto: Double, categoria: String = "General", responsable: String) {
        self.descripcion = descripcion
        self.monto = monto
        self.categoria = categoria
        self.fechaRegistro = Date().timeIntervalSince1970
        self.responsable = responsable
    }
}

// Modelo base de Ahorro
struct Ahorro: Identifiable, Codable {
    var id: String = UUID().uuidString
    var descripcion: String
    var monto: Double
    var fechaRegistro: TimeInterval
    var responsable: String
    
    init(descripcion: String, monto: Double, responsable: String) {
        self.descripcion = descripcion
        self.monto = monto
        self.fechaRegistro = Date().timeIntervalSince1970
        self.responsable = responsable
    }
}

// Enum para identificar tipos de transacciones
enum TipoTransaccion: String, Codable {
    case aporte = "aporte"
    case gasto = "gasto"
    case ahorro = "ahorro"
    case deuda = "deuda"
    case pago = "pago"
}

// Alias para compatibilidad
typealias Presupuesto = PresupuestoMensual
// Para compatibilidad con código existente
typealias DeudaPresupuesto = DeudaItem
