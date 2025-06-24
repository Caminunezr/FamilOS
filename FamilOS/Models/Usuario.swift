import Foundation

struct Usuario: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var nombre: String
    var email: String
    var contrasena: String
    var imagenPerfil: URL?
    var esPrincipal: Bool = false
    var fechaCreacion: Date = Date()
    
    // Información adicional opcional
    var telefono: String?
    var preferencias: Preferencias = Preferencias()
    
    static func == (lhs: Usuario, rhs: Usuario) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Para mock y testing
    static func usuarioDemo() -> Usuario {
        return Usuario(
            nombre: "Usuario Demo",
            email: "demo@familos.app",
            contrasena: "demo1234",
            esPrincipal: true
        )
    }
}

struct Preferencias: Codable {
    var temaOscuro: Bool = false
    var notificaciones: Bool = true
    var mostrarSaldos: Bool = true
    var moneda: String = "MXN"
}