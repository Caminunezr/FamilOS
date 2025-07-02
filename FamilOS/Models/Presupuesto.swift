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
    var montoUtilizado: Double = 0.0  // FASE 1: Nuevo campo para tracking
    var comentario: String = ""
    var fecha: TimeInterval = Date().timeIntervalSince1970
    
    // MARK: - Codable customizado para manejar campos opcionales
    enum CodingKeys: String, CodingKey {
        case id, presupuestoId, usuario, monto, montoUtilizado, comentario, fecha
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        presupuestoId = try container.decode(String.self, forKey: .presupuestoId)
        usuario = try container.decode(String.self, forKey: .usuario)
        monto = try container.decode(Double.self, forKey: .monto)
        
        // montoUtilizado es opcional para compatibilidad con datos existentes
        montoUtilizado = try container.decodeIfPresent(Double.self, forKey: .montoUtilizado) ?? 0.0
        
        comentario = try container.decodeIfPresent(String.self, forKey: .comentario) ?? ""
        fecha = try container.decode(TimeInterval.self, forKey: .fecha)
    }
    
    // FASE 1: Propiedades calculadas para gestión de saldos
    var saldoDisponible: Double {
        return monto - montoUtilizado
    }
    
    var porcentajeUtilizado: Double {
        guard monto > 0 else { return 0 }
        return (montoUtilizado / monto) * 100
    }
    
    var tieneDisponible: Bool {
        return saldoDisponible > 0
    }
    
    // Computed property para trabajar con Date en la UI
    var fechaDate: Date {
        get { Date(timeIntervalSince1970: fecha) }
        set { fecha = newValue.timeIntervalSince1970 }
    }
    
    // Inicializadores para compatibilidad
    init(presupuestoId: String, usuario: String, monto: Double, comentario: String = "") {
        self.presupuestoId = presupuestoId
        self.usuario = usuario
        self.monto = monto
        self.montoUtilizado = 0.0
        self.comentario = comentario
        self.fecha = Date().timeIntervalSince1970
    }
    
    // FASE 1: Método para usar monto del aporte
    mutating func usarMonto(_ cantidad: Double) -> Bool {
        guard cantidad > 0 && cantidad <= saldoDisponible else { return false }
        montoUtilizado += cantidad
        return true
    }
    
    // FASE 1: Método para revertir uso (en caso de error)
    mutating func revertirUso(_ cantidad: Double) -> Bool {
        guard cantidad > 0 && cantidad <= montoUtilizado else { return false }
        montoUtilizado -= cantidad
        return true
    }
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

// MARK: - FASE 1: Modelo de Transacción con referencia a aportes
struct TransaccionPago: Identifiable, Codable {
    var id: String = UUID().uuidString
    var cuentaId: String
    var monto: Double
    var fecha: TimeInterval = Date().timeIntervalSince1970
    var usuario: String
    var descripcion: String
    var tipo: TipoTransaccion = .pago
    
    // FASE 1: Nuevos campos para tracking de aportes utilizados
    var aportesUtilizados: [AporteUtilizado] = []
    
    // Computed property para trabajar con Date en la UI
    var fechaDate: Date {
        get { Date(timeIntervalSince1970: fecha) }
        set { fecha = newValue.timeIntervalSince1970 }
    }
    
    init(cuentaId: String, monto: Double, usuario: String, descripcion: String = "Pago de cuenta") {
        self.cuentaId = cuentaId
        self.monto = monto
        self.usuario = usuario
        self.descripcion = descripcion
        self.fecha = Date().timeIntervalSince1970
    }
}

struct AporteUtilizado: Codable {
    let aporteId: String
    let usuarioAporte: String
    let montoUtilizado: Double
    
    init(aporteId: String, usuarioAporte: String, montoUtilizado: Double) {
        self.aporteId = aporteId
        self.usuarioAporte = usuarioAporte
        self.montoUtilizado = montoUtilizado
    }
}

enum TipoTransaccion: String, Codable {
    case pago = "pago"
    case reembolso = "reembolso"
    case transferencia = "transferencia"
}