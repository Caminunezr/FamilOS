import SwiftUI
import AppKit

struct ConfiguracionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var mostrarGeneradorInvitacion = false
    @State private var codigoInvitacion = ""
    @State private var isGeneratingCode = false
    
    var body: some View {
        NavigationStack {
            List {
                // Información de la familia
                if let familia = authViewModel.familiaActual,
                   let miembro = authViewModel.miembroFamiliar {
                    
                    Section("Información Familiar") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(familia.nombre)
                                .font(.headline)
                            
                            if !familia.descripcion.isEmpty {
                                Text(familia.descripcion)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Tu rol:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(miembro.rol.rawValue.capitalized)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Miembro desde:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(miembro.fechaUnion, style: .date)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Gestión de invitaciones (solo para administradores)
                    if miembro.rol == .admin {
                        Section("Gestión Familiar") {
                            Button(action: {
                                generarCodigoInvitacion()
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Invitar Miembro")
                                    Spacer()
                                    if isGeneratingCode {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                }
                            }
                            .disabled(isGeneratingCode)
                            
                            if !codigoInvitacion.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Código de Invitación:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text(codigoInvitacion)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            NSPasteboard.general.clearContents()
                                            NSPasteboard.general.setString(codigoInvitacion, forType: .string)
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                        }
                                    }
                                    
                                    Text("Comparte este código para invitar nuevos miembros")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                
                // Información del usuario
                if let usuario = authViewModel.usuarioActual {
                    Section("Información Personal") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Nombre:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(usuario.nombre)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Email:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(usuario.email)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Acciones
                Section("Acciones") {
                    Button(action: {
                        authViewModel.logout()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Cerrar Sesión")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // Información de la app
                Section("Información") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FamilOS")
                            .font(.headline)
                        Text("Gestión Financiera Familiar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Versión 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Configuración")
        }
    }
    
    private func generarCodigoInvitacion() {
        guard let familiaId = authViewModel.familiaActual?.id,
              let usuarioId = authViewModel.usuarioActual?.id else { return }
        
        isGeneratingCode = true
        
        // Crear una invitación temporal
        let firebaseService = FirebaseService()
        
        let invitacion = InvitacionFamiliar(
            familiaId: familiaId,
            familiaName: authViewModel.familiaActual?.nombre ?? "Familia",
            invitadoPor: usuarioId,
            invitadoEmail: ""
        )
        
        Task {
            do {
                try await firebaseService.crearInvitacion(invitacion)
                
                await MainActor.run {
                    self.codigoInvitacion = invitacion.codigo
                    self.isGeneratingCode = false
                }
            } catch {
                await MainActor.run {
                    self.isGeneratingCode = false
                    // Aquí podrías mostrar un error
                }
            }
        }
    }
}

#Preview {
    ConfiguracionView()
}
