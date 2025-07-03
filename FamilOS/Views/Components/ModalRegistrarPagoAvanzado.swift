import SwiftUI

// MARK: - FASE 3: Modal de Registro de Pago con Múltiples Aportes
struct ModalRegistrarPagoAvanzado: View {
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
    @State private var modoAporte: ModoAporte = .multiple
    @State private var aporteUnico: Aporte?
    @State private var aportesMultiples: [AporteSeleccionado] = []
    @State private var usarAporte = true
    
    // Estados de la UI
    @State private var registrandoPago = false
    @State private var mostrandoError = false
    @State private var mensajeError = ""
    @State private var mostrandoPreview = false
    
    enum ModoAporte: String, CaseIterable {
        case unico = "Un Aporte"
        case multiple = "Múltiples Aportes"
        
        var icono: String {
            switch self {
            case .unico: return "person.circle"
            case .multiple: return "person.2.circle"
            }
        }
        
        var descripcion: String {
            switch self {
            case .unico: return "Usar un solo aporte para cubrir el pago"
            case .multiple: return "Combinar varios aportes para cubrir el pago"
            }
        }
    }
    
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
                    VStack(spacing: 16) {
                        headerSection
                        
                        informacionCuentaSection
                        
                        metodoPagoSection
                        
                        if usarAporte {
                            configuracionAportesSection
                            
                            if modoAporte == .unico {
                                selectorAporteUnicoSection
                            } else {
                                selectorAportesMultiplesSection
                            }
                            
                            previewDistribucionSection
                        }
                        
                        detallesPagoSection
                        
                        botonesSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Preview") {
                        mostrandoPreview = true
                    }
                    .disabled(!esFormularioValido)
                }
            }
        }
        .alert("Error", isPresented: $mostrandoError) {
            Button("OK") { }
        } message: {
            Text(mensajeError)
        }
        .sheet(isPresented: $mostrandoPreview) {
            VistaPreviewPago(
                cuenta: cuenta,
                montoPago: montoPago,
                modoAporte: modoAporte,
                aporteUnico: aporteUnico,
                aportesMultiples: aportesMultiples,
                presupuestoViewModel: presupuestoViewModel
            )
            .frame(width: 500, height: 600)
            .frame(minWidth: 480, minHeight: 580)
        }
        .frame(width: 600, height: 750)
        .frame(minWidth: 580, minHeight: 720)
    }
    
    // MARK: - Validaciones
    private var esFormularioValido: Bool {
        guard montoPago > 0 else { return false }
        
        if usarAporte {
            if modoAporte == .unico {
                guard let aporte = aporteUnico else { return false }
                return aporte.saldoDisponible >= montoPago
            } else {
                let validacion = presupuestoViewModel.validarDistribucionMultiple(aportesMultiples, montoRequerido: montoPago)
                return validacion.esValida
            }
        }
        
        return true
    }
    
    private var mensajeValidacion: String? {
        if montoPago <= 0 {
            return "El monto debe ser mayor a 0"
        }
        
        if usarAporte {
            if modoAporte == .unico {
                guard let aporte = aporteUnico else {
                    return "Selecciona un aporte"
                }
                
                if aporte.saldoDisponible < montoPago {
                    return "Saldo insuficiente en el aporte seleccionado"
                }
            } else {
                let validacion = presupuestoViewModel.validarDistribucionMultiple(aportesMultiples, montoRequerido: montoPago)
                return validacion.error
            }
        }
        
        return nil
    }
    
    // MARK: - Secciones de la UI
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(glassMaterial)
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: usarAporte ? (modoAporte == .unico ? "wallet.pass.fill" : "person.2.circle.fill") : "creditcard.fill")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                )
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
            
            VStack(spacing: 6) {
                Text("Pago Avanzado")
                    .font(.title2.weight(.bold))
                    .foregroundColor(primaryTextColor)
                
                Text(getSubtituloHeader())
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
    }
    
    private func getSubtituloHeader() -> String {
        if !usarAporte {
            return "Registra el pago directo de la cuenta"
        } else if modoAporte == .unico {
            return "Paga usando un aporte familiar"
        } else {
            return "Combina múltiples aportes para el pago"
        }
    }
    
    private var informacionCuentaSection: some View {
        glassSection(title: "Información de la Cuenta", icon: "doc.text") {
            VStack(spacing: 16) {
                infoRow("Proveedor", value: cuenta.proveedor)
                infoRow("Cuenta", value: cuenta.nombre.isEmpty ? "Sin nombre" : cuenta.nombre)
                infoRow("Categoría", value: cuenta.categoria)
                infoRow("Monto Original", value: String(format: "$%.0f", cuenta.monto))
            }
        }
    }
    
    private var metodoPagoSection: some View {
        glassSection(title: "Método de Pago", icon: "creditcard") {
            VStack(spacing: 16) {
                HStack {
                    Button(action: { 
                        usarAporte = false
                        limpiarSelecciones()
                    }) {
                        HStack {
                            Image(systemName: usarAporte ? "circle" : "circle.fill")
                                .foregroundColor(.blue)
                            Text("Pago directo")
                                .foregroundColor(primaryTextColor)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Button(action: { 
                        usarAporte = true 
                    }) {
                        HStack {
                            Image(systemName: usarAporte ? "circle.fill" : "circle")
                                .foregroundColor(.blue)
                            Text("Usar aportes")
                                .foregroundColor(primaryTextColor)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if usarAporte {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        
                        Text("El pago se descontará de los aportes seleccionados")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var configuracionAportesSection: some View {
        glassSection(title: "Configuración de Aportes", icon: "gear") {
            VStack(spacing: 16) {
                Picker("Modo", selection: $modoAporte) {
                    ForEach(ModoAporte.allCases, id: \.self) { modo in
                        HStack {
                            Image(systemName: modo.icono)
                            Text(modo.rawValue)
                        }
                        .tag(modo)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: modoAporte) { oldValue, newValue in
                    limpiarSelecciones()
                }
                
                HStack {
                    Image(systemName: modoAporte.icono)
                        .foregroundColor(.blue)
                    
                    Text(modoAporte.descripcion)
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var selectorAporteUnicoSection: some View {
        VStack(spacing: 16) {
            SelectorAportesView(
                presupuestoViewModel: presupuestoViewModel,
                montoRequerido: montoPago,
                aporteSeleccionado: $aporteUnico,
                montoAUsar: .constant(montoPago)
            )
        }
    }
    
    private var selectorAportesMultiplesSection: some View {
        VStack(spacing: 16) {
            SelectorMultipleAportesView(
                presupuestoViewModel: presupuestoViewModel,
                montoRequerido: montoPago,
                aportesSeleccionados: $aportesMultiples
            )
        }
    }
    
    private var previewDistribucionSection: some View {
        Group {
            if usarAporte && ((modoAporte == .unico && aporteUnico != nil) || (modoAporte == .multiple && !aportesMultiples.isEmpty)) {
                glassSection(title: "Resumen de Distribución", icon: "chart.pie") {
                    VStack(spacing: 12) {
                        if modoAporte == .unico, let aporte = aporteUnico {
                            HStack {
                                Text("Aporte de \(aporte.usuario)")
                                    .foregroundColor(primaryTextColor)
                                Spacer()
                                Text("$\(String(format: "%.0f", montoPago))")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Saldo restante")
                                    .foregroundColor(secondaryTextColor)
                                Spacer()
                                Text("$\(String(format: "%.0f", aporte.saldoDisponible - montoPago))")
                                    .foregroundColor(secondaryTextColor)
                            }
                        } else {
                            Text(presupuestoViewModel.resumenDistribucion(aportesMultiples))
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Mensaje de validación
                        if let mensaje = mensajeValidacion {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                
                                Text(mensaje)
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
    }
    
    private var detallesPagoSection: some View {
        glassSection(title: "Detalles del Pago", icon: "calendar") {
            VStack(spacing: 16) {
                glassNumberField("Monto a Pagar", value: $montoPago)
                    .onChange(of: montoPago) { oldValue, newValue in
                        ajustarSeleccionesAlCambiarMonto()
                    }
                
                glassDatePicker("Fecha de Pago", selection: $fechaPago)
                glassTextField("Notas (opcional)", text: $notas)
                
                Toggle("Tengo comprobante", isOn: $tieneComprobante)
                    .foregroundColor(primaryTextColor)
            }
        }
    }
    
    private var botonesSection: some View {
        VStack(spacing: 12) {
            // Botón principal de procesar pago
            HStack(spacing: 10) {
                if registrandoPago {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Button(registrandoPago ? "Procesando..." : "Procesar Pago") {
                    registrarPago()
                }
                .disabled(!esFormularioValido || registrandoPago)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    esFormularioValido && !registrandoPago ? 
                    Color.blue : Color.gray.opacity(0.3)
                )
                .foregroundColor(esFormularioValido && !registrandoPago ? .white : .gray)
                .cornerRadius(10)
                .fontWeight(.semibold)
            }
            
            // Botón secundario de cancelar
            Button("Cancelar") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(10)
            .fontWeight(.medium)
        }
        .padding(.top, 4)
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
                if usarAporte {
                    if modoAporte == .unico, let aporte = aporteUnico {
                        // Pago con un solo aporte
                        let distribucion = [(aporteId: aporte.id, montoAUsar: montoPago)]
                        try await presupuestoViewModel.procesarPagoConAportes(
                            cuenta: cuenta,
                            distribucion: distribucion,
                            usuario: aporte.usuario
                        )
                    } else {
                        // Pago con múltiples aportes
                        try await presupuestoViewModel.procesarPagoConMultiplesAportes(
                            cuenta: cuenta,
                            aportesSeleccionados: aportesMultiples,
                            usuario: "Sistema" // O el usuario actual
                        )
                    }
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
    
    private func limpiarSelecciones() {
        aporteUnico = nil
        aportesMultiples.removeAll()
    }
    
    private func ajustarSeleccionesAlCambiarMonto() {
        // Si cambia el monto, ajustar las selecciones
        if modoAporte == .unico {
            // Para aporte único, no necesita ajuste
        } else {
            // Para múltiples aportes, recalcular distribución si es necesario
            if !aportesMultiples.isEmpty {
                let montoTotal = aportesMultiples.reduce(0) { $0 + $1.montoAUsar }
                if montoTotal != montoPago {
                    // Opcional: aplicar distribución automática
                }
            }
        }
    }
    
    // MARK: - Helper Views (reutilizamos las del modal anterior)
    private func glassSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                
                Spacer()
            }
            
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(glassMaterial)
        .cornerRadius(10)
        .shadow(color: shadowColor, radius: 2, x: 0, y: 1)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            TextField("0", value: value, format: .number)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(fieldBackground)
                .cornerRadius(10)
                .foregroundColor(primaryTextColor)
        }
    }
    
    private func glassDatePicker(_ title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            DatePicker("", selection: selection, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .foregroundColor(primaryTextColor)
        }
    }
    
    private func glassTextField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            TextField(title, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(fieldBackground)
                .cornerRadius(10)
                .foregroundColor(primaryTextColor)
        }
    }
    
    // MARK: - Fondo y Estilos
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

// MARK: - Vista Preview de Pago
struct VistaPreviewPago: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let cuenta: Cuenta
    let montoPago: Double
    let modoAporte: ModalRegistrarPagoAvanzado.ModoAporte
    let aporteUnico: Aporte?
    let aportesMultiples: [AporteSeleccionado]
    let presupuestoViewModel: PresupuestoViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header fijo
            VStack(spacing: 12) {
                HStack {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Vista Previa del Pago")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    // Espaciador para centrar el título
                    Text("")
                        .frame(width: 50)
                }
                
                VStack(spacing: 4) {
                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("Revisa los detalles antes de procesar")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(glassMaterial)
            
            // Contenido scrollable
            ScrollView {
                VStack(spacing: 16) {
                    resumenCuentaSection
                    
                    resumenDistribucionSection
                    
                    impactoEnAportesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var headerPreview: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Vista Previa del Pago")
                .font(.title.weight(.bold))
                .foregroundColor(primaryTextColor)
            
            Text("Revisa los detalles antes de procesar")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
    }
    
    private var resumenCuentaSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Cuenta a Pagar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            VStack(spacing: 6) {
                infoRow("Proveedor", value: cuenta.proveedor)
                infoRow("Monto", value: "$\(String(format: "%.0f", montoPago))")
                infoRow("Categoría", value: cuenta.categoria)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(glassMaterial)
        .cornerRadius(10)
    }
    
    private var resumenDistribucionSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Distribución de Aportes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            if modoAporte == .unico, let aporte = aporteUnico {
                VStack(spacing: 6) {
                    HStack {
                        Text("Aporte de \(aporte.usuario)")
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor)
                        Spacer()
                        Text("$\(String(format: "%.0f", montoPago))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(aportesMultiples) { seleccion in
                        HStack {
                            Text(seleccion.aporte.usuario)
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                            Spacer()
                            Text("$\(String(format: "%.0f", seleccion.montoAUsar))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 2)
                    }
                    
                    if aportesMultiples.count > 1 {
                        Divider()
                            .padding(.vertical, 4)
                        
                        HStack {
                            Text("Total")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(primaryTextColor)
                            Spacer()
                            Text("$\(String(format: "%.0f", aportesMultiples.reduce(0) { $0 + $1.montoAUsar }))")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(glassMaterial)
        .cornerRadius(10)
    }
    
    private var impactoEnAportesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Impacto en Aportes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            if modoAporte == .unico, let aporte = aporteUnico {
                VStack(spacing: 6) {
                    HStack {
                        Text("Saldo actual")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                        Spacer()
                        Text("$\(String(format: "%.0f", aporte.saldoDisponible))")
                            .font(.caption.weight(.medium))
                            .foregroundColor(primaryTextColor)
                    }
                    
                    HStack {
                        Text("Después del pago")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                        Spacer()
                        Text("$\(String(format: "%.0f", aporte.saldoDisponible - montoPago))")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.orange)
                    }
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(aportesMultiples) { seleccion in
                        VStack(spacing: 3) {
                            HStack {
                                Text(seleccion.aporte.usuario)
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(primaryTextColor)
                                Spacer()
                            }
                            
                            HStack {
                                Text("Actual: $\(String(format: "%.0f", seleccion.aporte.saldoDisponible))")
                                    .font(.caption2)
                                    .foregroundColor(secondaryTextColor)
                                Spacer()
                                Text("Después: $\(String(format: "%.0f", seleccion.saldoRestante))")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.vertical, 2)
                        
                        if seleccion.id != aportesMultiples.last?.id {
                            Divider()
                                .opacity(0.5)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(glassMaterial)
        .cornerRadius(10)
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
    
    // MARK: - Estilos
    private var glassMaterial: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.ultraThinMaterial.opacity(0.6))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.7))
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .secondary
    }
}
