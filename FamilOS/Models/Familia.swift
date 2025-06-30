import Foundation

// MARK: - Familia
struct Familia: Identifiable, Codable {
    var id: String = UUID().uuidString
    var nombre: String
    var descripcion: String
    var fechaCreacion: Date
    var adminId: String // Usuario que creó la familia
    var miembros: [String: MiembroFamilia] // [userId: MiembroFamilia]
    var configuracion: ConfiguracionFamilia
    
    init(nombre: String, descripcion: String, adminId: String) {
        self.nombre = nombre
        self.descripcion = descripcion
        self.adminId = adminId
        self.fechaCreacion = Date()
        self.miembros = [:]
        self.configuracion = ConfiguracionFamilia()
    }
}

// MARK: - MiembroFamilia
struct MiembroFamilia: Identifiable, Codable {
    var id: String // userId
    var nombre: String
    var email: String
    var rol: RolFamiliar
    var fechaUnion: Date
    var activo: Bool
    var avatar: String? // URL o emoji
    var familiaId: String? // ID de la familia a la que pertenece
    
    init(id: String, nombre: String, email: String, rol: RolFamiliar = .miembro, familiaId: String? = nil) {
        self.id = id
        self.nombre = nombre
        self.email = email
        self.rol = rol
        self.fechaUnion = Date()
        self.activo = true
        self.avatar = nil
        self.familiaId = familiaId
    }
}

// MARK: - RolFamiliar
enum RolFamiliar: String, Codable, CaseIterable {
    case admin = "admin"           // Puede gestionar familia y todos los datos
    case miembro = "miembro"       // Puede ver y editar datos financieros
    case soloLectura = "solo_lectura" // Solo puede ver datos
    
    var descripcion: String {
        switch self {
        case .admin:
            return "Administrador"
        case .miembro:
            return "Miembro"
        case .soloLectura:
            return "Solo lectura"
        }
    }
    
    var permisos: PermisosFamiliares {
        switch self {
        case .admin:
            return PermisosFamiliares(
                puedeVerDatos: true,
                puedeEditarDatos: true,
                puedeAgregarMiembros: true,
                puedeEliminarMiembros: true,
                puedeConfigurarFamilia: true
            )
        case .miembro:
            return PermisosFamiliares(
                puedeVerDatos: true,
                puedeEditarDatos: true,
                puedeAgregarMiembros: false,
                puedeEliminarMiembros: false,
                puedeConfigurarFamilia: false
            )
        case .soloLectura:
            return PermisosFamiliares(
                puedeVerDatos: true,
                puedeEditarDatos: false,
                puedeAgregarMiembros: false,
                puedeEliminarMiembros: false,
                puedeConfigurarFamilia: false
            )
        }
    }
}

// MARK: - PermisosFamiliares
struct PermisosFamiliares: Codable {
    let puedeVerDatos: Bool
    let puedeEditarDatos: Bool
    let puedeAgregarMiembros: Bool
    let puedeEliminarMiembros: Bool
    let puedeConfigurarFamilia: Bool
}

// MARK: - ConfiguracionFamilia
struct ConfiguracionFamilia: Codable {
    var monedaPrincipal: String
    var requiereAprobacionGastos: Bool
    var limiteGastoSinAprobacion: Double
    var notificacionesActivas: Bool
    var compartirUbicacion: Bool
    
    init() {
        self.monedaPrincipal = "EUR"
        self.requiereAprobacionGastos = false
        self.limiteGastoSinAprobacion = 100.0
        self.notificacionesActivas = true
        self.compartirUbicacion = false
    }
}

// MARK: - InvitacionFamiliar
struct InvitacionFamiliar: Identifiable, Codable {
    var id: String = UUID().uuidString
    var familiaId: String
    var familiaName: String
    var invitadoPor: String // userId del que invita
    var invitadoEmail: String
    var fechaInvitacion: Date
    var fechaExpiracion: Date
    var estado: EstadoInvitacion
    var codigoInvitacion: String
    var fechaRespuesta: Date? // Fecha cuando se respondió la invitación
    var respondidoPor: String? // Usuario que respondió (útil para tracking)
    
    // Propiedad computada para compatibilidad
    var codigo: String {
        return codigoInvitacion
    }
    
    init(familiaId: String, familiaName: String, invitadoPor: String, invitadoEmail: String) {
        self.familiaId = familiaId
        self.familiaName = familiaName
        self.invitadoPor = invitadoPor
        self.invitadoEmail = invitadoEmail
        self.fechaInvitacion = Date()
        self.fechaExpiracion = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        self.estado = .pendiente
        self.codigoInvitacion = Self.generarCodigoInvitacion()
        self.fechaRespuesta = nil
        self.respondidoPor = nil
    }
    
    private static func generarCodigoInvitacion() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
}

// MARK: - EstadoInvitacion
enum EstadoInvitacion: String, Codable, CaseIterable {
    case pendiente = "pendiente"
    case aceptada = "aceptada"
    case rechazada = "rechazada"
    case expirada = "expirada"
    
    var descripcion: String {
        switch self {
        case .pendiente:
            return "Pendiente"
        case .aceptada:
            return "Aceptada"
        case .rechazada:
            return "Rechazada"
        case .expirada:
            return "Expirada"
        }
    }
}
