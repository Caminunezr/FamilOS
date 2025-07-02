import SwiftUI
import AppKit

struct ConfiguracionView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var mostrarGeneradorInvitacion = false
    @State private var codigoInvitacion = ""
    @State private var isGeneratingCode = false
    @State private var isHovered = false
    @State private var hoveredCard: String? = nil
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo moderno con gradiente
                backgroundView
                
                HStack(spacing: 0) {
                    // Panel izquierdo - Información de la app y usuario
                    leftPanel
                        .frame(width: geometry.size.width * 0.35)
                    
                    // Panel derecho - Configuración
                    rightPanel
                        .frame(width: geometry.size.width * 0.65)
                }
            }
        }
    }
    
    // MARK: - Componentes de la vista
    
    private var backgroundView: some View {
        ZStack {
            // Fondo base con gradiente mejorado
            if colorScheme == .dark {
                Color.black
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(NSColor.windowBackgroundColor),
                        Color.gray.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Gradiente principal más elegante
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color.purple.opacity(0.15) : Color.blue.opacity(0.08),
                    colorScheme == .dark ? Color.blue.opacity(0.1) : Color.purple.opacity(0.05),
                    colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Elementos decorativos mejorados con animación
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.white.opacity(0.05) : Color.blue.opacity(0.08),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.3)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.purple.opacity(0.03) : Color.purple.opacity(0.06),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.7)
                    .scaleEffect(isAnimating ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var leftPanel: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo y branding mejorado
            VStack(spacing: 25) {
                // Icono principal con mejor diseño
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colorScheme == .dark ? Color.white.opacity(0.9) : Color.blue,
                                    colorScheme == .dark ? Color.gray.opacity(0.7) : Color.purple.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 85, height: 85)
                        .shadow(
                            color: colorScheme == .dark ? .white.opacity(0.2) : .blue.opacity(0.4),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                    
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                }
                .scaleEffect(hoveredCard == "logo" ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: hoveredCard)
                .onHover { hovering in
                    hoveredCard = hovering ? "logo" : nil
                }
                
                VStack(spacing: 12) {
                    Text("Configuración")
                        .font(.system(size: 36, weight: .thin, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("Gestiona tu perfil y familia")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            
            // Información del usuario mejorada
            if let usuario = authViewModel.usuarioActual {
                VStack(spacing: 20) {
                    // Avatar con animación
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.9),
                                        Color.purple.opacity(0.7),
                                        Color.pink.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 75, height: 75)
                            .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                        
                        Text(String(usuario.nombre.prefix(1)).uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(hoveredCard == "avatar" ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hoveredCard)
                    .onHover { hovering in
                        hoveredCard = hovering ? "avatar" : nil
                    }
                    
                    VStack(spacing: 6) {
                        Text(usuario.nombre)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(usuario.email)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            colorScheme == .dark ? Color.white.opacity(0.15) : Color.blue.opacity(0.3),
                                            colorScheme == .dark ? Color.gray.opacity(0.1) : Color.purple.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 15, x: 0, y: 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 35)
        .background(
            ZStack {
                if colorScheme == .dark {
                    Color.black.opacity(0.8)
                } else {
                    Color.white.opacity(0.9)
                }
                
                // Gradiente sutil en el panel
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color.purple.opacity(0.1) : Color.blue.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
    }
    
    private var rightPanel: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 30) {
                
                // Información de la familia
                if let familia = authViewModel.familiaActual,
                   let miembro = authViewModel.miembroFamiliar {
                    
                    modernCard(
                        title: "Información Familiar",
                        icon: "house.fill",
                        iconColor: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(familia.nombre)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                if !familia.descripcion.isEmpty {
                                    Text(familia.descripcion)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            VStack(spacing: 12) {
                                infoRow(
                                    icon: "person.circle.fill",
                                    title: "Tu rol",
                                    value: miembro.rol.rawValue.capitalized,
                                    valueColor: miembro.rol == .admin ? .blue : .green
                                )
                                
                                infoRow(
                                    icon: "calendar.circle.fill",
                                    title: "Miembro desde",
                                    value: miembro.fechaUnion.formatted(date: .abbreviated, time: .omitted),
                                    valueColor: .secondary
                                )
                            }
                        }
                    }
                    
                    // Gestión de invitaciones (solo para administradores)
                    if miembro.rol == .admin {
                        modernCard(
                            title: "Gestión Familiar",
                            icon: "person.2.fill",
                            iconColor: .purple
                        ) {
                            VStack(spacing: 20) {
                                modernButton(
                                    title: "Invitar Miembro",
                                    icon: "person.badge.plus",
                                    isLoading: isGeneratingCode,
                                    action: generarCodigoInvitacion
                                )
                                
                                if !codigoInvitacion.isEmpty {
                                    invitationCodeView
                                }
                            }
                        }
                    }
                }
                
                // Información personal
                if let usuario = authViewModel.usuarioActual {
                    modernCard(
                        title: "Información Personal",
                        icon: "person.fill",
                        iconColor: .green
                    ) {
                        VStack(spacing: 12) {
                            infoRow(
                                icon: "person.circle.fill",
                                title: "Nombre",
                                value: usuario.nombre,
                                valueColor: .primary
                            )
                            
                            infoRow(
                                icon: "envelope.circle.fill",
                                title: "Email",
                                value: usuario.email,
                                valueColor: .primary
                            )
                        }
                    }
                }
                
                // Acciones
                modernCard(
                    title: "Acciones",
                    icon: "gear",
                    iconColor: .orange
                ) {
                    VStack(spacing: 16) {
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            HStack(spacing: 14) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Cerrar Sesión")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.red,
                                                    Color.red.opacity(0.8),
                                                    Color.pink.opacity(0.7)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
                                    
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(hoveredCard == "logout" ? 1.02 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: hoveredCard)
                        .onHover { hovering in
                            hoveredCard = hovering ? "logout" : nil
                        }
                    }
                }
                
                // Información de la app
                modernCard(
                    title: "Información de la App",
                    icon: "info.circle.fill",
                    iconColor: .gray
                ) {
                    VStack(spacing: 12) {
                        infoRow(
                            icon: "app.badge.fill",
                            title: "Aplicación",
                            value: "FamilOS",
                            valueColor: .primary
                        )
                        
                        infoRow(
                            icon: "tag.circle.fill",
                            title: "Versión",
                            value: "1.0.0",
                            valueColor: .secondary
                        )
                        
                        infoRow(
                            icon: "hammer.circle.fill",
                            title: "Build",
                            value: "2025.1",
                            valueColor: .secondary
                        )
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 30)
        }
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .opacity(0.8)
        )
    }
    
    // MARK: - Componentes auxiliares
    
    @ViewBuilder
    private func modernCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header mejorado de la card
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    iconColor.opacity(0.3),
                                    iconColor.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: iconColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                }
                .scaleEffect(hoveredCard == title ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: hoveredCard)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Información actualizada")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Contenido de la card
            content()
        }
        .padding(28)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 16, x: 0, y: 8)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.white.opacity(0.15) : Color.gray.opacity(0.3),
                                colorScheme == .dark ? Color.gray.opacity(0.05) : Color.gray.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .scaleEffect(hoveredCard == title ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: hoveredCard)
        .onHover { hovering in
            hoveredCard = hovering ? title : nil
        }
    }
    
    @ViewBuilder
    private func infoRow(
        icon: String,
        title: String,
        value: String,
        valueColor: Color
    ) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.clear)
                .onHover { hovering in
                    // Efecto sutil de hover
                }
        )
    }
    
    @ViewBuilder
    private func modernButton(
        title: String,
        icon: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                if !isLoading {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.blue.opacity(0.8),
                                    Color.purple.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : (hoveredCard == title ? 1.02 : 1.0))
        .animation(.easeInOut(duration: 0.15), value: isLoading)
        .animation(.easeInOut(duration: 0.15), value: hoveredCard)
        .onHover { hovering in
            hoveredCard = hovering ? title : nil
        }
    }
    
    private var invitationCodeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Código de Invitación Generado")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(codigoInvitacion)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                            .textSelection(.enabled)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        
                        Text("Comparte este código para invitar nuevos miembros")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(codigoInvitacion, forType: .string)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Copiar")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(hoveredCard == "copy" ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: hoveredCard)
                    .onHover { hovering in
                        hoveredCard = hovering ? "copy" : nil
                    }
                }
                
                Text("⏰ Este código expirará en 24 horas")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.1))
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.4),
                                    Color.blue.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .green.opacity(0.2), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Funciones auxiliares
    
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
        .environmentObject(AuthViewModel())
}
