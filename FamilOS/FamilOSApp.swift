//
//  FamilOSApp.swift
//  FamilOS
//
//  Created by Camilo Nunez on 23-06-25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import Network

@main
struct FamilOSApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Configurar Firebase con verificación de errores
        if FirebaseApp.app() == nil {
            print("Configurando Firebase...")
            FirebaseApp.configure()
            print("Firebase configurado exitosamente")
        } else {
            print("Firebase ya estaba configurado")
        }
        
        // Verificar la configuración de Firebase
        if let app = FirebaseApp.app() {
            print("Firebase App configurada: \(app.name)")
            print("Project ID: \(app.options.projectID ?? "No definido")")
            if let apiKey = app.options.apiKey {
                print("API Key: \(apiKey.prefix(10))...")
            } else {
                print("API Key: No definido")
            }
        }
        
        // Configurar Firebase Database para usar emulador en desarrollo (opcional)
        #if DEBUG
        // Database.database().useEmulator(withHost: "localhost", port: 9000)
        #endif
        
        // Ejecutar diagnósticos de red al inicializar
        diagnosticarConectividadRed()
    }
    
    // MARK: - Funciones de Diagnóstico de Red
    
    /// Verifica la conectividad de red básica
    private func diagnosticarConectividadRed() {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("✅ Red disponible")
                    print("Tipo de conexión: \(self.descripcionTipoRed(path))")
                    
                    // Realizar diagnósticos específicos de Firebase
                    self.diagnosticarFirebase()
                } else {
                    print("❌ Red no disponible")
                    print("Razón: \(self.descripcionEstadoRed(path.status))")
                }
            }
        }
        
        monitor.start(queue: queue)
        
        // Detener el monitor después de 5 segundos para no mantenerlo activo indefinidamente
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            monitor.cancel()
        }
    }
    
    /// Describe el tipo de conexión de red
    private func descripcionTipoRed(_ path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "WiFi"
        } else if path.usesInterfaceType(.cellular) {
            return "Celular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "Ethernet"
        } else {
            return "Otro"
        }
    }
    
    /// Describe el estado de la red
    private func descripcionEstadoRed(_ status: NWPath.Status) -> String {
        switch status {
        case .satisfied:
            return "Conexión satisfactoria"
        case .unsatisfied:
            return "Sin conexión"
        case .requiresConnection:
            return "Requiere conexión"
        @unknown default:
            return "Estado desconocido"
        }
    }
    
    /// Realiza diagnósticos específicos de Firebase
    private func diagnosticarFirebase() {
        print("\n🔥 Iniciando diagnósticos de Firebase...")
        
        // Verificar configuración básica
        guard let app = FirebaseApp.app() else {
            print("❌ Firebase App no está configurada")
            return
        }
        
        print("✅ Firebase App configurada: \(app.name)")
        
        // Verificar configuración de opciones
        let options = app.options
        print("Project ID: \(options.projectID ?? "❌ No definido")")
        print("API Key: \(options.apiKey != nil ? "✅ Configurado" : "❌ No definido")")
        print("Database URL: \(options.databaseURL ?? "❌ No definido")")
        print("Storage Bucket: \(options.storageBucket ?? "❌ No definido")")
        
        // Intentar una conexión de prueba a Firebase Auth
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                print("✅ Usuario autenticado: \(user.uid)")
            } else {
                print("ℹ️ No hay usuario autenticado")
            }
        }
        
        // Probar conectividad con Firebase Database
        let ref = Database.database().reference()
        ref.child("test").setValue("connection_test") { error, _ in
            if let error = error {
                print("❌ Error conectando con Firebase Database: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("Código de error: \(nsError.code)")
                    print("Dominio de error: \(nsError.domain)")
                    if let userInfo = nsError.userInfo as? [String: Any] {
                        print("Información adicional: \(userInfo)")
                    }
                }
            } else {
                print("✅ Conexión exitosa con Firebase Database")
                // Limpiar el test
                ref.child("test").removeValue()
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(colorScheme)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
    
    // Implementación básica para preferencia de tema
    private var colorScheme: ColorScheme? {
        let temaModo = UserDefaults.standard.integer(forKey: "tema")
        switch temaModo {
        case 1: return .light
        case 2: return .dark
        default: return nil // Seguir tema del sistema
        }
    }
}
