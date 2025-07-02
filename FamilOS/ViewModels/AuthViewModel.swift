import Foundation
import SwiftUI
import LocalAuthentication
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import Network

class AuthViewModel: ObservableObject {
    @Published var usuarioActual: Usuario?
    @Published var familiaActual: Familia?
    @Published var miembroFamiliar: MiembroFamilia?
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var error: String?
    @Published var mostrarRegistro: Bool = false
    @Published var mostrarCreacionFamilia: Bool = false
    @Published var mostrarUnirseFamilia: Bool = false
    @Published var needsFamilySetup: Bool = false // Nueva propiedad para el onboarding
    @Published var networkStatus: NWPath.Status = .satisfied
    
    private let firebaseService = FirebaseService()
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        // Configurar monitoreo de red
        setupNetworkMonitoring()
        
        // Verificar si hay un usuario autenticado
        verificarUsuarioAutenticado()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.networkStatus = path.status
                print("Network status changed: \(path.status)")
                
                if path.status == .satisfied {
                    print("✅ Network is available")
                } else {
                    print("❌ Network is not available")
                    self?.error = "Sin conexión a internet. Verifica tu red."
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    // Verificar si hay un usuario autenticado actualmente
    private func verificarUsuarioAutenticado() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                if let firebaseUser = user {
                    // Usuario autenticado, cargar datos del usuario
                    self?.cargarDatosUsuario(uid: firebaseUser.uid)
                } else {
                    // No hay usuario autenticado
                    self?.usuarioActual = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // Cargar datos del usuario desde Firebase Database
    private func cargarDatosUsuario(uid: String) {
        Task {
            do {
                // Cargar usuario
                if let usuario = try await firebaseService.obtenerUsuario(uid: uid) {
                    await MainActor.run {
                        self.usuarioActual = usuario
                    }
                    
                    // Cargar información familiar
                    try await cargarDatosFamiliares(usuarioId: uid)
                    
                    await MainActor.run {
                        self.isAuthenticated = true
                    }
                } else {
                    // Si no hay datos en la DB, crear perfil básico
                    await crearPerfilUsuario(uid: uid)
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al cargar datos del usuario: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Cargar datos familiares del usuario
    private func cargarDatosFamiliares(usuarioId: String) async throws {
        // Solo intentar cargar datos familiares si el usuario existe en la DB
        guard usuarioActual != nil else { return }
        
        do {
            // Usar método optimizado para obtener familia del usuario
            let (familia, miembro) = try await firebaseService.obtenerFamiliaDelUsuario(usuarioId: usuarioId)
            
            await MainActor.run {
                self.familiaActual = familia
                self.miembroFamiliar = miembro
                
                if familia == nil {
                    print("ℹ️ Usuario sin familia asignada - mostrando onboarding")
                    self.needsFamilySetup = true
                } else {
                    self.needsFamilySetup = false
                }
            }
        } catch {
            // Si hay error de permisos, significa que el usuario no tiene familia asignada
            print("Info: Usuario sin familia asignada - \(error.localizedDescription)")
            await MainActor.run {
                self.familiaActual = nil
                self.miembroFamiliar = nil
                self.needsFamilySetup = true
            }
        }
    }
    
    // Crear perfil de usuario en Firebase Database
    private func crearPerfilUsuario(uid: String) async {
        guard let firebaseUser = Auth.auth().currentUser else { return }
        
        let usuario = Usuario(
            id: uid,
            nombre: firebaseUser.displayName ?? "Usuario",
            email: firebaseUser.email ?? "",
            contrasena: "",
            esPrincipal: true
        )
        
        do {
            print("👤 Creando perfil de usuario existente: \(usuario.nombre)")
            try await firebaseService.crearUsuario(usuario)
            
            await MainActor.run {
                self.usuarioActual = usuario
            }
            
            // Crear automáticamente una familia para este usuario
            print("🏠 Creando familia automática para usuario existente...")
            let nuevaFamilia = Familia(
                nombre: "Familia de \(usuario.nombre)",
                descripcion: "Familia creada automáticamente",
                adminId: uid
            )
            
            let miembro = MiembroFamilia(
                id: uid,
                nombre: usuario.nombre,
                email: usuario.email,
                rol: .admin,
                familiaId: nuevaFamilia.id
            )
            
            print("📝 Creando familia con ID: \(nuevaFamilia.id)")
            try await firebaseService.crearFamilia(nuevaFamilia)
            try await firebaseService.agregarMiembroFamilia(familiaId: nuevaFamilia.id, miembro: miembro)
            
            await MainActor.run {
                self.familiaActual = nuevaFamilia
                self.miembroFamiliar = miembro
                self.isAuthenticated = true
            }
            
            print("✅ Usuario y familia creados exitosamente para usuario existente")
            
        } catch {
            print("❌ Error al crear perfil de usuario existente: \(error)")
            await MainActor.run {
                self.error = "Error al crear perfil: \(error.localizedDescription)"
            }
        }
    }
    
    // Inicio de sesión con email y contraseña
    func login(email: String, contrasena: String) {
        isAuthenticating = true
        error = nil
        
        Auth.auth().signIn(withEmail: email, password: contrasena) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isAuthenticating = false
                
                if let error = error {
                    self?.error = self?.obtenerMensajeError(error) ?? "Error desconocido"
                } else {
                    // El listener de Auth se encargará de actualizar el estado
                    self?.guardarCredenciales(email: email, contrasena: contrasena)
                }
            }
        }
    }
    
    // Inicio de sesión con biométricos (Touch ID/Face ID)
    func loginConBiometricos() {
        let context = LAContext()
        var error: NSError?
        
        // Verificar si la biometría está disponible
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Si hay credenciales guardadas, intentamos autenticar
            if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail"),
               let savedPassword = UserDefaults.standard.string(forKey: "savedPassword") {
                
                self.isAuthenticating = true
                
                let reason = "Iniciar sesión en FamilOS"
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            // Autenticación biométrica exitosa, ahora usamos las credenciales guardadas
                            self.login(email: savedEmail, contrasena: savedPassword)
                        } else {
                            // Error en autenticación biométrica
                            self.error = "No se pudo verificar tu identidad. Por favor usa tu correo y contraseña."
                            self.isAuthenticating = false
                        }
                    }
                }
            } else {
                // No hay credenciales guardadas
                self.error = "Debes iniciar sesión primero para configurar la autenticación biométrica."
            }
        } else {
            // Biometría no disponible
            self.error = "Tu dispositivo no soporta autenticación biométrica."
        }
    }
    
