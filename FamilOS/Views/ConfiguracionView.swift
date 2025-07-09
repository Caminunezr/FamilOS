import SwiftUI

struct ConfiguracionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var configuracionService = ConfiguracionService.shared
    @State private var nombreTemp: String = ""
    @State private var editandoNombre = false
    @State private var mostrarCodigoInvitacion = false
    @State private var codigoInvitacion: String = ""
    @State private var notificacionesHabilitadas = true
    @State private var mostrarConfirmacionMoneda = false
    @State private var nuevaMonedaSeleccionada: TipoMoneda?
    @State private var mostrarAlertaCerrarSesion = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header del perfil
                    headerPerfil
                    
                    // Configuración principal
                    configuracionPrincipal
                    
                    // Configuración de familia (si aplica)
                    if let _ = authViewModel.familiaActual {
                        configuracionFamilia
                    }
                    
                    // Acciones importantes
                    accionesImportantes
                    
                    // Mensaje de confirmación de moneda
                    if mostrarConfirmacionMoneda {
                        mensajeConfirmacionMoneda
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Configuración")
            .background(.regularMaterial)
            .onAppear {
                nombreTemp = authViewModel.usuarioActual?.nombre ?? ""
            }
            .alert("Cerrar Sesión", isPresented: $mostrarAlertaCerrarSesion) {
                Button("Cancelar", role: .cancel) { }
                Button("Cerrar Sesión", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("¿Estás seguro de que quieres cerrar sesión?")
            }
            .sheet(isPresented: $mostrarCodigoInvitacion) {
                CodigoInvitacionSheet(codigo: codigoInvitacion)
            }
        }
    }
    
    // MARK: - Subvistas principales
    
    private var headerPerfil: some View {
        VStack(spacing: 16) {
            // Avatar del usuario
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .overlay {
                    Text(iniciales)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
            
            // Información del usuario
            VStack(spacing: 8) {
                if editandoNombre {
                    campoEdicionNombre
                } else {
                    infoUsuario
                }
                
                if let usuario = authViewModel.usuarioActual {
                    Text(usuario.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private var configuracionPrincipal: some View {
        VStack(spacing: 16) {
            Text("Configuración General")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Configuración de moneda
                configuracionMoneda
                
                // Configuración de notificaciones
                configuracionNotificaciones
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private var configuracionFamilia: some View {
        VStack(spacing: 16) {
            Text("Configuración de Familia")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                // Información de la familia
                infoFamilia
                
                // Código de invitación (solo admin)
                if esAdministrador {
                    botonCodigoInvitacion
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private var accionesImportantes: some View {
        VStack(spacing: 16) {
            Text("Acciones")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Botón de cerrar sesión
            botonCerrarSesion
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Componentes específicos
    
    private var iniciales: String {
        guard let nombre = authViewModel.usuarioActual?.nombre, !nombre.isEmpty else {
            return "?"
        }
        
        let componentes = nombre.split(separator: " ")
        
        if componentes.count >= 2 {
            let primera = String(componentes[0].prefix(1))
            let segunda = String(componentes[1].prefix(1))
            return "\(primera)\(segunda)".uppercased()
        } else {
            return String(nombre.prefix(2)).uppercased()
        }
    }
    
    private var esAdministrador: Bool {
        authViewModel.miembroFamiliar?.rol == .admin
    }
    
    private var campoEdicionNombre: some View {
        VStack(spacing: 12) {
            TextField("Nombre completo", text: $nombreTemp)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
            
            HStack(spacing: 12) {
                Button("Cancelar") {
                    nombreTemp = authViewModel.usuarioActual?.nombre ?? ""
                    editandoNombre = false
                }
                .buttonStyle(.bordered)
                
                Button("Guardar") {
                    Task {
                        await guardarNombre()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(nombreTemp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private var infoUsuario: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(authViewModel.usuarioActual?.nombre ?? "Usuario")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let familia = authViewModel.familiaActual,
                   let miembro = authViewModel.miembroFamiliar {
                    Text("\(miembro.rol.rawValue.capitalized) de \(familia.nombre)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button("Editar") {
                editandoNombre = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    private var configuracionMoneda: some View {
        HStack {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Moneda")
                    .font(.headline)
                
                Text("Configura tu moneda preferida")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Menu {
                ForEach(TipoMoneda.allCases) { moneda in
                    Button(action: {
                        if moneda != configuracionService.monedaSeleccionada {
                            nuevaMonedaSeleccionada = moneda
                            configuracionService.cambiarMoneda(moneda)
                            mostrarConfirmacionMoneda = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                mostrarConfirmacionMoneda = false
                            }
                        }
                    }) {
                        HStack {
                            Text(moneda.bandera)
                            Text(moneda.nombre)
                            Text("(\(moneda.simbolo))")
                                .foregroundColor(.secondary)
                            if moneda == configuracionService.monedaSeleccionada {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(configuracionService.monedaSeleccionada.bandera)
                    Text(configuracionService.monedaSeleccionada.codigo)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var configuracionNotificaciones: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Notificaciones")
                    .font(.headline)
                
                Text("Recibe alertas importantes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $notificacionesHabilitadas)
                .labelsHidden()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var infoFamilia: some View {
        VStack(spacing: 12) {
            if let familia = authViewModel.familiaActual,
               let miembro = authViewModel.miembroFamiliar {
                
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Familia: \(familia.nombre)")
                            .font(.headline)
                        
                        Text("Tu rol: \(miembro.rol.rawValue.capitalized)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Miembro desde")
                            .font(.headline)
                        
                        Text(miembro.fechaUnion.formatted(.dateTime.day().month().year()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                }
            }
        }
    }
    
    private var botonCodigoInvitacion: some View {
        Button(action: {
            Task {
                await generarCodigoInvitacion()
            }
        }) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invitar Miembro")
                        .font(.headline)
                    
                    Text("Genera un código de invitación")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var botonCerrarSesion: some View {
        Button(action: {
            mostrarAlertaCerrarSesion = true
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cerrar Sesión")
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    Text("Salir de la aplicación")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Funciones auxiliares
    
    private func guardarNombre() async {
        guard !nombreTemp.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // TODO: Implementar actualización en Firebase
        await MainActor.run {
            editandoNombre = false
        }
    }
    
    private func generarCodigoInvitacion() async {
        guard let familiaId = authViewModel.familiaActual?.id,
              let usuarioId = authViewModel.usuarioActual?.id else { return }
        
        let firebaseService = FirebaseService()
        
        let invitacion = InvitacionFamiliar(
            familiaId: familiaId,
            familiaName: authViewModel.familiaActual?.nombre ?? "Familia",
            invitadoPor: usuarioId,
            invitadoEmail: ""
        )
        
        do {
            try await firebaseService.crearInvitacion(invitacion)
            
            await MainActor.run {
                self.codigoInvitacion = invitacion.codigo
                self.mostrarCodigoInvitacion = true
            }
        } catch {
            print("Error al generar código: \(error)")
        }
    }
    
    private var mensajeConfirmacionMoneda: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Moneda actualizada")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let nuevaMoneda = nuevaMonedaSeleccionada {
                    Text("Se cambió a \(nuevaMoneda.nombre) (\(nuevaMoneda.simbolo))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                mostrarConfirmacionMoneda = false
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.1))
                .stroke(.green.opacity(0.3), lineWidth: 1)
        }
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: mostrarConfirmacionMoneda)
    }
}

// MARK: - Vista del código de invitación

struct CodigoInvitacionSheet: View {
    let codigo: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                VStack(spacing: 16) {
                    Text("Código de Invitación")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Comparte este código con el miembro que quieres invitar a tu familia")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Text(codigo)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.opacity(0.1))
                                .stroke(.blue.opacity(0.3), lineWidth: 1)
                        }
                        .textSelection(.enabled)
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(codigo, forType: .string)
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Copiar código")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                Text("⏰ El código expira en 24 horas")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Invitación")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ConfiguracionView()
        .environmentObject(AuthViewModel())
}
