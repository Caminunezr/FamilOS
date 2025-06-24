import Foundation
import SwiftUI
import LocalAuthentication

class AuthViewModel: ObservableObject {
    @Published var usuarioActual: Usuario?
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var error: String?
    @Published var mostrarRegistro: Bool = false
    
    // Para almacenar usuarios de prueba (en una aplicación real usaríamos Core Data o iCloud)
    private var usuarios: [Usuario] = []
    
    init() {
        #if DEBUG
        // Solo en modo debug, creamos usuarios de prueba
        let usuarioPrincipal = Usuario(
            nombre: "Usuario Principal",
            email: "usuario@familos.app",
            contrasena: "123456",
            esPrincipal: true
        )
        
        let usuarioSecundario = Usuario(
            nombre: "Usuario Secundario",
            email: "secundario@familos.app",
            contrasena: "123456",
            esPrincipal: false
        )
        
        usuarios = [usuarioPrincipal, usuarioSecundario]
        
        // Verificar si hay credenciales guardadas
        verificarCredencialesGuardadas()
        #endif
    }
    
    // Inicio de sesión con email y contraseña
    func login(email: String, contrasena: String) {
        isAuthenticating = true
        error = nil
        
        // Simular una demora de red
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Buscar usuario que coincida
            if let usuario = self.usuarios.first(where: { $0.email == email && $0.contrasena == contrasena }) {
                self.usuarioActual = usuario
                self.isAuthenticated = true
                self.isAuthenticating = false
                
                // Guardar credenciales
                self.guardarCredenciales(email: email, contrasena: contrasena)
            } else {
                self.error = "Credenciales incorrectas. Por favor intenta de nuevo."
                self.isAuthenticating = false
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
        usuarioActual = nil
        isAuthenticated = false
    }
    
    // Registrar un nuevo usuario
    func registrarUsuario(nombre: String, email: String, contrasena: String) {
        isAuthenticating = true
        error = nil
        
        // Verificar si el email ya existe
        if usuarios.contains(where: { $0.email == email }) {
            error = "Este correo ya está registrado. Por favor usa otro."
            isAuthenticating = false
            return
        }
        
        // Simular una demora de red
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Crear nuevo usuario
            let nuevoUsuario = Usuario(
                nombre: nombre,
                email: email,
                contrasena: contrasena,
                esPrincipal: self.usuarios.isEmpty // Si es el primer usuario, es principal
            )
            
            // Agregar a la lista
            self.usuarios.append(nuevoUsuario)
            
            // Autenticar al usuario recién registrado
            self.usuarioActual = nuevoUsuario
            self.isAuthenticated = true
            self.isAuthenticating = false
            
            // Guardar credenciales
            self.guardarCredenciales(email: email, contrasena: contrasena)
        }
    }
    
    // Funciones privadas para manejo de credenciales persistentes
    private func guardarCredenciales(email: String, contrasena: String) {
        UserDefaults.standard.set(email, forKey: "savedEmail")
        UserDefaults.standard.set(contrasena, forKey: "savedPassword")
    }
    
    private func verificarCredencialesGuardadas() {
        if let savedEmail = UserDefaults.standard.string(forKey: "savedEmail"),
           let savedPassword = UserDefaults.standard.string(forKey: "savedPassword") {
            // En lugar de hacer login automático, solo guardamos las credenciales
            // para usarlas con autenticación biométrica
            return
        }
    }
    
    // Verificar si hay algún usuario registrado
    var hayUsuariosRegistrados: Bool {
        return !usuarios.isEmpty
    }
}
