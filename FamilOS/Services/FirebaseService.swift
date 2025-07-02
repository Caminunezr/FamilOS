import Foundation
import FirebaseDatabase
import FirebaseAuth

class FirebaseService: ObservableObject {
    private let database = Database.database().reference()
    private var listeners: [DatabaseHandle] = []
    
    // Configurar decodificador para fechas
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()
    
    // Configurar codificador para fechas
    private lazy var jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()
    
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
                let userData = try jsonEncoder.encode(usuario)
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
            database.child("usuarios").child(uid).observeSingleEvent(of: .value) { [self] snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let usuario = try jsonDecoder.decode(Usuario.self, from: jsonData)
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
                let familiaData = try jsonEncoder.encode(familia)
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
    
    // Método combinado para crear familia y agregar el primer miembro en una sola operación
    func crearFamiliaConAdministrador(_ familia: Familia, administrador: MiembroFamilia) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                print("🏠 Iniciando creación de familia: \(familia.nombre)")
                print("👤 Administrador: \(administrador.nombre) (\(administrador.id))")
                
                // Preparar datos de la familia
                let familiaData = try jsonEncoder.encode(familia)
                var familiaDict = try JSONSerialization.jsonObject(with: familiaData) as? [String: Any] ?? [:]
                
                // Preparar datos del administrador
                let adminData = try jsonEncoder.encode(administrador)
                let adminDict = try JSONSerialization.jsonObject(with: adminData) as? [String: Any] ?? [:]
                
                // Agregar el administrador directamente a la estructura de la familia
                familiaDict["miembros"] = [administrador.id: adminDict]
                
                print("📝 Escribiendo familia con ID: \(familia.id)")
                
                // Escribir todo en una sola operación
                database.child("familias").child(familia.id).setValue(familiaDict) { error, _ in
                    if let error = error {
                        print("❌ Error al crear familia: \(error.localizedDescription)")
                        self.logFirebaseError(error, operation: "crearFamiliaConAdministrador")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Familia creada exitosamente")
                        // También actualizar el usuario con la familiaId
                        self.database.child("usuarios").child(administrador.id).child("familiaId").setValue(familia.id) { updateError, _ in
                            if let updateError = updateError {
                                print("⚠️ Warning: No se pudo actualizar familiaId del usuario: \(updateError.localizedDescription)")
                                self.logFirebaseError(updateError, operation: "actualizar familiaId del usuario")
                            } else {
                                print("✅ Usuario actualizado con familiaId")
                            }
                            continuation.resume(returning: ())
                        }
                    }
                }
            } catch {
                print("❌ Error en preparación de datos: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Método simplificado para crear familia con miembro admin (para onboarding)
    func crearFamilia(_ familia: Familia, miembroAdmin: MiembroFamilia) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                print("🏠 Creando familia (onboarding): \(familia.nombre)")
                print("👤 Admin: \(miembroAdmin.nombre)")
                
                // Preparar datos de la familia
                let familiaData = try jsonEncoder.encode(familia)
                var familiaDict = try JSONSerialization.jsonObject(with: familiaData) as? [String: Any] ?? [:]
                
                // Preparar datos del administrador
                let adminData = try jsonEncoder.encode(miembroAdmin)
                let adminDict = try JSONSerialization.jsonObject(with: adminData) as? [String: Any] ?? [:]
                
                // Agregar el administrador a la familia
                familiaDict["miembros"] = [miembroAdmin.id: adminDict]
                
                // Crear familia y usuario en paralelo
                let group = DispatchGroup()
                var error: Error?
                
                // Escribir familia
                group.enter()
                database.child("familias").child(familia.id).setValue(familiaDict) { err, _ in
                    if let err = err {
                        error = err
                        print("❌ Error creando familia: \(err)")
                    } else {
                        print("✅ Familia creada en Firebase")
                    }
                    group.leave()
                }
                
                // Actualizar usuario con familiaId
                group.enter()
                database.child("usuarios").child(miembroAdmin.id).child("familiaId").setValue(familia.id) { err, _ in
                    if let err = err {
                        error = err
                        print("❌ Error actualizando usuario: \(err)")
                    } else {
                        print("✅ Usuario actualizado con familiaId")
                    }
                    group.leave()
                }
                
                group.notify(queue: .main) {
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        print("🎉 Familia y miembro admin creados exitosamente")
                        continuation.resume(returning: ())
                    }
                }
                
            } catch {
                print("❌ Error en preparación de datos: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerFamilia(familiaId: String) async throws -> Familia {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).observeSingleEvent(of: .value) { [self] snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(throwing: NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Familia no encontrada"]))
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let familia = try jsonDecoder.decode(Familia.self, from: jsonData)
                    continuation.resume(returning: familia)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func obtenerMembresiasUsuario(usuarioId: String) async throws -> [MiembroFamilia] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").observeSingleEvent(of: .value) { [self] snapshot in
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
                            var miembro = try jsonDecoder.decode(MiembroFamilia.self, from: jsonData)
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
                let miembroData = try jsonEncoder.encode(miembro)
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
    
    // MARK: - Cuentas Methods
    
    func crearCuenta(familiaId: String, cuenta: Cuenta) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let cuentaData = try jsonEncoder.encode(cuenta)
                let cuentaDict = try JSONSerialization.jsonObject(with: cuentaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("cuentas").child(cuenta.id).setValue(cuentaDict) { error, _ in
                    if let error = error {
                        print("❌ Error al crear cuenta: \(error.localizedDescription)")
                        self.logFirebaseError(error, operation: "crearCuenta")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Cuenta creada exitosamente: \(cuenta.nombre)")
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                print("❌ Error en preparación de datos de cuenta: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerCuentas(familiaId: String) async throws -> [Cuenta] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("cuentas").observeSingleEvent(of: .value) { [self] snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var cuentas: [Cuenta] = []
                for (_, cuentaData) in data {
                    if let cuentaDict = cuentaData as? [String: Any] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: cuentaDict)
                            var cuenta = try jsonDecoder.decode(Cuenta.self, from: jsonData)
                            // Recalcular el estado después de la decodificación para asegurar consistencia
                            cuenta.recalcularEstado()
                            cuentas.append(cuenta)
                        } catch {
                            print("Error decodificando cuenta: \(error)")
                        }
                    }
                }
                
                continuation.resume(returning: cuentas)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func actualizarCuenta(familiaId: String, cuenta: Cuenta) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let cuentaData = try jsonEncoder.encode(cuenta)
                let cuentaDict = try JSONSerialization.jsonObject(with: cuentaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("cuentas").child(cuenta.id).setValue(cuentaDict) { error, _ in
                    if let error = error {
                        print("❌ Error al actualizar cuenta: \(error.localizedDescription)")
                        self.logFirebaseError(error, operation: "actualizarCuenta")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Cuenta actualizada exitosamente: \(cuenta.nombre)")
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                print("❌ Error en preparación de datos de cuenta: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func eliminarCuenta(familiaId: String, cuentaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("cuentas").child(cuentaId).removeValue { error, _ in
                if let error = error {
                    print("❌ Error al eliminar cuenta: \(error.localizedDescription)")
                    self.logFirebaseError(error, operation: "eliminarCuenta")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Cuenta eliminada exitosamente")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func observarCuentas(familiaId: String, completion: @escaping ([Cuenta]) -> Void) {
        let handle = database.child("familias").child(familiaId).child("cuentas").observe(.value) { [self] snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                completion([])
                return
            }
            
            var cuentas: [Cuenta] = []
            for (_, cuentaData) in data {
                if let cuentaDict = cuentaData as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: cuentaDict)
                        var cuenta = try jsonDecoder.decode(Cuenta.self, from: jsonData)
                        // Recalcular el estado después de la decodificación para asegurar consistencia
                        cuenta.recalcularEstado()
                        cuentas.append(cuenta)
                    } catch {
                        print("Error decodificando cuenta en observador: \(error)")
                    }
                }
            }
            
            completion(cuentas)
        }
        listeners.append(handle)
    }
    
    // MARK: - Presupuestos Methods
    
    func crearPresupuesto(familiaId: String, presupuesto: PresupuestoMensual) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let presupuestoData = try jsonEncoder.encode(presupuesto)
                let presupuestoDict = try JSONSerialization.jsonObject(with: presupuestoData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("presupuestos").child(presupuesto.id).setValue(presupuestoDict) { error, _ in
                    if let error = error {
                        print("❌ Error al crear presupuesto: \(error.localizedDescription)")
                        self.logFirebaseError(error, operation: "crearPresupuesto")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Presupuesto creado exitosamente: \(presupuesto.nombreMes)")
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                print("❌ Error en preparación de datos de presupuesto: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerPresupuestos(familiaId: String) async throws -> [PresupuestoMensual] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("presupuestos").observeSingleEvent(of: .value) { [self] snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var presupuestos: [PresupuestoMensual] = []
                for (_, presupuestoData) in data {
                    if let presupuestoDict = presupuestoData as? [String: Any] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: presupuestoDict)
                            let presupuesto = try jsonDecoder.decode(PresupuestoMensual.self, from: jsonData)
                            presupuestos.append(presupuesto)
                        } catch {
                            print("Error decodificando presupuesto: \(error)")
                        }
                    }
                }
                
                continuation.resume(returning: presupuestos)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func actualizarPresupuesto(familiaId: String, presupuesto: PresupuestoMensual) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let presupuestoData = try jsonEncoder.encode(presupuesto)
                let presupuestoDict = try JSONSerialization.jsonObject(with: presupuestoData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("presupuestos").child(presupuesto.id).setValue(presupuestoDict) { error, _ in
                    if let error = error {
                        print("❌ Error al actualizar presupuesto: \(error.localizedDescription)")
                        self.logFirebaseError(error, operation: "actualizarPresupuesto")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Presupuesto actualizado exitosamente: \(presupuesto.nombreMes)")
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                print("❌ Error en preparación de datos de presupuesto: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func eliminarPresupuesto(familiaId: String, presupuestoId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("presupuestos").child(presupuestoId).removeValue { error, _ in
                if let error = error {
                    print("❌ Error al eliminar presupuesto: \(error.localizedDescription)")
                    self.logFirebaseError(error, operation: "eliminarPresupuesto")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Presupuesto eliminado exitosamente")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Aportes Methods
    
    func crearAporte(familiaId: String, aporte: Aporte) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                print("📊 Creando aporte:")
                print("   - FamiliaId: \(familiaId)")
                print("   - AporteId: \(aporte.id)")
                print("   - Usuario: \(aporte.usuario)")
                print("   - Monto: \(aporte.monto)")
                print("   - Fecha: \(aporte.fecha)")
                print("   - PresupuestoId: \(aporte.presupuestoId)")
                print("   - Comentario: '\(aporte.comentario)'")
                
                let aporteData = try jsonEncoder.encode(aporte)
                let aporteDict = try JSONSerialization.jsonObject(with: aporteData) as? [String: Any] ?? [:]
                
                print("📊 Datos serializados del aporte:")
                for (key, value) in aporteDict {
                    print("   - \(key): \(value) (tipo: \(type(of: value)))")
                }
                
                // Verificar estructura de datos antes de enviar
                let pathCompleto = "familias/\(familiaId)/aportes/\(aporte.id)"
                print("📊 Path completo a Firebase: \(pathCompleto)")
                
                // Verificar que tenemos autenticación
                if let currentUser = Auth.auth().currentUser {
                    print("📊 Usuario autenticado: \(currentUser.uid)")
                } else {
                    print("❌ No hay usuario autenticado!")
                    continuation.resume(throwing: NSError(domain: "FirebaseAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuario no autenticado"]))
                    return
                }
                
                database.child("familias").child(familiaId).child("aportes").child(aporte.id).setValue(aporteDict) { error, _ in
                    if let error = error {
                        print("❌ Error al crear aporte: \(error.localizedDescription)")
                        if let nsError = error as NSError? {
                            print("   - Código: \(nsError.code)")
                            print("   - Dominio: \(nsError.domain)")
                            print("   - UserInfo: \(nsError.userInfo)")
                            
                            // Logs específicos para errores de reglas
                            if nsError.domain == "FirebaseDatabase" {
                                print("   - Error específico de Firebase Database")
                                if nsError.code == 1 {
                                    print("   - Código 1: Probablemente problema de permisos/reglas")
                                }
                            }
                        }
                        self.logFirebaseError(error, operation: "crearAporte")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Aporte creado exitosamente: $\(aporte.monto)")
                        print("✅ Path utilizado: familias/\(familiaId)/aportes/\(aporte.id)")
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                print("❌ Error en preparación de datos de aporte: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerAportes(familiaId: String, presupuestoId: String) async throws -> [Aporte] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("aportes")
                .queryOrdered(byChild: "presupuestoId")
                .queryEqual(toValue: presupuestoId)
                .observeSingleEvent(of: .value) { [self] snapshot in
                    guard let data = snapshot.value as? [String: Any] else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    var aportes: [Aporte] = []
                    for (_, aporteData) in data {
                        if let aporteDict = aporteData as? [String: Any] {
                            do {
                                let jsonData = try JSONSerialization.data(withJSONObject: aporteDict)
                                let aporte = try jsonDecoder.decode(Aporte.self, from: jsonData)
                                aportes.append(aporte)
                            } catch {
                                print("Error decodificando aporte: \(error)")
                            }
                        }
                    }
                    
                    continuation.resume(returning: aportes)
                } withCancel: { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    func eliminarAporte(familiaId: String, aporteId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("aportes").child(aporteId).removeValue { error, _ in
                if let error = error {
                    print("❌ Error al eliminar aporte: \(error.localizedDescription)")
                    self.logFirebaseError(error, operation: "eliminarAporte")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Aporte eliminado exitosamente")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Deudas Methods
    
    func crearDeuda(familiaId: String, deuda: DeudaPresupuesto) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let deudaData = try jsonEncoder.encode(deuda)
                let deudaDict = try JSONSerialization.jsonObject(with: deudaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("deudas").child(deuda.id).setValue(deudaDict) { error, _ in
                    if let error = error {
                        print("❌ Error al crear deuda: \(error.localizedDescription)")
                        self.logFirebaseError(error, operation: "crearDeuda")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Deuda creada exitosamente: \(deuda.descripcion)")
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                print("❌ Error en preparación de datos de deuda: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func obtenerDeudas(familiaId: String) async throws -> [DeudaPresupuesto] {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("deudas").observeSingleEvent(of: .value) { [self] snapshot in
                guard let data = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var deudas: [DeudaPresupuesto] = []
                for (_, deudaData) in data {
                    if let deudaDict = deudaData as? [String: Any] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: deudaDict)
                            let deuda = try jsonDecoder.decode(DeudaPresupuesto.self, from: jsonData)
                            deudas.append(deuda)
                        } catch {
                            print("Error decodificando deuda: \(error)")
                        }
                    }
                }
                
                continuation.resume(returning: deudas)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    func actualizarDeuda(familiaId: String, deuda: DeudaPresupuesto) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let deudaData = try jsonEncoder.encode(deuda)
                let deudaDict = try JSONSerialization.jsonObject(with: deudaData) as? [String: Any] ?? [:]
                
                database.child("familias").child(familiaId).child("deudas").child(deuda.id).setValue(deudaDict) { error, _ in
                    if let error = error {
                        print("❌ Error al actualizar deuda: \(error.localizedDescription)")
                        self.logFirebaseError(error, operation: "actualizarDeuda")
                        continuation.resume(throwing: error)
                    } else {
                        print("✅ Deuda actualizada exitosamente: \(deuda.descripcion)")
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                print("❌ Error en preparación de datos de deuda: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            }
        }
    }
    
    func eliminarDeuda(familiaId: String, deudaId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("familias").child(familiaId).child("deudas").child(deudaId).removeValue { error, _ in
                if let error = error {
                    print("❌ Error al eliminar deuda: \(error.localizedDescription)")
                    self.logFirebaseError(error, operation: "eliminarDeuda")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Deuda eliminada exitosamente")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Invitaciones
    
    func buscarInvitacionPorCodigo(_ codigo: String) async throws -> InvitacionFamiliar? {
        return try await withCheckedThrowingContinuation { continuation in
            database.child("invitaciones").queryOrdered(byChild: "codigoInvitacion").queryEqual(toValue: codigo).observeSingleEvent(of: .value) { [self] snapshot in
                guard let data = snapshot.value as? [String: Any],
                      let invitacionData = data.values.first else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: invitacionData)
                    let invitacion = try jsonDecoder.decode(InvitacionFamiliar.self, from: jsonData)
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
                let invitacionData = try jsonEncoder.encode(invitacion)
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
                let invitacionData = try jsonEncoder.encode(invitacion)
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
                    print("❌ Error al eliminar invitación: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Invitación eliminada exitosamente")
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Error Handling Helpers
    
    private func logFirebaseError(_ error: Error, operation: String) {
        print("❌ Firebase Error en \(operation):")
        print("   - Descripción: \(error.localizedDescription)")
        
        if let nsError = error as NSError? {
            print("   - Código: \(nsError.code)")
            print("   - Dominio: \(nsError.domain)")
            print("   - UserInfo: \(nsError.userInfo)")
            
            // Errores específicos de Firebase Database
            if nsError.domain == "com.firebase" {
                switch nsError.code {
                case -3: // PERMISSION_DENIED
                    print("   ⚠️ PERMISSION_DENIED: Verificar reglas de Firebase Database")
                case -1: // NETWORK_ERROR
                    print("   ⚠️ NETWORK_ERROR: Problema de conectividad")
                case -2: // UNAVAILABLE
                    print("   ⚠️ UNAVAILABLE: Servicio no disponible")
                default:
                    print("   ⚠️ Código de error Firebase no reconocido")
                }
            }
        }
    }
    
    // Método optimizado para obtener familia del usuario
    func obtenerFamiliaDelUsuario(usuarioId: String) async throws -> (Familia?, MiembroFamilia?) {
        return try await withCheckedThrowingContinuation { continuation in
            // Primero obtener el usuario para conseguir su familiaId
            database.child("usuarios").child(usuarioId).observeSingleEvent(of: .value) { [self] snapshot in
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
                self.database.child("familias").child(familiaId).observeSingleEvent(of: .value) { [self] familiaSnapshot in
                    defer { group.leave() }
                    
                    guard let familiaData = familiaSnapshot.value as? [String: Any] else {
                        error = NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Familia no encontrada"])
                        return
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: familiaData)
                        familia = try jsonDecoder.decode(Familia.self, from: jsonData)
                    } catch {
                        print("Error decodificando familia: \(error)")
                    }
                }
                
                // Obtener miembro
                group.enter()
                self.database.child("familias").child(familiaId).child("miembros").child(usuarioId).observeSingleEvent(of: .value) { [self] miembroSnapshot in
                    defer { group.leave() }
                    
                    guard let miembroData = miembroSnapshot.value as? [String: Any] else {
                        error = NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Miembro no encontrado"])
                        return
                    }
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: miembroData)
                        miembro = try jsonDecoder.decode(MiembroFamilia.self, from: jsonData)
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
    
    // MARK: - Transacciones Methods (para un futuro registro de pagos de cuentas)
    
    func registrarPagoCuenta(familiaId: String, cuentaId: String, monto: Double, usuario: String, fecha: Date = Date()) async throws {
        // Crear transacción del pago
        let transaccion: [String: Any] = [
            "id": UUID().uuidString,
            "cuentaId": cuentaId,
            "tipo": "pago",
            "monto": monto,
            "usuario": usuario,
            "fecha": fecha.timeIntervalSince1970,
            "descripcion": "Pago de cuenta"
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            // Actualizar cuenta y crear transacción en una sola operación
            let updates: [String: Any] = [
                "familias/\(familiaId)/cuentas/\(cuentaId)/estado": "Pagada",
                "familias/\(familiaId)/cuentas/\(cuentaId)/fechaPago": fecha.timeIntervalSince1970,
                "familias/\(familiaId)/cuentas/\(cuentaId)/montoPagado": monto,
                "familias/\(familiaId)/transacciones/\(transaccion["id"] as! String)": transaccion
            ]
            
            database.updateChildValues(updates) { error, _ in
                if let error = error {
                    print("❌ Error al registrar pago: \(error.localizedDescription)")
                    self.logFirebaseError(error, operation: "registrarPagoCuenta")
                    continuation.resume(throwing: error)
                } else {
                    print("✅ Pago registrado exitosamente")
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
