import Foundation

struct Cuenta: Identifiable, Codable {
    var id: UUID = UUID()
    var monto: Double
    var proveedor: String
    var fechaEmision: Date?
    var fechaVencimiento: Date
    var categoria: String
    var descripcion: String
    var facturaURL: URL?
    var creador: String
    var nombre: String
    var estado: EstadoCuenta
    
    enum EstadoCuenta: String, Codable {
        case pagada
        case pendiente
        case vencida
    }
    
    init(monto: Double, proveedor: String, fechaVencimiento: Date, categoria: String, creador: String, fechaEmision: Date? = nil, descripcion: String = "", facturaURL: URL? = nil, nombre: String = "") {
        self.monto = monto
        self.proveedor = proveedor
        self.fechaEmision = fechaEmision
        self.fechaVencimiento = fechaVencimiento
        self.categoria = categoria
        self.descripcion = descripcion
        self.facturaURL = facturaURL
        self.creador = creador
        
        // Generar nombre automáticamente si no se proporciona
        if nombre.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            let fecha = fechaVencimiento
            self.nombre = "\(categoria) / \(dateFormatter.string(from: fecha))"
        } else {
            self.nombre = nombre
        }
        
        // Determinar estado basado en la fecha de vencimiento
        if let fechaEmision = fechaEmision, fechaEmision <= Date() {
            self.estado = .pagada
        } else if fechaVencimiento < Date() {
            self.estado = .vencida
        } else {
            self.estado = .pendiente
        }
    }
}