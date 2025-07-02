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
    
    func crearUsuario(_ usuario: Usuario) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let userData = try JSONEncoder().encode(usuario)
                let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]
                
                database.child("usuarios").child(usuario.id).setValue(userDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerUsuario(uid: String) async throws -> Usuario? {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("usuarios").child(uid).observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let usuario = try JSONDecoder().decode(Usuario.self, from: jsonData)
                    continuation.resume(returning: usuario)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Familia Methods
    
    func crearFamilia(_ familia: Familia) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let familiaData = try JSONEncoder().encode(familia)
                let familiaDict = try JSONSerialization.jsonObject(with: familiaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familia.id).setValue(familiaDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerFamilia(familiaId: String) async throws -> Familia {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(throwing: NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Familia no encontrada"]))
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let familia = try JSONDecoder().decode(Familia.self, from: jsonData)
                    continuation.resume(returning: familia)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func obtenerMembresiasUsuario(usuarioId: String) async throws -> [MiembroFamilia] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").observeSingleEvent(of: .value) { snapshot in
                guard let familias = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var membresias: [MiembroFamilia] = []
                
                for (familiaId, familiaData) in familias {
                    if let familiaDict = familiaData as? [String: Any],
                       let miembros = familiaDict["miembros"] as? [String: Any],
                       let miembroData = miembros[usuarioId] as? [String: Any] {
                        
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: miembroData)
                            var miembro = try JSONDecoder().decode(MiembroFamilia.self, from: jsonData)
                            // Asegurarnos de que el miembro tenga el familiaId correcto
                            miembro.familiaId = familiaId
                            membresias.append(miembro)
                        } catch {
                            print("Error decodificando miembro: \(error)")
                        }
                    }
                }
                
                continuation.resume(returning: membresias)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func agregarMiembroFamilia(familiaId: String, miembro: MiembroFamilia) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let miembroData = try JSONEncoder().encode(miembro)
                let miembroDict = try JSONSerialization.jsonObject(with: miembroData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("miembros").child(miembro.id).setValue(miembroDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        // También actualizar el usuario con la familiaId
                        self.database.child("usuarios").child(miembro.id).child("familiaId").setValue(familiaId)
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Cuentas Familiares
    
    func obtenerCuentasFamilia(familiaId: String) async throws -> [Cuenta] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("cuentas").observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
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
                continuation.resume(returning: cuentas)
            }
        }
    }
    
    func crearCuenta(_ cuenta: Cuenta, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let cuentaData = try JSONEncoder().encode(cuenta)
                let cuentaDict = try JSONSerialization.jsonObject(with: cuentaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("cuentas").child(cuenta.id).setValue(cuentaDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func actualizarCuenta(_ cuenta: Cuenta, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let cuentaData = try JSONEncoder().encode(cuenta)
                let cuentaDict = try JSONSerialization.jsonObject(with: cuentaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("cuentas").child(cuenta.id).setValue(cuentaDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func eliminarCuenta(cuentaId: String, familiaId: String) async throws {
        print("🗑️ Eliminando cuenta: \(cuentaId) de familia: \(familiaId)")
        
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("cuentas").child(cuentaId).removeValue { error, _ in
                if let error = error {
                    print("❌ Error eliminando cuenta: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Cuenta eliminada exitosamente: \(cuentaId)")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Presupuestos Familiares
    
    func obtenerPresupuestosFamilia(familiaId: String) async throws -> [PresupuestoMensual] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("presupuestos").observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var presupuestos: [PresupuestoMensual] = []
                for (_, presupuestoData) in data {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: presupuestoData)
                        let presupuesto = try JSONDecoder().decode(PresupuestoMensual.self, from: jsonData)
                        presupuestos.append(presupuesto)
                    } catch {
                        print("Error decodificando presupuesto: \(error)")
                    }
                }
                continuation.resume(returning: presupuestos)
            }
        }
    }
    
    func crearPresupuesto(_ presupuesto: PresupuestoMensual, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let presupuestoData = try JSONEncoder().encode(presupuesto)
                let presupuestoDict = try JSONSerialization.jsonObject(with: presupuestoData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("presupuestos").child(presupuesto.id).setValue(presupuestoDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Aportes Familiares
    
    func obtenerAportesFamilia(familiaId: String) async throws -> [Aporte] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("aportes").observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
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
                continuation.resume(returning: aportes)
            }
        }
    }
    
    func crearAporte(_ aporte: Aporte, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let aporteData = try JSONEncoder().encode(aporte)
                let aporteDict = try JSONSerialization.jsonObject(with: aporteData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("aportes").child(aporte.id).setValue(aporteDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // FASE 1: Método para actualizar aporte existente
    func actualizarAporte(familiaId: String, aporte: Aporte) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let aporteData = try JSONEncoder().encode(aporte)
                let aporteDict = try JSONSerialization.jsonObject(with: aporteData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("aportes").child(aporte.id).updateChildValues(aporteDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func eliminarAporte(aporteId: String, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("aportes").child(aporteId).removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Deudas Familiares
    
    func obtenerDeudasFamilia(familiaId: String) async throws -> [DeudaPresupuesto] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("deudas").observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var deudas: [DeudaPresupuesto] = []
                for (_, deudaData) in data {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: deudaData)
                        let deuda = try JSONDecoder().decode(DeudaPresupuesto.self, from: jsonData)
                        deudas.append(deuda)
                    } catch {
                        print("Error decodificando deuda: \(error)")
                    }
                }
                continuation.resume(returning: deudas)
            }
        }
    }
    
    func crearDeuda(_ deuda: DeudaPresupuesto, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let deudaData = try JSONEncoder().encode(deuda)
                let deudaDict = try JSONSerialization.jsonObject(with: deudaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("deudas").child(deuda.id).setValue(deudaDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func actualizarDeuda(_ deuda: DeudaPresupuesto, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let deudaData = try JSONEncoder().encode(deuda)
                let deudaDict = try JSONSerialization.jsonObject(with: deudaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("deudas").child(deuda.id).setValue(deudaDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func eliminarDeuda(deudaId: String, familiaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("deudas").child(deudaId).removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Invitaciones
    
    func buscarInvitacionPorCodigo(_ codigo: String) async throws -> InvitacionFamiliar? {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("invitaciones").queryOrdered(byChild: "codigoInvitacion").queryEqual(toValue: codigo).observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any],
                      let invitacionData = data.values.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: invitacionData)
                    let invitacion = try JSONDecoder().decode(InvitacionFamiliar.self, from: jsonData)
                    continuation.resume(returning: invitacion)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func actualizarInvitacion(_ invitacion: InvitacionFamiliar) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let invitacionData = try JSONEncoder().encode(invitacion)
                let invitacionDict = try JSONSerialization.jsonObject(with: invitacionData) as? [String: Any] ?? [:]
                
                database.child("invitaciones").child(invitacion.id).setValue(invitacionDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func crearInvitacion(_ invitacion: InvitacionFamiliar) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let invitacionData = try JSONEncoder().encode(invitacion)
                let invitacionDict = try JSONSerialization.jsonObject(with: invitacionData) as? [String: Any] ?? [:]
                
                database.child("invitaciones").child(invitacion.id).setValue(invitacionDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func eliminarInvitacion(_ invitacionId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("invitaciones").child(invitacionId).removeValue { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // Método optimizado para obtener familia del usuario
    func obtenerFamiliaDelUsuario(usuarioId: String) async throws -> (Familia?, MiembroFamilia?) {
        return try await withCheckedThrowingContinuation { continuation in
            // Primero obtener el usuario para conseguir su familiaId
            database.child("usuarios").child(usuarioId).observeSingleEvent(of: .value) { snapshot in
                guard let userData = snapshot.value as? [String: Any],
                      let familiaId = userData["familiaId"] as? String else {
                    // Usuario sin familia asignada
                    continuation.resume(returning: (nil, nil))
                    return
                }
                
                // Ahora obtener la familia y el miembro en paralelo
                let group = DispatchGroup()
                var familia: Familia?
                var miembro: MiembroFamilia?
                var error: Error?
                
                // Obtener familia
                group.enter()
                self.database.child("familias").child(familiaId).observeSingleEvent(of: .value) { familiaSnapshot in
                    defer { group.leave() }
                    
                    guard let familiaData = familiaSnapshot.value as? [String: Any] else {
                        error = NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Familia no encontrada"])
                        return
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: familiaData)
                        familia = try JSONDecoder().decode(Familia.self, from: jsonData)
                    } catch {
                        print("Error decodificando familia: \(error)")
                    }
                }
                
                // Obtener miembro
                group.enter()
                self.database.child("familias").child(familiaId).child("miembros").child(usuarioId).observeSingleEvent(of: .value) { miembroSnapshot in
                    defer { group.leave() }
                    
                    guard let miembroData = miembroSnapshot.value as? [String: Any] else {
                        error = NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Miembro no encontrado"])
                        return
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: miembroData)
                        miembro = try JSONDecoder().decode(MiembroFamilia.self, from: jsonData)
                        miembro?.familiaId = familiaId
                    } catch {
                        print("Error decodificando miembro: \(error)")
                    }
                }
                
                group.notify(queue: .main) {
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: (familia, miembro))
                    }
                }
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - FASE 1: Transacciones de Pago con Aportes
    
    func crearTransaccionPago(familiaId: String, transaccion: TransaccionPago) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let transaccionData = try JSONEncoder().encode(transaccion)
                let transaccionDict = try JSONSerialization.jsonObject(with: transaccionData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("transacciones").child(transaccion.id).setValue(transaccionDict) { error, _ in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerTransacciones(familiaId: String) async throws -> [TransaccionPago] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("transacciones").observeSingleEvent(of: .value) { snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var transacciones: [TransaccionPago] = []
                for (_, transaccionData) in data {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: transaccionData)
                        let transaccion = try JSONDecoder().decode(TransaccionPago.self, from: jsonData)
                        transacciones.append(transaccion)
                    } catch {
                        print("Error decodificando transacción: \(error)")
                    }
                }
                continuation.resume(returning: transacciones)
            }
        }
    }
    
    // MARK: - Observadores en tiempo real
    
    func observarCuentas(familiaId: String, completion: @escaping ([Cuenta]) -> Void) -> DatabaseHandle {
        let cuentasRef = database.child("familias").child(familiaId).child("cuentas")
        
        let handle = cuentasRef.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                print("📊 Observador cuentas: No hay datos, enviando array vacío")
                completion([])
                return
            }
            
            var cuentas: [Cuenta] = []
            for (cuentaId, cuentaData) in data {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: cuentaData)
                    let cuenta = try JSONDecoder().decode(Cuenta.self, from: jsonData)
                    cuentas.append(cuenta)
                } catch {
                    print("❌ Error decodificando cuenta \(cuentaId) en observador: \(error)")
                    // Continuar con las demás cuentas en lugar de fallar completamente
                }
            }
            
            // Ordenar por fecha de vencimiento
            cuentas.sort { $0.fechaVencimiento < $1.fechaVencimiento }
            print("📊 Observador cuentas: Enviando \(cuentas.count) cuentas")
            completion(cuentas)
        } withCancel: { error in
            print("❌ Error en observador de cuentas: \(error)")
            completion([])
        }
        
        return handle
    }
    
    func detenerObservadorCuentas(familiaId: String, handle: DatabaseHandle) {
        let cuentasRef = database.child("familias").child(familiaId).child("cuentas")
        cuentasRef.removeObserver(withHandle: handle)
    }
}
