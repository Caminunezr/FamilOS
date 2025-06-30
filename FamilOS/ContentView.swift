import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated && authViewModel.familiaActual != nil {
                MainTabView()
                    .environmentObject(authViewModel)
            } else if authViewModel.isAuthenticated && authViewModel.familiaActual == nil {
                ConfiguracionFamiliarView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

// Vista para configurar la familia (crear o unirse)
struct ConfiguracionFamiliarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var nombreFamilia = ""
    @State private var descripcionFamilia = ""
    @State private var codigoInvitacion = ""
    @State private var modoCreacion = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Configurar Familia")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Para usar FamilOS necesitas crear una familia o unirte a una existente")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Picker("Modo", selection: $modoCreacion) {
                    Text("Crear Familia").tag(true)
                    Text("Unirse a Familia").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if modoCreacion {
                    // Formulario para crear familia
                    VStack(spacing: 15) {
                        TextField("Nombre de la familia", text: $nombreFamilia)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Descripción (opcional)", text: $descripcionFamilia)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            authViewModel.crearFamilia(nombre: nombreFamilia, descripcion: descripcionFamilia)
                        }) {
                            HStack {
                                if authViewModel.isAuthenticating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text("Crear Familia")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(nombreFamilia.isEmpty || authViewModel.isAuthenticating)
                    }
                } else {
                    // Formulario para unirse a familia
                    VStack(spacing: 15) {
                        TextField("Código de invitación", text: $codigoInvitacion)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            authViewModel.unirseFamilia(codigoInvitacion: codigoInvitacion)
                        }) {
                            HStack {
                                if authViewModel.isAuthenticating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.2.fill")
                                }
                                Text("Unirse a Familia")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(codigoInvitacion.isEmpty || authViewModel.isAuthenticating)
                    }
                }
                
                if let error = authViewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cerrar Sesión") {
                        authViewModel.logout()
                    }
                }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var cuentasViewModel = CuentasViewModel()
    @StateObject private var presupuestoViewModel = PresupuestoViewModel()
    @State private var seleccionTab = 0
    
    var body: some View {
        TabView(selection: $seleccionTab) {
            DashboardIntegradoView()
                .environmentObject(cuentasViewModel)
                .environmentObject(presupuestoViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            CuentasView()
                .environmentObject(cuentasViewModel)
                .tabItem {
                    Label("Cuentas", systemImage: "doc.text.fill")
                }
                .tag(1)
            
            PresupuestoView()
                .environmentObject(presupuestoViewModel)
                .tabItem {
                    Label("Presupuesto", systemImage: "chart.pie.fill")
                }
                .tag(2)
            
            HistorialView()
                .tabItem {
                    Label("Historial", systemImage: "clock.fill")
                }
                .tag(3)
            
            ConfiguracionView()
                .tabItem {
                    Label("Configuración", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .onAppear {
            configurarViewModels()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    if let usuario = authViewModel.usuarioActual {
                        Text(usuario.nombre)
                            .font(.headline)
                        
                        if let familia = authViewModel.familiaActual {
                            Text("Familia: \(familia.nombre)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
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
    
    private func configurarViewModels() {
        guard let familiaId = authViewModel.familiaActual?.id else { return }
        
        // Configurar la integración entre ViewModels
        presupuestoViewModel.configurarIntegracionCuentas(cuentasViewModel)
        
        // Configurar los ViewModels con la familia actual
        cuentasViewModel.configurarFamilia(familiaId)
        presupuestoViewModel.configurarFamilia(familiaId)
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



#Preview {
    ContentView()
}
