import Foundation
import SwiftUI

struct Cuenta: Identifiable, Codable {
    var id: UUID = UUID()
    var monto: Double
    var proveedor: String
    var fechaEmision: Date?
    var fechaVencimiento: Date
    var categoria: String
    var descripcion: String
    var facturaURL: URL?
    var comprobanteURL: URL?
    var creador: String
    var nombre: String
    var estado: EstadoCuenta
    var fechaPago: Date?
    var montoPagado: Double?
    
    enum EstadoCuenta: String, Codable, CaseIterable {
        case pagada = "Pagada"
        case pendiente = "Pendiente"
        case vencida = "Vencida"
        
        var color: String {
            switch self {
            case .pagada: return "green"
            case .pendiente: return "blue"
            case .vencida: return "red"
            }
        }
    }
    
    // Categorías del sistema según README
    enum CategoriasCuentas: String, CaseIterable {
        case luz = "Luz"
        case agua = "Agua"
        case gas = "Gas"
        case internet = "Internet"
        case arriendo = "Arriendo"
        case gastoComun = "Gasto Común"
        case seguros = "Seguros"
        case otros = "Otros"
        
        var icono: String {
            switch self {
            case .luz: return "lightbulb"
            case .agua: return "drop"
            case .gas: return "flame"
            case .internet: return "wifi"
            case .arriendo: return "house"
            case .gastoComun: return "building.2"
            case .seguros: return "shield"
            case .otros: return "ellipsis.circle"
            }
        }
        
        // Proveedores organizados por categoría (según README)
        var proveedoresComunes: [String] {
            switch self {
            case .luz: return ["CFE", "Enel", "Naturgy", "Total Energías"]
            case .agua: return ["Conagua", "Aguas Andinas", "ESSM"]
            case .gas: return ["Naturgy", "Lipigas", "Total Gas"]
            case .internet: return ["Totalplay", "Izzi", "Megacable", "Telmex"]
            case .arriendo: return ["Propietario", "Inmobiliaria"]
            case .gastoComun: return ["Administración", "Condominio"]
            case .seguros: return ["GNP", "Mapfre", "AXA", "Zurich"]
            case .otros: return ["Varios", "Otros"]
            }
        }
    }
    
    init(monto: Double, proveedor: String, fechaVencimiento: Date, categoria: String, creador: String, fechaEmision: Date? = nil, descripcion: String = "", facturaURL: URL? = nil, comprobanteURL: URL? = nil, nombre: String = "", fechaPago: Date? = nil, montoPagado: Double? = nil) {
        self.monto = monto
        self.proveedor = proveedor
        self.fechaEmision = fechaEmision
        self.fechaVencimiento = fechaVencimiento
        self.categoria = categoria
        self.descripcion = descripcion
        self.facturaURL = facturaURL
        self.comprobanteURL = comprobanteURL
        self.creador = creador
        self.fechaPago = fechaPago
        self.montoPagado = montoPagado
        
        // Generar nombre automáticamente si no se proporciona
        if nombre.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM yyyy"
            let fecha = fechaVencimiento
            self.nombre = "\(categoria) / \(dateFormatter.string(from: fecha))"
        } else {
            self.nombre = nombre
        }
        
        // Determinar estado basado en la fecha de vencimiento y pago
        if fechaPago != nil {
            self.estado = .pagada
        } else if fechaVencimiento < Date() {
            self.estado = .vencida
        } else {
            self.estado = .pendiente
        }
    }
    
    // Computed properties para el dashboard
    var estaVencida: Bool {
        return fechaVencimiento < Date() && estado != .pagada
    }
    
    var diasParaVencimiento: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: fechaVencimiento).day ?? 0
    }
    
    var mesVencimiento: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: fechaVencimiento)
    }
}

// MARK: - Extensiones para categorías
extension Cuenta {
    var categoriaFinanciera: CategoriaFinanciera? {
        return CategoriaFinanciera.allCases.first { $0.rawValue == categoria }
    }
    
    mutating func setCategoriaFinanciera(_ nuevaCategoria: CategoriaFinanciera) {
        self.categoria = nuevaCategoria.rawValue
    }
    
    var iconoCategoria: String {
        return categoriaFinanciera?.icono ?? "questionmark.circle.fill"
    }
    
    var colorCategoria: Color {
        return categoriaFinanciera?.colorPrimario ?? .gray
    }
    
    var iconoProveedor: String {
        return proveedor.iconoProveedor
    }
}