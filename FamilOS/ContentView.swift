import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var seleccionTab = 0
    
    var body: some View {
        TabView(selection: $seleccionTab) {
            CuentasView()
                .tabItem {
                    Label("Cuentas", systemImage: "doc.text.fill")
                }
                .tag(0)
            
            PresupuestoView()
                .tabItem {
                    Label("Presupuesto", systemImage: "chart.pie.fill")
                }
                .tag(1)
            
            HistorialView()
                .tabItem {
                    Label("Historial", systemImage: "clock.fill")
                }
                .tag(2)
            
            ConfiguracionView()
                .tabItem {
                    Label("Configuración", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    if let usuario = authViewModel.usuarioActual {
                        Text(usuario.nombre)
                            .font(.headline)
                        
                        Divider()
                    }
                    
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.circle")
                }
            }
        }
    }
}

// Vista de Placeholder para Historial (que implementaremos después)
struct HistorialView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .padding()
                    .foregroundColor(.green)
                
                Text("Módulo de Historial")
                    .font(.title)
                
                Text("Analiza tus gastos históricos y tendencias")
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .navigationTitle("Historial")
        }
    }
}

// Vista de Configuración
struct ConfiguracionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("tema") private var temaModo: Int = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Perfil")) {
                    if let usuario = authViewModel.usuarioActual {
                        Text(usuario.nombre)
                            .font(.headline)
                        Text(usuario.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Apariencia")) {
                    Picker("Tema", selection: $temaModo) {
                        Text("Sistema").tag(0)
                        Text("Claro").tag(1)
                        Text("Oscuro").tag(2)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Acerca de")) {
                    HStack {
                        Text("Versión")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Enviar comentarios") {
                        // Acción para enviar comentarios
                    }
                    
                    Button("Cerrar sesión") {
                        authViewModel.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Configuración")
        }
    }
}

#Preview {
    ContentView()
}
