import SwiftUI
import AppKit

struct ConfiguracionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var configuracionService = ConfiguracionService.shared
    @State private var mostrarGeneradorInvitacion = false
    @State private var codigoInvitacion = ""
    @State private var isGeneratingCode = false
    @State private var isHovered = false
    @State private var hoveredCard: String? = nil
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Estados para edición
    @State private var nombreEditable = ""
    @State private var estaEditandoNombre = false
    
    // Estados para confirmación de cambio de moneda
    @State private var mostrarConfirmacionMoneda = false
    @State private var nuevaMonedaSeleccionada: TipoMoneda?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo igual al LoginView
                backgroundView
                
                HStack(spacing: 0) {
                    // Panel izquierdo - Información de la app y usuario
                    leftPanel
                        .frame(width: geometry.size.width * 0.45)
                    
                    // Panel derecho - Configuración
                    rightPanel
                        .frame(width: geometry.size.width * 0.55)
                }
            }
        }
        .onAppear {
            nombreEditable = authViewModel.usuarioActual?.nombre ?? ""
        }
    }
    
    // MARK: - Componentes principales
    
    private var backgroundView: some View {
        ZStack {
            // Fondo base oscuro
            Color.black
                .ignoresSafeArea()
            
            // Gradiente sutil
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.1),
                    Color.black.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Elementos decorativos de fondo
            GeometryReader { geometry in
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                
                Circle()
                    .fill(Color.gray.opacity(0.02))
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.7)
            }
        }
    }
    
    private var leftPanel: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo y branding igual al LoginView
            VStack(spacing: 20) {
                // Icono principal
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.black)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("Configuración")
                        .font(.system(size: 42, weight: .light, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Gestiona tu perfil y familia")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            
            // Información del usuario con avatar
            if let usuario = authViewModel.usuarioActual {
                VStack(spacing: 20) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Text(String(usuario.nombre.prefix(1)).uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                    }
                    
                    VStack(spacing: 6) {
                        Text(usuario.nombre)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(usuario.email)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 20)
            }
            
            // Características destacadas del perfil
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "person.circle.fill", text: "Perfil personalizado")
                featureRow(icon: "dollarsign.circle.fill", text: "Configuración de moneda")
                featureRow(icon: "house.fill", text: "Gestión familiar")
                featureRow(icon: "shield.checkerboard", text: "Privacidad y seguridad")
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color.black.opacity(0.7))
    }
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Formulario de configuración
            configuracionForm
                .frame(maxWidth: 400)
                .padding(.horizontal, 60)
            
            Spacer()
        }
        .background(
            // Efecto vidrio esmerilado
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .opacity(0.8)
        )
    }
    
    private var configuracionForm: some View {
        VStack(spacing: 32) {
            // Header del formulario
            VStack(spacing: 8) {
                Text("Mi Perfil")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white)
                
                Text("Personaliza tu experiencia")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
            
            // Campos de configuración
            VStack(spacing: 24) {
                // Nombre editable
                VStack(alignment: .leading, spacing: 8) {
                    if estaEditandoNombre {
                        modernTextField(
                            placeholder: "Nombre completo",
                            text: $nombreEditable,
                            icon: "person.fill",
                            isSecure: false
                        )
                        
                        HStack(spacing: 12) {
                            Button(action: guardarNombre) {
                                Text("Guardar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                estaEditandoNombre = false
                                nombreEditable = authViewModel.usuarioActual?.nombre ?? ""
                            }) {
                                Text("Cancelar")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        modernInfoField(
                            placeholder: "Nombre completo",
                            value: nombreEditable,
                            icon: "person.fill",
                            action: { estaEditandoNombre = true }
                        )
                    }
                }
                
                // Email (solo lectura)
                modernInfoField(
                    placeholder: "Correo electrónico", 
                    value: authViewModel.usuarioActual?.email ?? "",
                    icon: "envelope.fill"
                )
                
                // Selector de moneda
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        
                        Text("Moneda Preferida")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Menu {
                            ForEach(TipoMoneda.allCases) { moneda in
                                Button(action: { 
                                    if moneda != configuracionService.monedaSeleccionada {
                                        nuevaMonedaSeleccionada = moneda
                                        configuracionService.cambiarMoneda(moneda)
                                        mostrarConfirmacionMoneda = true
                                        
                                        // Ocultar el mensaje después de 3 segundos
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
                                    .foregroundColor(.white)
                                    .fontWeight(.medium)
                                Text(configuracionService.monedaSeleccionada.simbolo)
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
            
            // Información familiar (si aplica)
            if let familia = authViewModel.familiaActual,
               let miembro = authViewModel.miembroFamiliar {
                
                VStack(spacing: 16) {
                    // Información de la familia
                    modernInfoField(
                        placeholder: "Familia",
                        value: familia.nombre,
                        icon: "house.fill"
                    )
                    
                    HStack(spacing: 16) {
                        modernInfoField(
                            placeholder: "Tu rol",
                            value: miembro.rol.rawValue.capitalized,
                            icon: "person.badge.key.fill"
                        )
                        
                        modernInfoField(
                            placeholder: "Miembro desde",
                            value: miembro.fechaUnion.formatted(.dateTime.day().month().year()),
                            icon: "calendar.circle.fill"
                        )
                    }
                    
                    // Botón de invitación para administradores
                    if miembro.rol == .admin {
                        Button(action: generarCodigoInvitacion) {
                            HStack {
                                if isGeneratingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 16))
                                    Text("Invitar Miembro")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isGeneratingCode ? Color.gray.opacity(0.3) : Color.white)
                            )
                            .foregroundColor(isGeneratingCode ? .gray : .black)
                        }
                        .disabled(isGeneratingCode)
                        .buttonStyle(.plain)
                        
                        if !codigoInvitacion.isEmpty {
                            codigoInvitacionView
                        }
                    }
                }
            }
            
            // Mensaje de confirmación de cambio de moneda
            if mostrarConfirmacionMoneda {
                mensajeConfirmacionMoneda
            }
            
            // Botón de cerrar sesión
            Button(action: {
                authViewModel.logout()
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16))
                    Text("Cerrar Sesión")
                        .font(.system(size: 16, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.8))
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }
    // MARK: - Componentes auxiliares estilo LoginView
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
    
    private func modernTextField(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        isSecure: Bool,
        hasSecureToggle: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(placeholder, text: text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private func modernInfoField(
        placeholder: String,
        value: String,
        icon: String,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                Text(value.isEmpty ? placeholder : value)
                    .font(.system(size: 16))
                    .foregroundColor(value.isEmpty ? .gray : .white)
                
                Spacer()
                
                if let action = action {
                    Button("Editar") {
                        action()
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var codigoInvitacionView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Código generado")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text(codigoInvitacion)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.4), lineWidth: 1)
                            )
                    )
                
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(codigoInvitacion, forType: .string)
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 14))
                        Text("Copiar código")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Text("⏰ Expira en 24 horas")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Funciones auxiliares
    
    private func guardarNombre() {
        guard !nombreEditable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Aquí deberías implementar la lógica para actualizar el nombre en Firebase
        // Por ahora solo actualizamos el estado local
        Task {
            do {
                // TODO: Implementar actualización en Firebase
                await MainActor.run {
                    estaEditandoNombre = false
                }
            } catch {
                print("Error al actualizar nombre: \(error)")
            }
        }
    }
    
    private func generarCodigoInvitacion() {
        guard let familiaId = authViewModel.familiaActual?.id,
              let usuarioId = authViewModel.usuarioActual?.id else { return }
        
        isGeneratingCode = true
        
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
                }
            }
        }
    }
    
    // MARK: - Mensaje de confirmación de cambio de moneda
    
    private var mensajeConfirmacionMoneda: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Moneda actualizada")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let nuevaMoneda = nuevaMonedaSeleccionada {
                    Text("Se cambió a \(nuevaMoneda.nombre) (\(nuevaMoneda.simbolo))")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: {
                mostrarConfirmacionMoneda = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                )
        )
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: mostrarConfirmacionMoneda)
    }
}

#Preview {
    ConfiguracionView()
        .environmentObject(AuthViewModel())
}
