import Foundation
import FirebaseDatabase
import FirebaseAuth

// Se revierte a class para evitar conflictos de concurrencia con el SDK de Firebase,
// que gestiona sus propios hilos. La clase actúa como un wrapper stateless.
final class FirebaseService {
    private let database = Database.database().reference()
    
    // MARK: - Usuario Methods
    
    func crearUsuario(_ usuario: Usuario) async throws {
        do {
            let userData = try JSONEncoder().encode(usuario)
            let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]
            try await database.child("usuarios").child(usuario.id).setValue(userDict)
        } catch {
            print("Error al crear usuario: \(error)")
            throw error
        }
    }
    
    func obtenerUsuario(uid: String) async throws -> Usuario? {
        let snapshot = try await database.child("usuarios").child(uid).getData()
        guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
            return nil
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(Usuario.self, from: jsonData)
        } catch {
            print("Error decodificando usuario: \(error)")
            throw error
        }
    }
    
    // MARK: - Familia Methods
    
    func crearFamilia(_ familia: Familia) async throws {
        let familiaData = try JSONEncoder().encode(familia)
        let familiaDict = try JSONSerialization.jsonObject(with: familiaData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familia.id).setValue(familiaDict)
    }
    
    func obtenerFamilia(familiaId: String) async throws -> Familia {
        let snapshot = try await database.child("familias").child(familiaId).getData()
        guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
            throw NSError(domain: "FirebaseService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Familia no encontrada"])
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(Familia.self, from: jsonData)
    }
    
    func obtenerMembresiasUsuario(usuarioId: String) async throws -> [MiembroFamilia] {
        let snapshot = try await database.child("familias").getData()
        guard snapshot.exists(), let familias = snapshot.value as? [String: Any] else {
            return []
        }
        
        var membresias: [MiembroFamilia] = []
        for (familiaId, familiaData) in familias {
            if let familiaDict = familiaData as? [String: Any],
               let miembros = familiaDict["miembros"] as? [String: Any],
               let miembroData = miembros[usuarioId] as? [String: Any] {
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: miembroData)
                    var miembro = try JSONDecoder().decode(MiembroFamilia.self, from: jsonData)
                    miembro.familiaId = familiaId
                    membresias.append(miembro)
                } catch {
                    print("Error decodificando miembro: \(error)")
                }
            }
        }
        return membresias
    }
    
    func agregarMiembroFamilia(familiaId: String, miembro: MiembroFamilia) async throws {
        let miembroData = try JSONEncoder().encode(miembro)
        let miembroDict = try JSONSerialization.jsonObject(with: miembroData) as? [String: Any] ?? [:]
        
        try await database.child("familias").child(familiaId).child("miembros").child(miembro.id).setValue(miembroDict)
        // También actualizar el usuario con la familiaId
        try await database.child("usuarios").child(miembro.id).child("familiaId").setValue(familiaId)
    }
    
    // MARK: - Cuentas Familiares
    
    func obtenerCuentasFamilia(familiaId: String) async throws -> [Cuenta] {
        let snapshot = try await database.child("familias").child(familiaId).child("cuentas").getData()
        guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
            return []
        }
        
        return data.values.compactMap { cuentaData in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: cuentaData)
                return try JSONDecoder().decode(Cuenta.self, from: jsonData)
            } catch {
                print("Error decodificando cuenta: \(error)")
                return nil
            }
        }
    }
    
    func crearCuenta(_ cuenta: Cuenta, familiaId: String) async throws {
        let cuentaData = try JSONEncoder().encode(cuenta)
        let cuentaDict = try JSONSerialization.jsonObject(with: cuentaData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("cuentas").child(cuenta.id).setValue(cuentaDict)
    }
    
    func actualizarCuenta(_ cuenta: Cuenta, familiaId: String) async throws {
        let cuentaData = try JSONEncoder().encode(cuenta)
        let cuentaDict = try JSONSerialization.jsonObject(with: cuentaData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("cuentas").child(cuenta.id).setValue(cuentaDict)
    }
    
    func eliminarCuenta(cuentaId: String, familiaId: String) async throws {
        print("🗑️ Eliminando cuenta: \(cuentaId) de familia: \(familiaId)")
        do {
            try await database.child("familias").child(familiaId).child("cuentas").child(cuentaId).removeValue()
            print("✅ Cuenta eliminada exitosamente: \(cuentaId)")
        } catch {
            print("❌ Error eliminando cuenta: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Presupuestos Familiares
    
    func obtenerPresupuestosFamilia(familiaId: String) async throws -> [PresupuestoMensual] {
        let snapshot = try await database.child("familias").child(familiaId).child("presupuestos").getData()
        guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
            return []
        }
        
        return data.values.compactMap { presupuestoData in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: presupuestoData)
                return try JSONDecoder().decode(PresupuestoMensual.self, from: jsonData)
            } catch {
                print("Error decodificando presupuesto: \(error)")
                return nil
            }
        }
    }
    
    func crearPresupuesto(_ presupuesto: PresupuestoMensual, familiaId: String) async throws {
        let presupuestoData = try JSONEncoder().encode(presupuesto)
        let presupuestoDict = try JSONSerialization.jsonObject(with: presupuestoData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("presupuestos").child(presupuesto.id).setValue(presupuestoDict)
    }
    
    // MARK: - Aportes Familiares
    
    func obtenerAportesFamilia(familiaId: String) async throws -> [Aporte] {
        let snapshot = try await database.child("familias").child(familiaId).child("aportes").getData()
        guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
            return []
        }
        
        return data.values.compactMap { aporteData in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: aporteData)
                return try JSONDecoder().decode(Aporte.self, from: jsonData)
            } catch {
                print("Error decodificando aporte: \(error)")
                return nil
            }
        }
    }
    
    func crearAporte(_ aporte: Aporte, familiaId: String) async throws {
        let aporteData = try JSONEncoder().encode(aporte)
        let aporteDict = try JSONSerialization.jsonObject(with: aporteData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("aportes").child(aporte.id).setValue(aporteDict)
    }
    
    // FASE 1: Método para actualizar aporte existente
    func actualizarAporte(familiaId: String, aporte: Aporte) async throws {
        let aporteData = try JSONEncoder().encode(aporte)
        let aporteDict = try JSONSerialization.jsonObject(with: aporteData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("aportes").child(aporte.id).updateChildValues(aporteDict)
    }
    
    func eliminarAporte(aporteId: String, familiaId: String) async throws {
        try await database.child("familias").child(familiaId).child("aportes").child(aporteId).removeValue()
    }
    
    // MARK: - Deudas Familiares
    
    func obtenerDeudasFamilia(familiaId: String) async throws -> [DeudaPresupuesto] {
        let snapshot = try await database.child("familias").child(familiaId).child("deudas").getData()
        guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
            return []
        }
        
        return data.values.compactMap { deudaData in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: deudaData)
                return try JSONDecoder().decode(DeudaPresupuesto.self, from: jsonData)
            } catch {
                print("Error decodificando deuda: \(error)")
                return nil
            }
        }
    }
    
    func crearDeuda(_ deuda: DeudaPresupuesto, familiaId: String) async throws {
        let deudaData = try JSONEncoder().encode(deuda)
        let deudaDict = try JSONSerialization.jsonObject(with: deudaData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("deudas").child(deuda.id).setValue(deudaDict)
    }
    
    func actualizarDeuda(_ deuda: DeudaPresupuesto, familiaId: String) async throws {
        let deudaData = try JSONEncoder().encode(deuda)
        let deudaDict = try JSONSerialization.jsonObject(with: deudaData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("deudas").child(deuda.id).setValue(deudaDict)
    }
    
    func eliminarDeuda(deudaId: String, familiaId: String) async throws {
        try await database.child("familias").child(familiaId).child("deudas").child(deudaId).removeValue()
    }
    
    // MARK: - Invitaciones
    
    func buscarInvitacionPorCodigo(_ codigo: String) async throws -> InvitacionFamiliar? {
        let snapshot = try await database.child("invitaciones").queryOrdered(byChild: "codigoInvitacion").queryEqual(toValue: codigo).getData()
        
        guard snapshot.exists(),
              let data = snapshot.value as? [String: Any],
              let invitacionData = data.values.first else {
            return nil
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: invitacionData)
        return try JSONDecoder().decode(InvitacionFamiliar.self, from: jsonData)
    }
    
    func actualizarInvitacion(_ invitacion: InvitacionFamiliar) async throws {
        let invitacionData = try JSONEncoder().encode(invitacion)
        let invitacionDict = try JSONSerialization.jsonObject(with: invitacionData) as? [String: Any] ?? [:]
        try await database.child("invitaciones").child(invitacion.id).setValue(invitacionDict)
    }
    
    func crearInvitacion(_ invitacion: InvitacionFamiliar) async throws {
        let invitacionData = try JSONEncoder().encode(invitacion)
        let invitacionDict = try JSONSerialization.jsonObject(with: invitacionData) as? [String: Any] ?? [:]
        try await database.child("invitaciones").child(invitacion.id).setValue(invitacionDict)
    }
    
    func eliminarInvitacion(_ invitacionId: String) async throws {
        try await database.child("invitaciones").child(invitacionId).removeValue()
    }
    
    // Método optimizado para obtener familia del usuario
    func obtenerFamiliaDelUsuario(usuarioId: String) async throws -> (Familia?, MiembroFamilia?) {
        // Primero obtener el usuario para conseguir su familiaId
        guard let usuario = try await obtenerUsuario(uid: usuarioId),
              let familiaId = usuario.familiaId else {
            // Usuario sin familia asignada
            return (nil, nil)
        }

        // Ahora obtener la familia y el miembro en paralelo
        async let familiaTask = obtenerFamilia(familiaId: familiaId)
        async let miembroTask = obtenerMiembro(familiaId: familiaId, usuarioId: usuarioId)

        do {
            let familia = try await familiaTask
            var miembro = try await miembroTask
            miembro?.familiaId = familiaId // Asegurarse de que el miembro tenga el familiaId correcto
            return (familia, miembro)
        } catch {
            print("Error obteniendo familia o miembro en paralelo: \(error)")
            throw error
        }
    }

    // Helper para obtener un miembro específico
    func obtenerMiembro(familiaId: String, usuarioId: String) async throws -> MiembroFamilia? {
        let snapshot = try await database.child("familias").child(familiaId).child("miembros").child(usuarioId).getData()
        guard snapshot.exists(), let miembroData = snapshot.value as? [String: Any] else {
            return nil
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: miembroData)
        return try JSONDecoder().decode(MiembroFamilia.self, from: jsonData)
    }

    // MARK: - FASE 1: Transacciones de Pago con Aportes
    
    func crearTransaccionPago(familiaId: String, transaccion: TransaccionPago) async throws {
        let transaccionData = try JSONEncoder().encode(transaccion)
        let transaccionDict = try JSONSerialization.jsonObject(with: transaccionData) as? [String: Any] ?? [:]
        try await database.child("familias").child(familiaId).child("transacciones").child(transaccion.id).setValue(transaccionDict)
    }
    
    func obtenerTransacciones(familiaId: String) async throws -> [TransaccionPago] {
        let snapshot = try await database.child("familias").child(familiaId).child("transacciones").getData()
        guard snapshot.exists(), let data = snapshot.value as? [String: Any] else {
            return []
        }
        
        return data.values.compactMap { transaccionData in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: transaccionData)
                return try JSONDecoder().decode(TransaccionPago.self, from: jsonData)
            } catch {
                print("Error decodificando transacción: \(error)")
                return nil
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
            
            var cuentas: [Cuenta] = data.values.compactMap { cuentaData in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: cuentaData)
                    return try JSONDecoder().decode(Cuenta.self, from: jsonData)
                } catch {
                    print("❌ Error decodificando cuenta en observador: \(error)")
                    return nil
                }
            }
            
            cuentas = cuentas.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
            print("📊 Observador cuentas: Enviando \(cuentas.count) cuentas")
            completion(cuentas)
        }
        
        return handle
    }
    
    func detenerObservadorCuentas(familiaId: String, handle: DatabaseHandle) {
        let cuentasRef = database.child("familias").child(familiaId).child("cuentas")
        cuentasRef.removeObserver(withHandle: handle)
        print("🛑 Observador de cuentas detenido para familia \(familiaId)")
    }
    
    // MARK: - Observadores para Aportes
    
    func observarAportes(familiaId: String, completion: @escaping ([Aporte]) -> Void) -> DatabaseHandle {
        let aportesRef = database.child("familias").child(familiaId).child("aportes")
        
        let handle = aportesRef.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                print("📊 Observador aportes: No hay datos, enviando array vacío")
                completion([])
                return
            }
            
            var aportes: [Aporte] = data.values.compactMap { aporteData in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: aporteData)
                    return try JSONDecoder().decode(Aporte.self, from: jsonData)
                } catch {
                    print("❌ Error decodificando aporte en observador: \(error)")
                    return nil
                }
            }
            
            aportes = aportes.sorted { $0.fechaDate < $1.fechaDate }
            print("📊 Observador aportes: Enviando \(aportes.count) aportes")
            completion(aportes)
        }
        
        return handle
    }
    
    func detenerObservadorAportes(familiaId: String, handle: DatabaseHandle) {
        let aportesRef = database.child("familias").child(familiaId).child("aportes")
        aportesRef.removeObserver(withHandle: handle)
        print("🛑 Observador de aportes detenido para familia \(familiaId)")
    }
    
    // MARK: - Observadores para Presupuestos
    
    func observarPresupuestos(familiaId: String, completion: @escaping ([PresupuestoMensual]) -> Void) -> DatabaseHandle {
        let presupuestosRef = database.child("familias").child(familiaId).child("presupuestos")
        
        let handle = presupuestosRef.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                print("📊 Observador presupuestos: No hay datos, enviando array vacío")
                completion([])
                return
            }
            
            var presupuestos: [PresupuestoMensual] = data.values.compactMap { presupuestoData in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: presupuestoData)
                    return try JSONDecoder().decode(PresupuestoMensual.self, from: jsonData)
                } catch {
                    print("❌ Error decodificando presupuesto en observador: \(error)")
                    return nil
                }
            }
            
            presupuestos = presupuestos.sorted { $0.fechaMes < $1.fechaMes }
            print("📊 Observador presupuestos: Enviando \(presupuestos.count) presupuestos")
            completion(presupuestos)
        }
        
        return handle
    }
    
    func detenerObservadorPresupuestos(familiaId: String, handle: DatabaseHandle) {
        let presupuestosRef = database.child("familias").child(familiaId).child("presupuestos")
        presupuestosRef.removeObserver(withHandle: handle)
        print("🛑 Observador de presupuestos detenido para familia \(familiaId)")
    }
    
    // MARK: - Observadores para Deudas
    
    func observarDeudas(familiaId: String, completion: @escaping ([DeudaPresupuesto]) -> Void) -> DatabaseHandle {
        let deudasRef = database.child("familias").child(familiaId).child("deudas")
        
        let handle = deudasRef.observe(.value) { snapshot in
            guard let data = snapshot.value as? [String: Any] else {
                print("📊 Observador deudas: No hay datos, enviando array vacío")
                completion([])
                return
            }
            
            var deudas: [DeudaPresupuesto] = data.values.compactMap { deudaData in
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: deudaData)
                    return try JSONDecoder().decode(DeudaPresupuesto.self, from: jsonData)
                } catch {
                    print("❌ Error decodificando deuda en observador: \(error)")
                    return nil
                }
            }
            
            deudas = deudas.sorted { $0.fechaInicio < $1.fechaInicio }
            print("📊 Observador deudas: Enviando \(deudas.count) deudas")
            completion(deudas)
        }
        
        return handle
    }
    
    func detenerObservadorDeudas(familiaId: String, handle: DatabaseHandle) {
        let deudasRef = database.child("familias").child(familiaId).child("deudas")
        deudasRef.removeObserver(withHandle: handle)
        print("🛑 Observador de deudas detenido para familia \(familiaId)")
    }
}
