import Foundation
import SwiftUI

// MARK: - Categoría Financiera
enum CategoriaFinanciera: String, CaseIterable, Identifiable {
    // Gastos
    case luz = "Luz"
    case agua = "Agua"
    case internet = "Internet"
    case gas = "Gas"
    case mascotas = "Mascotas"
    case hogar = "Hogar"
    
    // Ingresos
    case sueldo = "Sueldo"
    case bonos = "Bonos"
    case ventas = "Ventas"
    case servicios = "Servicios"
    case inversiones = "Inversiones"
    case varios = "Varios"
    case vivienda = "Vivienda"
    
    var id: String { self.rawValue }
    
    var proveedoresComunes: [String] {
        switch self {
        case .luz:
            return ["Enel", "CGE", "Frontel", "Saesa", "Elecda"]
        case .agua:
            return ["Aguas Andinas", "ESVAL", "ESSBIO", "Nuevosur", "Aguas del Valle"]
        case .internet:
            return ["Mundo", "Movistar", "WOM", "Claro", "GTD", "VTR"]
        case .gas:
            return ["Lipigas", "Gasco", "Abastible", "Metrogas"]
        case .mascotas:
            return ["Comida Gato", "Comida Perro", "Veterinario", "Accesorios", "Medicamentos", "Peluquería"]
        case .hogar:
            return ["Feria", "Útiles de Aseo", "Arreglos Casa", "Electrodomésticos", "Ferretería", "Supermercado"]
        case .sueldo:
            return ["Sueldo Principal", "Sueldo Secundario", "Trabajo Temporal", "Freelance"]
        case .bonos:
            return ["Bono Mensual", "Comisiones", "Aguinaldo", "Gratificación", "Bono Extra"]
        case .ventas:
            return ["Venta Online", "Venta Ocasional", "Negocio Personal", "Marketplace"]
        case .servicios:
            return ["Consultoría", "Servicios Profesionales", "Trabajo Extra", "Proyecto"]
        case .inversiones:
            return ["Dividendos", "Intereses", "Criptomonedas", "Fondos", "Acciones"]
        case .varios:
            return ["Regalo", "Reembolso", "Devolución", "Préstamo", "Otros"]
        case .vivienda:
            return ["Arriendo", "Venta Propiedad", "Renta", "Alquiler"]
        }
    }
    
    var icono: String {
        switch self {
        case .luz: return "lightbulb.fill"
        case .agua: return "drop.fill"
        case .internet: return "wifi"
        case .gas: return "flame.fill"
        case .mascotas: return "pawprint.fill"
        case .hogar: return "house.fill"
        case .sueldo: return "banknote.fill"
        case .bonos: return "star.fill"
        case .ventas: return "cart.fill"
        case .servicios: return "wrench.and.screwdriver.fill"
        case .inversiones: return "chart.line.uptrend.xyaxis"
        case .varios: return "ellipsis.circle.fill"
        case .vivienda: return "building.2.fill"
        }
    }
    
    var colorPrimario: Color {
        switch self {
        case .luz: return .yellow
        case .agua: return .blue
        case .internet: return .purple
        case .gas: return .orange
        case .mascotas: return .brown
        case .hogar: return .green
        case .sueldo: return .blue
        case .bonos: return .yellow
        case .ventas: return .orange
        case .servicios: return .purple
        case .inversiones: return .green
        case .varios: return .gray
        case .vivienda: return .brown
        }
    }
    
    var descripcion: String {
        switch self {
        case .luz: return "Servicios eléctricos"
        case .agua: return "Servicios de agua potable"
        case .internet: return "Internet y telefonía"
        case .gas: return "Gas licuado y natural"
        case .mascotas: return "Gastos de mascotas"
        case .hogar: return "Gastos varios del hogar"
        case .sueldo: return "Ingresos por trabajo"
        case .bonos: return "Bonificaciones y extras"
        case .ventas: return "Ingresos por ventas"
        case .servicios: return "Servicios profesionales"
        case .inversiones: return "Retornos de inversión"
        case .varios: return "Ingresos varios"
        case .vivienda: return "Ingresos por propiedades"
        }
    }
    
    var displayName: String {
        return rawValue
    }
    
    var ejemploProveedor: String {
        return proveedoresComunes.first ?? ""
    }
}

// MARK: - Helper para auto-sugerencias
extension CategoriaFinanciera {
    static func sugerirCategoria(basadoEn nombre: String) -> CategoriaFinanciera? {
        let nombreLower = nombre.lowercased()
        
        for categoria in CategoriaFinanciera.allCases {
            // Buscar en el nombre de la categoría
            if nombreLower.contains(categoria.rawValue.lowercased()) {
                return categoria
            }
            
            // Buscar en los proveedores
            for proveedor in categoria.proveedoresComunes {
                if nombreLower.contains(proveedor.lowercased()) {
                    return categoria
                }
            }
        }
        
        return nil
    }
    
    func sugerirProveedor(basadoEn nombre: String) -> String? {
        let nombreLower = nombre.lowercased()
        
        for proveedor in proveedoresComunes {
            if nombreLower.contains(proveedor.lowercased()) {
                return proveedor
            }
        }
        
        return nil
    }
}

// MARK: - Extensiones para iconos de proveedores específicos
extension String {
    var iconoProveedor: String {
        switch self.lowercased() {
        // Electricidad
        case "enel": return "bolt.fill"
        case "cge": return "bolt.circle.fill"
        case "frontel": return "bolt.horizontal.fill"
        
        // Agua
        case "aguas andinas": return "drop.circle.fill"
        case "esval": return "drop.triangle.fill"
        case "essbio": return "drop.fill"
        
        // Internet
        case "movistar": return "antenna.radiowaves.left.and.right"
        case "wom": return "wifi.circle.fill"
        case "claro": return "network"
        case "mundo": return "globe"
        
        // Gas
        case "lipigas": return "flame.circle.fill"
        case "gasco": return "flame.fill"
        case "abastible": return "flame"
        
        // Mascotas
        case "veterinario": return "cross.case.fill"
        case "comida gato": return "cat.fill"
        case "comida perro": return "dog.fill"
        
        // Hogar
        case "feria": return "basket.fill"
        case "supermercado": return "cart.fill"
        case "ferretería": return "hammer.fill"
        
        default: return "building.2.fill"
        }
    }
}
