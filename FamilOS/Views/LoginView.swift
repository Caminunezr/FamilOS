import SwiftUI
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email: String = ""
    @State private var contrasena: String = ""
    @State private var mostrarContrasena: Bool = false
    @State private var biometricsAvailable: Bool = false
    @State private var isHovered: Bool = false
    @State private var mostrarRegistro: Bool = false
    
    // MARK: - Estados para el registro
    @State private var nombreRegistro: String = ""
    @State private var emailRegistro: String = ""
    @State private var contrasenaRegistro: String = ""
    @State private var confirmarContrasenaRegistro: String = ""
    @State private var mostrarContrasenaRegistro: Bool = false
    @State private var mostrarConfirmarContrasenaRegistro: Bool = false
    @State private var aceptarTerminos: Bool = false
    @State private var errorLocalRegistro: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fondo con efecto vidrio esmerilado estilo macOS
                backgroundView
                
                // Contenedor principal
                HStack(spacing: 0) {
                    // Panel izquierdo - Información de la app
                    leftPanel
                        .frame(width: geometry.size.width * 0.45)
                    
                    // Panel derecho - Formulario de login
                    rightPanel
                        .frame(width: geometry.size.width * 0.55)
                }
            }
        }
        .onAppear {
            checkBiometricsAvailability()
        }
    }
    
    // MARK: - Componentes de la vista
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
            
            // Logo y branding
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
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.black)
                    )
                    .shadow(color: .white.opacity(0.2), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("FamilOS")
                        .font(.system(size: 42, weight: .light, design: .default))
                        .foregroundColor(.white)
                    
                    Text("Gestión Financiera Familiar")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            
            // Características destacadas
            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "shield.checkerboard", text: "Seguridad avanzada")
                featureRow(icon: "chart.bar.fill", text: "Análasis inteligente")
                featureRow(icon: "person.2.fill", text: "Colaboración familiar")
                featureRow(icon: "icloud.fill", text: "Sincronización en la nube")
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .background(Color.black.opacity(0.7))
    }
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Mostrar formulario de login o registro con transición
            if mostrarRegistro {
                registroForm
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 60)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                loginForm
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 60)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
            
            Spacer()
        }
        .background(
            // Efecto vidrio esmerilado
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .opacity(0.8)
        )
    }
    
    
    private var loginForm: some View {
        VStack(spacing: 32) {
            // Header del formulario
            VStack(spacing: 8) {
                Text("Iniciar Sesión")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white)
                
                Text("Accede a tu cuenta FamilOS")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
            
            // Campos del formulario
            VStack(spacing: 24) {
                modernTextField(
                    placeholder: "Correo electrónico",
                    text: $email,
                    icon: "envelope",
                    isSecure: false
                )
                
                modernTextField(
                    placeholder: "Contraseña",
                    text: $contrasena,
                    icon: "lock",
                    isSecure: !mostrarContrasena,
                    hasSecureToggle: true
                )
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
            
            // Estado de la red
            HStack {
                Circle()
                    .fill(authViewModel.networkStatus == .satisfied ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text("Red: \(authViewModel.networkStatus == .satisfied ? "Conectado" : "Sin conexión")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                Spacer()
            }
            
            // Botones de acción
            VStack(spacing: 16) {
                // Botón principal de login
                Button(action: {
                    authViewModel.login(email: email, contrasena: contrasena)
                }) {
                    HStack {
                        if authViewModel.isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Text("Continuar")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                isLoginButtonDisabled 
                                ? Color.gray.opacity(0.3)
                                : Color.white
                            )
                    )
                    .foregroundColor(
                        isLoginButtonDisabled 
                        ? .gray 
                        : .black
                    )
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isHovered)
                }
                .disabled(isLoginButtonDisabled)
                .onHover { hovering in
                    isHovered = hovering
                }
                
                // Opciones adicionales
                HStack(spacing: 20) {
                    // Touch ID / Face ID
                    if biometricsAvailable {
                        Button(action: {
                            authViewModel.loginConBiometricos()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: LAContext().biometryType == .faceID ? "faceid" : "touchid")
                                    .font(.system(size: 16))
                                Text("Biométrico")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .disabled(authViewModel.isAuthenticating)
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                    
                    // Crear cuenta
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            mostrarRegistro = true
                        }
                    }) {
                        Text("Crear cuenta")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .underline()
                    }
                    .disabled(authViewModel.isAuthenticating)
                    .buttonStyle(.plain)
                }
                
                // Botón de diagnóstico para problemas de conexión
                if authViewModel.networkStatus != .satisfied || authViewModel.error?.contains("conexión") == true {
                    Button(action: {
                        print("🔧 DIAGNÓSTICO FIREBASE:")
                        print(authViewModel.verificarConfiguracionFirebase())
                        authViewModel.testConexionFirebase()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 12))
                            Text("Diagnosticar Conexión")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                // Botón de diagnóstico avanzado (solo en DEBUG)
                #if DEBUG
                Button(action: {
                    print("🔧 DIAGNÓSTICO COMPLETO:")
                    print(authViewModel.verificarConfiguracionFirebase())
                    authViewModel.testConexionFirebase()
                    
                    // Verificar entitlements
                    print("� VERIFICANDO ENTITLEMENTS...")
                    let bundle = Bundle.main
                    if let entitlements = bundle.object(forInfoDictionaryKey: "com.apple.security.app-sandbox") {
                        print("App Sandbox: \(entitlements)")
                    }
                    if let networkClient = bundle.object(forInfoDictionaryKey: "com.apple.security.network.client") {
                        print("Network Client: \(networkClient)")
                    } else {
                        print("⚠️ Network Client entitlement no encontrado")
                    }
                }) {
                    Text("🔧 Diagnóstico Completo")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                #endif
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }
    
    private var isLoginButtonDisabled: Bool {
        email.isEmpty || contrasena.isEmpty || authViewModel.isAuthenticating
    }
    
    // MARK: - Componentes auxiliares
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
    
    private func modernTextField(
        placeholder: String,
        text: Binding<String>,
        icon: String,
        isSecure: Bool,
        hasSecureToggle: Bool = false,
        toggleAction: (() -> Void)? = nil
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
                        .textContentType(placeholder.contains("Correo") ? .emailAddress : .password)
                } else {
                    TextField(placeholder, text: text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .textContentType(placeholder.contains("Correo") ? .emailAddress : .none)
                }
                
                if hasSecureToggle {
                    Button(action: {
                        if let toggleAction = toggleAction {
                            toggleAction()
                        } else {
                            mostrarContrasena.toggle()
                        }
                    }) {
                        Image(systemName: isSecure ? "eye" : "eye.slash")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
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

    // MARK: - Formulario de registro integrado
    private var registroForm: some View {
        VStack(spacing: 32) {
            // Header del formulario de registro
            VStack(spacing: 8) {
                Text("Crear Cuenta")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white)
                
                Text("Únete a FamilOS")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
            
            // Campos del formulario de registro
            VStack(spacing: 24) {
                modernTextField(
                    placeholder: "Nombre completo",
                    text: $nombreRegistro,
                    icon: "person",
                    isSecure: false
                )
                
                modernTextField(
                    placeholder: "Correo electrónico",
                    text: $emailRegistro,
                    icon: "envelope",
                    isSecure: false
                )
                
                modernTextField(
                    placeholder: "Contraseña",
                    text: $contrasenaRegistro,
                    icon: "lock",
                    isSecure: !mostrarContrasenaRegistro,
                    hasSecureToggle: true,
                    toggleAction: { mostrarContrasenaRegistro.toggle() }
                )
                
                if !contrasenaRegistro.isEmpty {
                    indicadorFortalezaContrasenaRegistro
                        .transition(.opacity)
                }
                
                modernTextField(
                    placeholder: "Confirmar contraseña",
                    text: $confirmarContrasenaRegistro,
                    icon: "lock.shield",
                    isSecure: !mostrarConfirmarContrasenaRegistro,
                    hasSecureToggle: true,
                    toggleAction: { mostrarConfirmarContrasenaRegistro.toggle() }
                )
            }
            
            // Términos y condiciones
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    // Checkbox mejorado y más responsivo
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.15)) {
                            aceptarTerminos.toggle()
                        }
                        print("Términos aceptados: \(aceptarTerminos)") // Debug
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(aceptarTerminos ? Color.white : Color.clear)
                                .frame(width: 22, height: 22)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(aceptarTerminos ? 1.0 : 0.6), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            
                            if aceptarTerminos {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle()) // Hace que toda el área sea clickeable
                    
                    // Hacer que el texto también sea clickeable
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            aceptarTerminos.toggle()
                        }
                        print("Términos aceptados (texto): \(aceptarTerminos)") // Debug
                    }) {
                        HStack(spacing: 0) {
                            Text("Acepto los ")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            +
                            Text("términos y condiciones")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    // Indicador visual del estado
                    if aceptarTerminos {
                        Text("✓")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                
                // Mostrar errores de registro
                if let error = errorLocalRegistro ?? authViewModel.error {
                    Text(error)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .transition(.opacity)
                }
            }
            
            // Botones de acción del registro
            VStack(spacing: 16) {
                // Botón principal de registro
                Button(action: {
                    registrarUsuario()
                }) {
                    HStack {
                        if authViewModel.isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Text("Crear Cuenta")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                isRegistroButtonDisabled 
                                ? Color.gray.opacity(0.3)
                                : Color.white
                            )
                    )
                    .foregroundColor(
                        isRegistroButtonDisabled 
                        ? .gray 
                        : .black
                    )
                    .scaleEffect(isHovered ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isHovered)
                }
                .disabled(isRegistroButtonDisabled)
                .onHover { hovering in
                    isHovered = hovering
                }
                
                // Volver al login
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            mostrarRegistro = false
                            limpiarFormularioRegistro()
                        }
                    }) {
                        Text("¿Ya tienes cuenta? Inicia sesión")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .underline()
                    }
                    .disabled(authViewModel.isAuthenticating)
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }
    
    private var isRegistroButtonDisabled: Bool {
        let isEmpty = nombreRegistro.isEmpty || emailRegistro.isEmpty || contrasenaRegistro.isEmpty || confirmarContrasenaRegistro.isEmpty
        let passwordMismatch = contrasenaRegistro != confirmarContrasenaRegistro
        let passwordTooShort = contrasenaRegistro.count < 6
        let termsNotAccepted = !aceptarTerminos
        let isAuthenticating = authViewModel.isAuthenticating
        
        let disabled = isEmpty || termsNotAccepted || isAuthenticating || passwordMismatch || passwordTooShort
        
        // Debug más conciso - solo cuando hay cambios
        if disabled && !nombreRegistro.isEmpty {
            var reasons: [String] = []
            if isEmpty { reasons.append("campos vacíos") }
            if termsNotAccepted { reasons.append("términos no aceptados") }
            if passwordMismatch { reasons.append("contraseñas diferentes") }
            if passwordTooShort { reasons.append("contraseña corta") }
            if !reasons.isEmpty {
                print("🔒 Botón deshabilitado: \(reasons.joined(separator: ", "))")
            }
        }
        
        return disabled
    }
    
    private var indicadorFortalezaContrasenaRegistro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fortaleza de la contraseña")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorFortalezaRegistro(index: index))
                        .frame(height: 4)
                }
            }
            
            Text(textoFortalezaRegistro)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(colorFortalezaRegistro(index: 0))
        }
    }
    
    // MARK: - Funciones de validación y auxiliares unificadas

    private func calcularFortalezaContrasena(_ password: String) -> Int {
        var score = 0
        if password.count >= 6 { score += 1 }
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        return score
    }

    private func colorFortalezaContrasena(password: String, index: Int) -> Color {
        let fortaleza = calcularFortalezaContrasena(password)
        if index < fortaleza {
            switch fortaleza {
            case 1: return .red
            case 2: return .orange
            case 3: return .yellow
            case 4: return .green
            default: return .gray
            }
        }
        return .gray.opacity(0.3)
    }

    private func colorFortalezaRegistro(index: Int) -> Color {
        let fortaleza = calcularFortalezaContrasena(contrasenaRegistro)
        if index < fortaleza {
            switch fortaleza {
            case 1: return .red
            case 2: return .orange
            case 3: return .yellow
            case 4: return .green
            default: return .gray
            }
        }
        return .gray.opacity(0.3)
    }

    private var textoFortalezaRegistro: String {
        switch calcularFortalezaContrasena(contrasenaRegistro) {
        case 0, 1: return "Muy débil"
        case 2: return "Débil"
        case 3: return "Buena"
        case 4: return "Muy fuerte"
        default: return ""
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func isValidEmailRegistro(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func limpiarFormularioRegistro() {
        nombreRegistro = ""
        emailRegistro = ""
        contrasenaRegistro = ""
        confirmarContrasenaRegistro = ""
        mostrarContrasenaRegistro = false
        mostrarConfirmarContrasenaRegistro = false
        aceptarTerminos = false
        errorLocalRegistro = nil
    }
    
    private func registrarUsuario() {
        // Validaciones adicionales
        if !isValidEmailRegistro(emailRegistro) {
            errorLocalRegistro = "Por favor ingresa un correo electrónico válido."
            return
        }
        
        if contrasenaRegistro.count < 6 {
            errorLocalRegistro = "La contraseña debe tener al menos 6 caracteres."
            return
        }
        
        if contrasenaRegistro != confirmarContrasenaRegistro {
            errorLocalRegistro = "Las contraseñas no coinciden."
            return
        }
        
        if !aceptarTerminos {
            errorLocalRegistro = "Debes aceptar los términos y condiciones."
            return
        }
        
        // Todo validado, procedemos a registrar
        errorLocalRegistro = nil
        authViewModel.registrarUsuario(nombre: nombreRegistro, email: emailRegistro, contrasena: contrasenaRegistro)
        
        // Si el registro es exitoso, volvemos al login
        if authViewModel.error == nil {
            withAnimation(.easeInOut(duration: 0.5)) {
                mostrarRegistro = false
                limpiarFormularioRegistro()
            }
        }
    }

    // Verificar si hay autenticación biométrica disponible
    private func checkBiometricsAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsAvailable = true
        } else {
            biometricsAvailable = false
        }
    }
}

// MARK: - Visual Effect View para el efecto vidrio esmerilado
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.material = material
        effectView.blendingMode = blendingMode
        effectView.state = .active
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
    
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
