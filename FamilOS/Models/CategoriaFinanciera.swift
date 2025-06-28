import Foundation
import SwiftUI

// MARK: - Categoría Financiera
enum CategoriaFinanciera: String, CaseIterable, Identifiable {
    case luz = "Luz"
    case agua = "Agua"
    case internet = "Internet"
    case gas = "Gas"
    case mascotas = "Mascotas"
    case hogar = "Hogar"
    
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
        }
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
