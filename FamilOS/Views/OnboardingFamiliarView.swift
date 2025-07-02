import SwiftUI

struct OnboardingFamiliarView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var nombreFamilia: String = ""
    @State private var descripcionFamilia: String = ""
    @State private var codigoInvitacion: String = ""
    @State private var mostrarCrearFamilia: Bool = true
    @State private var isCreating: Bool = false
    @State private var isJoining: Bool = false
    @State private var hoveredCard: String? = nil
    @State private var isAnimating: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo con efecto moderno
                backgroundView
                
                HStack(spacing: 0) {
                    // Panel izquierdo - Bienvenida
                    leftPanel
                        .frame(width: geometry.size.width * 0.4)
                    
                    // Panel derecho - Opciones
                    rightPanel
                        .frame(width: geometry.size.width * 0.6)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    // MARK: - Componentes de la vista
    
    private var backgroundView: some View {
        ZStack {
            // Fondo base
            if colorScheme == .dark {
                Color.black.ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            // Gradiente principal
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color.blue.opacity(0.15) : Color.blue.opacity(0.08),
                    colorScheme == .dark ? Color.purple.opacity(0.1) : Color.purple.opacity(0.05),
                    colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Elementos decorativos animados
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.15),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.purple.opacity(0.08) : Color.purple.opacity(0.12),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.7)
                    .scaleEffect(isAnimating ? 0.9 : 1.0)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
    }
    
    private var leftPanel: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Bienvenida y logo
            VStack(spacing: 30) {
                // Icono principal animado
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.2),
                                    Color.purple.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.purple.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 85, height: 85)
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                    
                    Image(systemName: "house.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("¡Bienvenido a FamilOS!")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Para comenzar, necesitas configurar tu entorno familiar")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            
            // Información del usuario
            if let usuario = authViewModel.usuarioActual {
                VStack(spacing: 20) {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.8),
                                    Color.blue.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(usuario.nombre.prefix(1)).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        Text("Hola, \(usuario.nombre)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(usuario.email)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.3),
                                            Color.blue.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .background(
            ZStack {
                if colorScheme == .dark {
                    Color.black.opacity(0.8)
                } else {
                    Color.white.opacity(0.9)
                }
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05),
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
            VStack(spacing: 40) {
                Spacer(minLength: 50)
                
                // Selector de opciones
                VStack(spacing: 24) {
                    Text("Elige una opción")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                    
                    // Botones de selección
                    HStack(spacing: 20) {
                        optionButton(
                            title: "Crear Familia",
                            icon: "plus.circle.fill",
                            isSelected: mostrarCrearFamilia,
                            action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    mostrarCrearFamilia = true
                                }
                            }
                        )
                        
                        optionButton(
                            title: "Unirse a Familia",
                            icon: "person.2.fill",
                            isSelected: !mostrarCrearFamilia,
                            action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    mostrarCrearFamilia = false
                                }
                            }
                        )
                    }
                }
                
                // Formulario dinámico
                if mostrarCrearFamilia {
                    crearFamiliaForm
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    unirseFamiliaForm
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 50)
        }
        .background(
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .opacity(0.8)
        )
    }
    
    // MARK: - Formularios
    
    private var crearFamiliaForm: some View {
        modernCard(
            title: "Crear Nueva Familia",
            icon: "house.circle.fill",
            iconColor: .blue
        ) {
            VStack(spacing: 24) {
                modernTextField(
                    placeholder: "Nombre de la familia",
                    text: $nombreFamilia,
                    icon: "house.fill"
                )
                
                modernTextField(
                    placeholder: "Descripción (opcional)",
                    text: $descripcionFamilia,
                    icon: "text.quote"
                )
                
                // Mensaje de error
                if let error = authViewModel.error {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                }
                
                modernButton(
                    title: "Crear Familia",
                    icon: "plus.circle.fill",
                    isLoading: isCreating,
                    action: crearFamilia
                )
                .disabled(nombreFamilia.isEmpty || isCreating)
            }
        }
    }
    
    private var unirseFamiliaForm: some View {
        modernCard(
            title: "Unirse a Familia",
            icon: "person.2.circle.fill",
            iconColor: .green
        ) {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Código de Invitación")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    modernTextField(
                        placeholder: "Ingresa el código",
                        text: $codigoInvitacion,
                        icon: "key.fill"
                    )
                    
                    Text("Solicita el código a un administrador de la familia")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                // Mensaje de error
                if let error = authViewModel.error {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                }
                
                modernButton(
                    title: "Unirse a Familia",
                    icon: "person.2.fill",
                    isLoading: isJoining,
                    action: unirseFamilia
                )
                .disabled(codigoInvitacion.isEmpty || isJoining)
            }
        }
    }
    
    // MARK: - Componentes auxiliares
    
    @ViewBuilder
    private func optionButton(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected 
                            ? LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(isSelected ? 0.0 : 0.3), lineWidth: 1)
                    )
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(hoveredCard == title ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: hoveredCard)
        .onHover { hovering in
            hoveredCard = hovering ? title : nil
        }
    }
    
    @ViewBuilder
    private func modernCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
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
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
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
    }
    
    @ViewBuilder
    private func modernTextField(
        placeholder: String,
        text: Binding<String>,
        icon: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 20)
            
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .regular))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func modernButton(
        title: String,
        icon: String,
        isLoading: Bool,
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
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
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
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }
    
    // MARK: - Funciones de acción
    
    private func crearFamilia() {
        isCreating = true
        authViewModel.error = nil
        
        Task {
            await authViewModel.crearFamilia(nombre: nombreFamilia, descripcion: descripcionFamilia)
            await MainActor.run {
                isCreating = false
            }
        }
    }
    
    private func unirseFamilia() {
        isJoining = true
        authViewModel.error = nil
        
        Task {
            await authViewModel.unirseFamiliaConCodigo(codigo: codigoInvitacion)
            await MainActor.run {
                isJoining = false
            }
        }
    }
}



#Preview {
    OnboardingFamiliarView()
        .environmentObject(AuthViewModel())
}
