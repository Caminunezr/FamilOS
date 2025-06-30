import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Network

@main
struct FamilOSApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        FirebaseApp.configure()
        setupLogging()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onAppear {
                    checkSystemStatus()
                }
        }
    }
    
    private func setupLogging() {
        // Configurar logging de Firebase para debugging
        #if DEBUG
        print("🔥 Firebase configurado correctamente")
        print("📱 Configurando logging de debug")
        #endif
    }
    
    private func checkSystemStatus() {
        print("🔍 Verificando estado del sistema...")
        
        // Verificar conectividad de red
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    print("✅ Conexión a internet disponible")
                    self.testFirebaseConnection()
                } else {
                    print("❌ Sin conexión a internet")
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        // Detener monitor después de 10 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            monitor.cancel()
        }
        
        // Información sobre entitlements
        print("ℹ️ Los entitlements están configurados en build time en FamilOS.entitlements")
        print("📝 Entitlements incluyen: network, keychain, app groups, sandbox, etc.")
    }
    
    private func testFirebaseConnection() {
        #if DEBUG
        print("🔥 Probando conexión con Firebase...")
        
        let ref = Database.database().reference().child("test")
        ref.setValue(["timestamp": ServerValue.timestamp(), "status": "connected"]) { error, _ in
            if let error = error {
                print("❌ Error escribiendo a Firebase: \(error.localizedDescription)")
                self.analyzeFirebaseError(error)
            } else {
                print("✅ Escritura a Firebase exitosa")
                
                // Probar lectura
                ref.observeSingleEvent(of: .value) { snapshot in
                    if snapshot.exists() {
                        print("✅ Lectura de Firebase exitosa")
                    } else {
                        print("❌ No se pudo leer de Firebase")
                    }
                }
            }
        }
        #endif
    }
    
    private func analyzeFirebaseError(_ error: Error) {
        let nsError = error as NSError
        switch nsError.code {
        case -3:
            print("💡 Error de permisos: Verificar reglas de Firebase Database")
        case -1:
            print("💡 Error de red: Verificar conectividad a internet")
        case -4:
            print("💡 Database desconectado: Verificar configuración")
        default:
            print("💡 Error código \(nsError.code): \(nsError.localizedDescription)")
        }
    }
}