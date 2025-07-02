import SwiftUI

// MARK: - FASE 2: Modal de Registro de Pago con Selector de Aportes
struct ModalRegistrarPagoConAporte: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // ViewModels
    @ObservedObject var cuentasViewModel: CuentasViewModel
    @ObservedObject var presupuestoViewModel: PresupuestoViewModel
    
    // Datos de la cuenta
    let cuenta: Cuenta
    
    // Estados del formulario
    @State private var montoPago: Double
    @State private var fechaPago = Date()
    @State private var notas = ""
    @State private var tieneComprobante = false
    
    // Estados del selector de aportes
    @State private var aporteSeleccionado: Aporte?
    @State private var montoAUsar: Double = 0
    @State private var usarAporte = true
    
    // Estados de la UI
    @State private var registrandoPago = false
    @State private var mostrandoError = false
    @State private var mensajeError = ""
    @State private var mostrandoDetallesAporte = false
    
    init(cuenta: Cuenta, cuentasViewModel: CuentasViewModel, presupuestoViewModel: PresupuestoViewModel) {
        self.cuenta = cuenta
        self.cuentasViewModel = cuentasViewModel
        self.presupuestoViewModel = presupuestoViewModel
        self._montoPago = State(initialValue: cuenta.monto)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        
                        informacionCuentaSection
                        
                        metodoPagoSection
                        
                        if usarAporte {
                            selectorAportesSection
                        }
                        
                        detallesPagoSection
                        
                        botonesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("Error", isPresented: $mostrandoError) {
            Button("OK") { }
        } message: {
            Text(mensajeError)
        }
    }
    
    // MARK: - Validaciones
    private var esFormularioValido: Bool {
        guard montoPago > 0 else { return false }
        
        if usarAporte {
            guard let aporte = aporteSeleccionado else { return false }
            return aporte.saldoDisponible >= montoPago
        }
        
        return true
    }
    
    private var mensajeValidacion: String? {
        if montoPago <= 0 {
            return "El monto debe ser mayor a 0"
        }
        
        if usarAporte {
            guard let aporte = aporteSeleccionado else {
                return "Selecciona un aporte"
            }
            
            if aporte.saldoDisponible < montoPago {
                return "Saldo insuficiente en el aporte seleccionado"
            }
        }
        
        return nil
    }
    
    // MARK: - Fondo
    private var backgroundView: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color.gray.opacity(0.8),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.white,
                        Color.blue.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(glassMaterial)
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: usarAporte ? "wallet.pass.fill" : "creditcard.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                )
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            
            VStack(spacing: 6) {
                Text("Registrar Pago")
                    .font(.title.weight(.bold))
                    .foregroundColor(primaryTextColor)
                
                Text(usarAporte ? "Paga usando aportes familiares" : "Registra el pago de la cuenta")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Información de la Cuenta
    private var informacionCuentaSection: some View {
        glassSection(title: "Información de la Cuenta", icon: "doc.text") {
            VStack(spacing: 12) {
                infoRow("Proveedor", value: cuenta.proveedor)
                infoRow("Cuenta", value: cuenta.nombre.isEmpty ? "Sin nombre" : cuenta.nombre)
                infoRow("Categoría", value: cuenta.categoria)
                infoRow("Monto Original", value: String(format: "$%.0f", cuenta.monto))
            }
        }
    }
    
    // MARK: - Método de Pago
    private var metodoPagoSection: some View {
        glassSection(title: "Método de Pago", icon: "creditcard") {
            VStack(spacing: 12) {
                HStack {
                    Button(action: { usarAporte = false }) {
                        HStack(spacing: 8) {
                            Image(systemName: usarAporte ? "circle" : "circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("Pago directo")
                                .foregroundColor(primaryTextColor)
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { usarAporte = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: usarAporte ? "circle.fill" : "circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            Text("Usar aporte")
                                .foregroundColor(primaryTextColor)
                                .font(.subheadline)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if usarAporte {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("El pago se descontará del aporte seleccionado")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Selector de Aportes
    private var selectorAportesSection: some View {
        VStack(spacing: 12) {
            SelectorAportesView(
                presupuestoViewModel: presupuestoViewModel,
                montoRequerido: montoPago,
                aporteSeleccionado: $aporteSeleccionado,
                montoAUsar: $montoAUsar
            )
            
            // Mensaje de validación
            if let mensaje = mensajeValidacion {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(mensaje)
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Detalles del Pago
    private var detallesPagoSection: some View {
        glassSection(title: "Detalles del Pago", icon: "calendar") {
            VStack(spacing: 14) {
                glassNumberField("Monto a Pagar", value: $montoPago)
                glassDatePicker("Fecha de Pago", selection: $fechaPago)
                glassTextField("Notas (opcional)", text: $notas)
                
                HStack {
                    Toggle("Tengo comprobante", isOn: $tieneComprobante)
                        .foregroundColor(primaryTextColor)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Botones
    private var botonesSection: some View {
        VStack(spacing: 12) {
            Button(action: registrarPago) {
                HStack(spacing: 8) {
                    if registrandoPago {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Text(registrandoPago ? "Procesando..." : "Registrar Pago")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(esFormularioValido && !registrandoPago ? Color.blue : Color.gray.opacity(0.3))
                )
                .foregroundColor(esFormularioValido && !registrandoPago ? .white : .gray)
            }
            .disabled(!esFormularioValido || registrandoPago)
            .buttonStyle(PlainButtonStyle())
            
            Button("Cancelar") {
                dismiss()
            }
            .foregroundColor(.red)
            .font(.subheadline)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Lógica de Pago
    private func registrarPago() {
        registrandoPago = true
        
        guard esFormularioValido else {
            mostrarError(mensajeValidacion ?? "Formulario inválido")
            registrandoPago = false
            return
        }
        
        Task {
            do {
                if usarAporte, let aporte = aporteSeleccionado {
                    // Usar el nuevo método que integra aportes
                    let distribucion = [(aporteId: aporte.id, montoAUsar: montoPago)]
                    try await presupuestoViewModel.procesarPagoConAportes(
                        cuenta: cuenta,
                        distribucion: distribucion,
                        usuario: aporte.usuario
                    )
                } else {
                    // Pago directo tradicional
                    cuentasViewModel.registrarPago(
                        cuenta: cuenta,
                        monto: montoPago,
                        fecha: fechaPago,
                        notas: notas,
                        tieneComprobante: tieneComprobante
                    )
                }
                
                await MainActor.run {
                    registrandoPago = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    mostrarError("Error al procesar el pago: \(error.localizedDescription)")
                    registrandoPago = false
                }
            }
        }
    }
    
    private func mostrarError(_ mensaje: String) {
        mensajeError = mensaje
        mostrandoError = true
    }
    
    // MARK: - Helper Views
    private func glassSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
            }
            
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(glassMaterial)
        .cornerRadius(12)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
        }
    }
    
    private func glassNumberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            TextField("0", value: value, format: .number)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
                .cornerRadius(8)
                .foregroundColor(primaryTextColor)
                .font(.subheadline)
        }
    }
    
    private func glassDatePicker(_ title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            DatePicker("", selection: selection, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .foregroundColor(primaryTextColor)
                .font(.subheadline)
        }
    }
    
    private func glassTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            TextField(title, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(fieldBackground)
                .cornerRadius(8)
                .foregroundColor(primaryTextColor)
                .font(.subheadline)
        }
    }
    
    // MARK: - Estilos
    private var glassMaterial: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.ultraThinMaterial.opacity(0.6))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.7))
        }
    }
    
    private var fieldBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(Color.white.opacity(0.1))
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.1))
        }
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.3) : .gray.opacity(0.2)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .secondary
    }
}

// MARK: - Preview
#Preview {
    let cuentasVM = CuentasViewModel()
    let presupuestoVM = PresupuestoViewModel()
    
    // Mock data
    let mockCuenta = Cuenta(
        monto: 25000,
        proveedor: "Empresa Test",
        fechaVencimiento: Date(),
        categoria: "Internet",
        creador: "Usuario",
        nombre: "Internet / Julio 2025"
    )
    
    let mockAportes = [
        Aporte(presupuestoId: "test", usuario: "leo@leo.com", monto: 50000, comentario: "Aporte mensual"),
        Aporte(presupuestoId: "test", usuario: "ana@ana.com", monto: 30000, comentario: "Aporte quincenal")
    ]
    
    ModalRegistrarPagoConAporte(
        cuenta: mockCuenta,
        cuentasViewModel: cuentasVM,
        presupuestoViewModel: presupuestoVM
    )
    .onAppear {
        presupuestoVM.aportes = mockAportes
    }
    .preferredColorScheme(.light)
}
