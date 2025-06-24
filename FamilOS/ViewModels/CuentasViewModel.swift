import Foundation
import SwiftUI
import Combine

class CuentasViewModel: ObservableObject {
    @Published var cuentas: [Cuenta] = []
    @Published var filtroCategorias: Set<String> = []
    @Published var filtroEstado: Cuenta.EstadoCuenta? = nil
    @Published var filtroFechaDesde: Date? = nil
    @Published var filtroFechaHasta: Date? = nil
    @Published var busquedaTexto: String = ""
    
    // Mock data para desarrollo
    func cargarDatosEjemplo() {
        let ahora = Date()
        let calendario = Calendar.current
        
        // Cuentas pagadas (mes pasado)
        let mesPasado = calendario.date(byAdding: .month, value: -1, to: ahora)!
        
        cuentas = [
            Cuenta(monto: 45000, proveedor: "CFE", fechaVencimiento: mesPasado, categoria: "Electricidad", creador: "Usuario", fechaEmision: mesPasado),
            
            Cuenta(monto: 350, proveedor: "Totalplay", fechaVencimiento: calendario.date(byAdding: .day, value: -5, to: ahora)!, categoria: "Internet", creador: "Usuario"),
            
            Cuenta(monto: 1200, proveedor: "Conagua", fechaVencimiento: calendario.date(byAdding: .day, value: 10, to: ahora)!, categoria: "Agua", creador: "Usuario"),
            
            Cuenta(monto: 6500, proveedor: "Arrendador", fechaVencimiento: calendario.date(byAdding: .day, value: 5, to: ahora)!, categoria: "Arriendo", creador: "Usuario"),
            
            Cuenta(monto: 890, proveedor: "Naturgy", fechaVencimiento: calendario.date(byAdding: .day, value: 15, to: ahora)!, categoria: "Gas", creador: "Usuario")
        ]
    }
    
    // Filtrar cuentas según los criterios establecidos
    var cuentasFiltradas: [Cuenta] {
        return cuentas.filter { cuenta in
            // Filtro por categoría
            if !filtroCategorias.isEmpty && !filtroCategorias.contains(cuenta.categoria) {
                return false
            }
            
            // Filtro por estado
            if let estado = filtroEstado, cuenta.estado != estado {
                return false
            }
            
            // Filtro por fecha
            if let fechaDesde = filtroFechaDesde, cuenta.fechaVencimiento < fechaDesde {
                return false
            }
            
            if let fechaHasta = filtroFechaHasta, cuenta.fechaVencimiento > fechaHasta {
                return false
            }
            
            // Filtro por texto
            if !busquedaTexto.isEmpty {
                let textoBusqueda = busquedaTexto.lowercased()
                return cuenta.nombre.lowercased().contains(textoBusqueda) ||
                       cuenta.proveedor.lowercased().contains(textoBusqueda) ||
                       cuenta.categoria.lowercased().contains(textoBusqueda) ||
                       cuenta.descripcion.lowercased().contains(textoBusqueda)
            }
            
            return true
        }
    }
    
    // Obtener categorías disponibles
    var categoriasDisponibles: [String] {
        return Array(Set(cuentas.map { $0.categoria })).sorted()
    }
    
    // Agregar nueva cuenta
    func agregarCuenta(_ cuenta: Cuenta) {
        cuentas.append(cuenta)
        // Aquí se implementaría la persistencia real
    }
    
    // Actualizar cuenta existente
    func actualizarCuenta(_ cuenta: Cuenta) {
        if let index = cuentas.firstIndex(where: { $0.id == cuenta.id }) {
            cuentas[index] = cuenta
            // Aquí se implementaría la persistencia real
        }
    }
    
    // Eliminar cuenta
    func eliminarCuenta(id: UUID) {
        cuentas.removeAll { $0.id == id }
        // Aquí se implementaría la persistencia real
    }
}