    // Cerrar sesión
    func logout() {
        do {
            try Auth.auth().signOut()
            usuarioActual = nil
            familiaActual = nil
            miembroFamiliar = nil
            isAuthenticated = false
            mostrarCreacionFamilia = false
            mostrarUnirseFamilia = false
            error = nil
        } catch {
            self.error = "Error al cerrar sesión: \(error.localizedDescription)"
        }
    }
    
    // Registrar un nuevo usuario
    func registrarUsuario(nombre: String, email: String, contrasena: String) {
        isAuthenticating = true
        error = nil
        
        Auth.auth().createUser(withEmail: email, password: contrasena) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.error = self?.obtenerMensajeError(error) ?? "Error desconocido"
                    self?.isAuthenticating = false
                } else if let user = result?.user {
                    // Actualizar el nombre del usuario en Firebase Auth
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = nombre
                    changeRequest.commitChanges { _ in
                        // Crear perfil en Database
                        self?.crearPerfilUsuarioRegistro(uid: user.uid, nombre: nombre, email: email)
                    }
                    
                    // Guardar credenciales
                    self?.guardarCredenciales(email: email, contrasena: contrasena)
                }
            }
        }
    }
    
    // Crear perfil de usuario durante el registro
    private func crearPerfilUsuarioRegistro(uid: String, nombre: String, email: String) {
        let usuario = Usuario(
            id: uid,
            nombre: nombre,
            email: email,
            contrasena: "", // No almacenamos la contraseña en la base de datos
            fechaCreacion: Date()
        )
        
        let firebaseService = FirebaseService()
        Task {
            do {
                print("👤 Creando usuario en Database: \(usuario.nombre)")
                // 1. Crear usuario en Firebase Database
                try await firebaseService.crearUsuario(usuario)
                
                print("🏠 Preparando familia automática...")
                // 2. Crear una familia automáticamente para el nuevo usuario
                let nuevaFamilia = Familia(
                    nombre: "Familia de \(nombre)",
                    descripcion: "Familia creada automáticamente",
                    adminId: uid
                )
                
                // 3. Crear el miembro administrador
                let miembro = MiembroFamilia(
                    id: uid,
                    nombre: nombre,
                    email: email,
                    rol: .admin,
                    familiaId: nuevaFamilia.id
                )
                
                print("📝 Creando familia con ID: \(nuevaFamilia.id)")
                // 4. Crear la familia y agregar al usuario como administrador
                try await firebaseService.crearFamilia(nuevaFamilia)
                try await firebaseService.agregarMiembroFamilia(familiaId: nuevaFamilia.id, miembro: miembro)
                
                await MainActor.run {
                    self.isAuthenticating = false
                    // El listener de Auth se encargará de cargar los datos
                }
                
                print("✅ Usuario registrado y familia creada exitosamente")
                
            } catch {
                await MainActor.run {
                    self.isAuthenticating = false
                    self.error = "Error al crear perfil: \(error.localizedDescription)"
                }
                print("❌ Error en registro: \(error)")
            }
        }
    }
    
    // MARK: - Métodos para Onboarding Familiar
    
    /// Crear una nueva familia (para el onboarding)
    @MainActor
    func crearFamilia(nombre: String, descripcion: String = "") async {
        guard let usuario = usuarioActual else {
            error = "Usuario no encontrado"
            return
        }
        
        error = nil
        
        do {
            // Crear la familia
            let familia = Familia(
                nombre: nombre,
                descripcion: descripcion,
                adminId: usuario.id
            )
            
            // Crear miembro admin
            let miembroAdmin = MiembroFamilia(
                id: usuario.id,
                nombre: usuario.nombre,
                email: usuario.email,
                rol: .admin,
                familiaId: familia.id
            )
            
            // Guardar en Firebase
            try await firebaseService.crearFamilia(familia)
            try await firebaseService.agregarMiembroFamilia(familiaId: familia.id, miembro: miembroAdmin)
            
            // Actualizar estado local
            self.familiaActual = familia
            self.miembroFamiliar = miembroAdmin
            self.needsFamilySetup = false
            
            print("✅ Familia creada exitosamente: \(familia.nombre)")
            
        } catch {
            self.error = "Error al crear la familia: \(error.localizedDescription)"
            print("❌ Error creando familia: \(error)")
        }
    }
    
    /// Unirse a una familia usando código de invitación (para el onboarding)
    @MainActor
    func unirseFamiliaConCodigo(codigo: String) async {
        guard let usuario = usuarioActual else {
            error = "Usuario no encontrado"
            return
        }
        
        error = nil
        
        do {
            // Buscar la invitación por código
            if let invitacion = try await firebaseService.buscarInvitacionPorCodigo(codigo) {
                
                // Verificar que la invitación no haya expirado
                if invitacion.fechaExpiracion > Date() {
                    
                    // Crear el miembro de la familia
                    let miembro = MiembroFamilia(
                        id: usuario.id,
                        nombre: usuario.nombre,
                        email: usuario.email,
                        rol: .miembro,
                        familiaId: invitacion.familiaId
                    )
                    
                    // Agregar el miembro a la familia
                    try await firebaseService.agregarMiembroFamilia(familiaId: invitacion.familiaId, miembro: miembro)
                    
                    // Eliminar la invitación usada
                    try await firebaseService.eliminarInvitacion(invitacion.id)
                    
                    // Cargar datos de la familia
                    let familia = try await firebaseService.obtenerFamilia(familiaId: invitacion.familiaId)
                    
                    // Actualizar estado local
                    self.familiaActual = familia
                    self.miembroFamiliar = miembro
                    self.needsFamilySetup = false
                    
                    print("✅ Usuario unido exitosamente a la familia: \(familia.nombre)")
                    
                } else {
                    self.error = "El código de invitación ha expirado"
                }
                
            } else {
                self.error = "Código de invitación inválido"
            }
            
        } catch {
            self.error = "Error al unirse a la familia: \(error.localizedDescription)"
            print("❌ Error uniéndose a familia: \(error)")
        }
    }
    
    // Funciones privadas para manejo de credenciales persistentes
    private func guardarCredenciales(email: String, contrasena: String) {
        UserDefaults.standard.set(email, forKey: "savedEmail")
        UserDefaults.standard.set(contrasena, forKey: "savedPassword")
    }
    
    // Obtener mensaje de error amigable
    private func obtenerMensajeError(_ error: Error) -> String {
        print("🚨 Firebase Error: \(error)")
        print("Error Code: \((error as NSError).code)")
        print("Error Domain: \((error as NSError).domain)")
        print("Error Description: \(error.localizedDescription)")
        
        // Detectar errores específicos de red/DNS
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("server with the specified hostname could not be found") ||
           errorDescription.contains("dns") ||
           errorDescription.contains("dnservicecreatedelegateconnection") {
            return "Error de DNS/Red: La aplicación no puede resolver nombres de dominio. Esto puede ser debido a restricciones del sandbox de macOS. Verifica los entitlements de red."
        }
        
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                return "Contraseña incorrecta. Verifica tus credenciales."
            case AuthErrorCode.userNotFound.rawValue:
                return "No existe una cuenta con este correo electrónico."
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "Este correo electrónico ya está registrado."
            case AuthErrorCode.invalidEmail.rawValue:
                return "El formato del correo electrónico no es válido."
            case AuthErrorCode.weakPassword.rawValue:
                return "La contraseña debe tener al menos 6 caracteres."
            case AuthErrorCode.networkError.rawValue:
                // Análisis más detallado del error de red
                if errorDescription.contains("could not be found") {
                    return "Error de DNS: No se puede resolver el servidor de Firebase. Verifica que la aplicación tenga permisos de red en el sandbox de macOS."
                }
                return "Error de conexión con Firebase. Verifica tu internet y configuración de red."
            case AuthErrorCode.tooManyRequests.rawValue:
                return "Demasiados intentos fallidos. Espera un momento antes de intentar nuevamente."
            case AuthErrorCode.userDisabled.rawValue:
                return "Esta cuenta ha sido deshabilitada."
            case AuthErrorCode.invalidAPIKey.rawValue:
                return "Error de configuración de Firebase. Verifica la clave API."
            case AuthErrorCode.appNotAuthorized.rawValue:
                return "La aplicación no está autorizada para usar Firebase Authentication."
            case AuthErrorCode.keychainError.rawValue:
                return """
                ❌ Error de Keychain: Firebase no puede acceder al almacén seguro de macOS.
                
                📋 Para resolverlo:
                1. Abre el proyecto en Xcode
                2. Ve a 'Signing & Capabilities'
                3. Activa 'Automatically manage signing'
                4. Selecciona tu Apple ID como Team
                5. Agrega el entitlement 'keychain-access-groups'
                
                🔧 Alternativa: Usa UserDefaults para desarrollo local (menos seguro)
                """
            case 17995: // ERROR_KEYCHAIN_ERROR específico
                let nsError = error as NSError
                if let failureReason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
                    if failureReason.contains("-34018") || failureReason.contains("required entitlement") {
                        return """
                        ❌ Error de Keychain (-34018): "A required entitlement isn't present"
                        
                        🔧 SOLUCIÓN RECOMENDADA:
                        1. En Xcode, selecciona el proyecto 'FamilOS'
                        2. Ve a pestaña "Signing & Capabilities"
                        3. Activa ✅ "Automatically manage signing"
                        4. Selecciona tu Apple ID en "Team"
                        5. Verifica que "Keychain Sharing" esté habilitado
                        6. Limpia y reconstruye: Cmd+Shift+K → Cmd+B
                        
                        📋 Si el problema persiste:
                        • Abre Terminal y ejecuta: codesign --force --deep --sign - FamilOS.app
                        • O desactiva temporalmente Firebase Keychain en configuración
                        
                        ⚠️  Este error impide que Firebase guarde tokens de autenticación seguros.
                        """
                    }
                }
                return """
                ❌ Error de acceso al Keychain (17995): Problema de configuración de entitlements.
                
                📋 Soluciones:
                1. Configura firma de código en Xcode (recomendado)
                2. O implementa almacenamiento alternativo para desarrollo
                
                ⚠️  Firebase requiere keychain para tokens de autenticación seguros
                """
            default:
                // Verificar si es error de keychain por descripción o código -34018
                let nsError = error as NSError
                if errorDescription.contains("keychain") || errorDescription.contains("secitemadd") || 
                   nsError.code == -34018 || errorDescription.contains("-34018") {
                    return """
                    ❌ Error de Keychain (-34018): "A required entitlement isn't present"
                    
                    🔧 PARA SOLUCIONARLO:
                    1. Abre Xcode → Proyecto FamilOS → "Signing & Capabilities"
                    2. Activa "Automatically manage signing"
                    3. Selecciona tu Development Team (Apple ID)
                    4. Asegúrate que "Keychain Sharing" esté habilitado
                    5. Limpia proyecto: Product → Clean Build Folder
                    6. Reconstruye: Product → Build
                    
                    💡 Causa: Firebase no puede acceder al keychain de macOS sin los entitlements correctos.
                    """
                }
                print("Error no manejado específicamente: \(authError.localizedDescription)")
                return "Error: \(authError.localizedDescription)"
            }
        }
        return error.localizedDescription
    }
    
    // Verificar si hay algún usuario registrado
    var hayUsuariosRegistrados: Bool {
        return Auth.auth().currentUser != nil
    }
    
    // Función para resetear contraseña
    func resetearContrasena(email: String, completion: @escaping (Bool, String?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, self.obtenerMensajeError(error))
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Diagnóstico de Firebase
    
    func verificarConfiguracionFirebase() -> String {
        var diagnostico = "=== Diagnóstico Firebase ===\n"
        
        // Verificar estado de red
        diagnostico += "🌐 Estado de red: \(networkStatus)\n"
        
        // Verificar si Firebase está configurado
        if let app = FirebaseApp.app() {
            diagnostico += "✅ Firebase App configurada\n"
            diagnostico += "Project ID: \(app.options.projectID ?? "No definido")\n"
            diagnostico += "API Key: \((app.options.apiKey?.isEmpty == false) ? "✅ Configurada" : "❌ Vacía")\n"
            diagnostico += "Bundle ID: \(app.options.bundleID)\n"
            diagnostico += "Database URL: \(app.options.databaseURL ?? "No definida")\n"
        } else {
            diagnostico += "❌ Firebase App NO configurada\n"
        }
        
        // Verificar Auth
        let auth = Auth.auth()
        diagnostico += "Auth configurado: \(auth.currentUser == nil ? "Sin usuario" : "Con usuario")\n"
        
        // Verificar Database
        let _ = Database.database()
        diagnostico += "Database configurado: ✅\n"
        
        // Verificar entitlements
        diagnostico += "\n=== Entitlements ===\n"
        let bundle = Bundle.main
        if let sandbox = bundle.object(forInfoDictionaryKey: "com.apple.security.app-sandbox") {
            diagnostico += "App Sandbox: \(sandbox)\n"
        }
        if let networkClient = bundle.object(forInfoDictionaryKey: "com.apple.security.network.client") {
            diagnostico += "Network Client: \(networkClient)\n"
        } else {
            diagnostico += "❌ Network Client: NO ENCONTRADO\n"
        }
        if let networkServer = bundle.object(forInfoDictionaryKey: "com.apple.security.network.server") {
            diagnostico += "Network Server: \(networkServer)\n"
        } else {
            diagnostico += "❌ Network Server: NO ENCONTRADO\n"
        }
        
        // Verificar Keychain Access Groups
        if let keychainGroups = bundle.object(forInfoDictionaryKey: "keychain-access-groups") {
            diagnostico += "Keychain Access Groups: \(keychainGroups)\n"
        } else {
            diagnostico += "❌ Keychain Access Groups: NO ENCONTRADO\n"
        }
        
        // Verificar Application Groups
        if let appGroups = bundle.object(forInfoDictionaryKey: "com.apple.security.application-groups") {
            diagnostico += "Application Groups: \(appGroups)\n"
        } else {
            diagnostico += "❌ Application Groups: NO ENCONTRADO\n"
        }
        
        return diagnostico
    }
    
    func testConexionFirebase() {
        print("🧪 Testing Firebase connection...")
        
        // Verificar estado de red primero
        if networkStatus != .satisfied {
            print("❌ Red no disponible - Status: \(networkStatus)")
            DispatchQueue.main.async {
                self.error = "Red no disponible. Estado: \(self.networkStatus)"
            }
            return
        }
        
        // Test de DNS básico
        testDNSResolution { [weak self] dnsWorking in
            if !dnsWorking {
                DispatchQueue.main.async {
                    self?.error = "❌ DNS no funciona. Problema de resolución de nombres."
                }
                return
            }
            
            // Si DNS funciona, probar Firebase
            self?.testFirebaseConnection()
        }
    }
    
    private func testDNSResolution(completion: @escaping (Bool) -> Void) {
        // Test simple de DNS resolviendo google.com
        let host = NWEndpoint.Host("google.com")
        let port = NWEndpoint.Port(80)
        let connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("✅ DNS/Network básico funcionando")
                connection.cancel()
                completion(true)
            case .failed(let error):
                print("❌ DNS/Network falló: \(error)")
                connection.cancel()
                completion(false)
            default:
                break
            }
        }
        
        connection.start(queue: networkQueue)
        
        // Timeout después de 5 segundos
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            connection.cancel()
            completion(false)
        }
    }
    
    private func testFirebaseConnection() {
        print("🔥 Testing Firebase Auth connection...")
        
        // Test de conexión usando signInAnonymously en lugar del método deprecado
        Auth.auth().signInAnonymously { authResult, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error de conexión Firebase: \(error)")
                    
                    // Analizar el tipo de error específico
                    let nsError = error as NSError
                    if nsError.domain.contains("NSURLErrorDomain") && nsError.code == -1003 {
                        self.error = "❌ DNS Error: No se puede resolver googleapis.com. Verifica tu configuración de DNS."
                    } else if nsError.code == -65563 {
                        self.error = "❌ DNS Service Error: El servicio de DNS no está funcionando. Posible problema de sandboxing."
                    } else {
                        self.error = "❌ Error Firebase: \(error.localizedDescription)"
                    }
                } else {
                    print("✅ Conexión a Firebase exitosa")
                    self.error = "✅ Conexión a Firebase exitosa"
                    
                    // Cerrar la sesión anónima inmediatamente después de la prueba
                    try? Auth.auth().signOut()
                }
            }
        }
    }
    
    // MARK: - Gestión de Familias
    
    // Crear una nueva familia
    func crearFamilia(nombre: String, descripcion: String = "") {
        guard let usuario = usuarioActual else { return }
        
        isAuthenticating = true
        error = nil
        
        Task {
            do {
                print("🎯 Iniciando creación de familia para usuario: \(usuario.nombre)")
                
                let familia = Familia(
                    nombre: nombre,
                    descripcion: descripcion,
                    adminId: usuario.id
                )
                
                // Crear el miembro administrador
                let miembro = MiembroFamilia(
                    id: usuario.id,
                    nombre: usuario.nombre,
                    email: usuario.email,
                    rol: .admin,
                    familiaId: familia.id
                )
                
                print("📋 Familia preparada: \(familia.id)")
                print("👑 Admin preparado: \(miembro.nombre) con rol \(miembro.rol)")
                
                // Crear familia y agregar al usuario como administrador
                try await firebaseService.crearFamilia(familia)
                try await firebaseService.agregarMiembroFamilia(familiaId: familia.id, miembro: miembro)
                
                print("🎉 Familia creada exitosamente!")
                
                await MainActor.run {
                    self.familiaActual = familia
                    self.miembroFamiliar = miembro
                    self.mostrarCreacionFamilia = false
                    self.isAuthenticating = false
                }
                
            } catch {
                print("❌ Error al crear familia: \(error)")
                await MainActor.run {
                    self.error = "Error al crear familia: \(error.localizedDescription)"
                    self.isAuthenticating = false
                }
            }
        }
    }
    
    // Unirse a una familia existente usando código de invitación
    func unirseFamilia(codigoInvitacion: String) {
        guard let usuario = usuarioActual else { return }
        
        isAuthenticating = true
        error = nil
        
        Task {
            do {
                // Buscar invitación por código
                if let invitacion = try await firebaseService.buscarInvitacionPorCodigo(codigoInvitacion),
                   invitacion.estado == .pendiente,
                   invitacion.fechaExpiracion > Date() {
                    
                    // Crear membresía del usuario
                    let miembro = MiembroFamilia(
                        id: usuario.id,
                        nombre: usuario.nombre,
                        email: usuario.email,
                        rol: .miembro
                    )
                    
                    try await firebaseService.agregarMiembroFamilia(familiaId: invitacion.familiaId, miembro: miembro)
                    
                    // Marcar invitación como aceptada
                    var invitacionActualizada = invitacion
                    invitacionActualizada.estado = .aceptada
                    invitacionActualizada.fechaRespuesta = Date()
                    invitacionActualizada.respondidoPor = usuario.id
                    try await firebaseService.actualizarInvitacion(invitacionActualizada)
                    
                    // Cargar datos de la familia
                    let familia = try await firebaseService.obtenerFamilia(familiaId: invitacion.familiaId)
                    
                    await MainActor.run {
                        self.familiaActual = familia
                        self.miembroFamiliar = miembro
                        self.mostrarUnirseFamilia = false
                        self.isAuthenticating = false
                    }
                    
                } else {
                    await MainActor.run {
                        self.error = "Código de invitación inválido o expirado"
                        self.isAuthenticating = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.error = "Error al unirse a la familia: \(error.localizedDescription)"
                    self.isAuthenticating = false
                }
            }
        }
    }
}
