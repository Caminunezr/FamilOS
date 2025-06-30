import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseService: ObservableObject {
    private let database = Database.database().reference()
    private var listeners: [DatabaseHandle] = []
    
    deinit {
        removeAllListeners()
    }
    
    private func removeAllListeners() {
        listeners.forEach { handle in
            database.removeObserver(withHandle: handle)
        }
        listeners.removeAll()
    }
    
    // MARK: - Usuario Methods
    
    func guardarUsuario(_ usuario: Usuario, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let userData = try JSONEncoder().encode(usuario)
            let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]
            
            database.child("usuarios").child(usuario.id).setValue(userDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func cargarUsuario(userId: String, completion: @escaping (Result<Usuario, Error>) -> Void) {
        database.child("usuarios").child(userId).observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.failure(NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])))
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let usuario = try JSONDecoder().decode(Usuario.self, from: jsonData)
                completion(.success(usuario))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Familia Methods
    
    func crearFamilia(_ familia: Familia, completion: @escaping (Result<Familia, Error>) -> Void) {
        do {
            let familiaData = try JSONEncoder().encode(familia)
            let familiaDict = try JSONSerialization.jsonObject(with: familiaData) as? [String: Any] ?? [:]
            
            database.child("familias").child(familia.id).setValue(familiaDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(familia))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func cargarFamilia(familiaId: String, completion: @escaping (Result<Familia, Error>) -> Void) {
        database.child("familias").child(familiaId).observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.failure(NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Familia no encontrada"])))
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let familia = try JSONDecoder().decode(Familia.self, from: jsonData)
                completion(.success(familia))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func observarFamilia(familiaId: String, completion: @escaping (Result<Familia, Error>) -> Void) {
        let handle = database.child("familias").child(familiaId).observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.failure(NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Familia no encontrada"])))
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let familia = try JSONDecoder().decode(Familia.self, from: jsonData)
                completion(.success(familia))
            } catch {
                completion(.failure(error))
            }
        }
        listeners.append(handle)
    }
    
    func agregarMiembroAFamilia(familiaId: String, miembro: MiembroFamilia, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let miembroData = try JSONEncoder().encode(miembro)
            let miembroDict = try JSONSerialization.jsonObject(with: miembroData) as? [String: Any] ?? [:]
            
            database.child("familias").child(familiaId).child("miembros").child(miembro.id).setValue(miembroDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // También actualizar el usuario con la familiaId
                    self.database.child("usuarios").child(miembro.id).child("familiaId").setValue(familiaId)
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Cuentas Familiares
    
    func cargarCuentasFamiliares(familiaId: String, completion: @escaping (Result<[Cuenta], Error>) -> Void) {
        database.child("familias").child(familiaId).child("cuentas").observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay cuentas aún
                return
            }
            
            var cuentas: [Cuenta] = []
            for (_, cuentaData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: cuentaData)
                    let cuenta = try JSONDecoder().decode(Cuenta.self, from: jsonData)
                    cuentas.append(cuenta)
                } catch {
                    print("Error decodificando cuenta: \(error)")
                }
            }
            completion(.success(cuentas))
        }
    }
    
    func observarCuentasFamiliares(familiaId: String, completion: @escaping (Result<[Cuenta], Error>) -> Void) {
        let handle = database.child("familias").child(familiaId).child("cuentas").observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay cuentas aún
                return
            }
            
            var cuentas: [Cuenta] = []
            for (_, cuentaData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: cuentaData)
                    let cuenta = try JSONDecoder().decode(Cuenta.self, from: jsonData)
                    cuentas.append(cuenta)
                } catch {
                    print("Error decodificando cuenta: \(error)")
                }
            }
            completion(.success(cuentas))
        }
        listeners.append(handle)
    }
    
    func guardarCuentaFamiliar(familiaId: String, cuenta: Cuenta, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let cuentaData = try JSONEncoder().encode(cuenta)
            let cuentaDict = try JSONSerialization.jsonObject(with: cuentaData) as? [String: Any] ?? [:]
            
            database.child("familias").child(familiaId).child("cuentas").child(cuenta.id).setValue(cuentaDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func eliminarCuentaFamiliar(familiaId: String, cuentaId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        database.child("familias").child(familiaId).child("cuentas").child(cuentaId).removeValue { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Presupuestos Familiares
    
    func cargarPresupuestosFamiliares(familiaId: String, completion: @escaping (Result<[Presupuesto], Error>) -> Void) {
        database.child("familias").child(familiaId).child("presupuestos").observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay presupuestos aún
                return
            }
            
            var presupuestos: [Presupuesto] = []
            for (_, presupuestoData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: presupuestoData)
                    let presupuesto = try JSONDecoder().decode(Presupuesto.self, from: jsonData)
                    presupuestos.append(presupuesto)
                } catch {
                    print("Error decodificando presupuesto: \(error)")
                }
            }
            completion(.success(presupuestos))
        }
    }
    
    func observarPresupuestosFamiliares(familiaId: String, completion: @escaping (Result<[Presupuesto], Error>) -> Void) {
        let handle = database.child("familias").child(familiaId).child("presupuestos").observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay presupuestos aún
                return
            }
            
            var presupuestos: [Presupuesto] = []
            for (_, presupuestoData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: presupuestoData)
                    let presupuesto = try JSONDecoder().decode(Presupuesto.self, from: jsonData)
                    presupuestos.append(presupuesto)
                } catch {
                    print("Error decodificando presupuesto: \(error)")
                }
            }
            completion(.success(presupuestos))
        }
        listeners.append(handle)
    }
    
    func guardarPresupuestoFamiliar(familiaId: String, presupuesto: Presupuesto, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let presupuestoData = try JSONEncoder().encode(presupuesto)
            let presupuestoDict = try JSONSerialization.jsonObject(with: presupuestoData) as? [String: Any] ?? [:]
            
            database.child("familias").child(familiaId).child("presupuestos").child(presupuesto.id).setValue(presupuestoDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Aportes Familiares
    
    func cargarAportesFamiliares(familiaId: String, completion: @escaping (Result<[Aporte], Error>) -> Void) {
        database.child("familias").child(familiaId).child("aportes").observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay aportes aún
                return
            }
            
            var aportes: [Aporte] = []
            for (_, aporteData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: aporteData)
                    let aporte = try JSONDecoder().decode(Aporte.self, from: jsonData)
                    aportes.append(aporte)
                } catch {
                    print("Error decodificando aporte: \(error)")
                }
            }
            completion(.success(aportes))
        }
    }
    
    func observarAportesFamiliares(familiaId: String, completion: @escaping (Result<[Aporte], Error>) -> Void) {
        let handle = database.child("familias").child(familiaId).child("aportes").observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay aportes aún
                return
            }
            
            var aportes: [Aporte] = []
            for (_, aporteData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: aporteData)
                    let aporte = try JSONDecoder().decode(Aporte.self, from: jsonData)
                    aportes.append(aporte)
                } catch {
                    print("Error decodificando aporte: \(error)")
                }
            }
            completion(.success(aportes))
        }
        listeners.append(handle)
    }
    
    func guardarAporteFamiliar(familiaId: String, aporte: Aporte, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let aporteData = try JSONEncoder().encode(aporte)
            let aporteDict = try JSONSerialization.jsonObject(with: aporteData) as? [String: Any] ?? [:]
            
            database.child("familias").child(familiaId).child("aportes").child(aporte.id).setValue(aporteDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Deudas Familiares
    
    func cargarDeudasFamiliares(familiaId: String, completion: @escaping (Result<[Deuda], Error>) -> Void) {
        database.child("familias").child(familiaId).child("deudas").observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay deudas aún
                return
            }
            
            var deudas: [Deuda] = []
            for (_, deudaData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: deudaData)
                    let deuda = try JSONDecoder().decode(Deuda.self, from: jsonData)
                    deudas.append(deuda)
                } catch {
                    print("Error decodificando deuda: \(error)")
                }
            }
            completion(.success(deudas))
        }
    }
    
    func observarDeudasFamiliares(familiaId: String, completion: @escaping (Result<[Deuda], Error>) -> Void) {
        let handle = database.child("familias").child(familiaId).child("deudas").observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay deudas aún
                return
            }
            
            var deudas: [Deuda] = []
            for (_, deudaData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: deudaData)
                    let deuda = try JSONDecoder().decode(Deuda.self, from: jsonData)
                    deudas.append(deuda)
                } catch {
                    print("Error decodificando deuda: \(error)")
                }
            }
            completion(.success(deudas))
        }
        listeners.append(handle)
    }
    
    func guardarDeudaFamiliar(familiaId: String, deuda: Deuda, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let deudaData = try JSONEncoder().encode(deuda)
            let deudaDict = try JSONSerialization.jsonObject(with: deudaData) as? [String: Any] ?? [:]
            
            database.child("familias").child(familiaId).child("deudas").child(deuda.id).setValue(deudaDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Invitaciones
    
    func crearInvitacion(_ invitacion: InvitacionFamiliar, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let invitacionData = try JSONEncoder().encode(invitacion)
            let invitacionDict = try JSONSerialization.jsonObject(with: invitacionData) as? [String: Any] ?? [:]
            
            database.child("invitaciones").child(invitacion.id).setValue(invitacionDict) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func cargarInvitacionesPendientes(email: String, completion: @escaping (Result<[InvitacionFamiliar], Error>) -> Void) {
        database.child("invitaciones").queryOrdered(byChild: "invitadoEmail").queryEqual(toValue: email).observeSingleEvent(of: .value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion(.success([])) // No hay invitaciones
                return
            }
            
            var invitaciones: [InvitacionFamiliar] = []
            for (_, invitacionData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: invitacionData)
                    let invitacion = try JSONDecoder().decode(InvitacionFamiliar.self, from: jsonData)
                    if invitacion.estado == .pendiente && invitacion.fechaExpiracion > Date() {
                        invitaciones.append(invitacion)
                    }
                } catch {
                    print("Error decodificando invitación: \(error)")
                }
            }
            completion(.success(invitaciones))
        }
    }
    
    func aceptarInvitacion(invitacionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        database.child("invitaciones").child(invitacionId).child("estado").setValue(EstadoInvitacion.aceptada.rawValue) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
