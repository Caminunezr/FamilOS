import SwiftUI

// MARK: - FASE 3: Estructura para manejar selección múltiple de aportes
struct AporteSeleccionado: Identifiable {
    let id = UUID()
    let aporte: Aporte
    var montoAUsar: Double
    
    init(aporte: Aporte, montoAUsar: Double = 0) {
        self.aporte = aporte
        self.montoAUsar = min(montoAUsar, aporte.saldoDisponible)
    }
    
    var saldoRestante: Double {
        aporte.saldoDisponible - montoAUsar
    }
    
    var porcentajeUso: Double {
        guard aporte.saldoDisponible > 0 else { return 0 }
        return (montoAUsar / aporte.saldoDisponible) * 100
    }
}

// MARK: - FASE 3: Selector de Múltiples Aportes
struct SelectorMultipleAportesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var presupuestoViewModel: PresupuestoViewModel
    let montoRequerido: Double
    @Binding var aportesSeleccionados: [AporteSeleccionado]
    
    @State private var mostrandoDistribucionAutomatica = false
    @State private var mostrandoDetalles = false
    @State private var algoritmoDistribucion: AlgoritmoDistribucion = .equilibrado
    
    enum AlgoritmoDistribucion: String, CaseIterable {
        case equilibrado = "Equilibrado"
        case mayorPrimero = "Mayor Primero"
        case menorPrimero = "Menor Primero"
        case proporcional = "Proporcional"
        
        var descripcion: String {
            switch self {
            case .equilibrado:
                return "Distribuye de manera equilibrada entre aportes"
            case .mayorPrimero:
                return "Usa primero los aportes con mayor saldo"
            case .menorPrimero:
                return "Usa primero los aportes con menor saldo"
            case .proporcional:
                return "Distribuye proporcionalmente según el saldo de cada aporte"
            }
        }
        
        var icono: String {
            switch self {
            case .equilibrado: return "scale.3d"
            case .mayorPrimero: return "arrow.up.circle"
            case .menorPrimero: return "arrow.down.circle"
            case .proporcional: return "chart.pie"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            headerSection
            
            if aportesDisponibles.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 16) {
                    controlsSection
                    resumenDistribucionSection
                    listaAportesSection
                }
            }
        }
        .onChange(of: montoRequerido) { _, _ in
            recalcularDistribucion()
        }
    }
    
    // MARK: - Computed Properties
    private var aportesDisponibles: [Aporte] {
        presupuestoViewModel.aportesDisponibles
    }
    
    private var montoTotalSeleccionado: Double {
        aportesSeleccionados.reduce(0) { $0 + $1.montoAUsar }
    }
    
    private var montoRestante: Double {
        max(0, montoRequerido - montoTotalSeleccionado)
    }
    
    private var distribuyeCompleto: Bool {
        abs(montoTotalSeleccionado - montoRequerido) < 0.01
    }
    
    private var tieneSaldoSuficiente: Bool {
        presupuestoViewModel.saldoTotalDisponible >= montoRequerido
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "wallet.pass")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Distribución de Aportes")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button(action: { mostrandoDetalles.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Info del monto
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monto requerido")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    Text("$\(String(format: "%.0f", montoRequerido))")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total seleccionado")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    Text("$\(String(format: "%.0f", montoTotalSeleccionado))")
                        .font(.headline.weight(.bold))
                        .foregroundColor(distribuyeCompleto ? .green : .orange)
                }
            }
            
            // Barra de progreso
            progressBarSection
        }
        .padding()
        .background(glassMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Barra de Progreso
    private var progressBarSection: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fondo
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    // Progreso
                    RoundedRectangle(cornerRadius: 4)
                        .fill(distribuyeCompleto ? Color.green : Color.blue)
                        .frame(
                            width: geometry.size.width * min(1.0, montoTotalSeleccionado / montoRequerido),
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.3), value: montoTotalSeleccionado)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("$0")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                
                Spacer()
                
                if montoRestante > 0 {
                    Text("Faltan $\(String(format: "%.0f", montoRestante))")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.orange)
                } else {
                    Text("✓ Completo")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("$\(String(format: "%.0f", montoRequerido))")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
        }
    }
    
    // MARK: - Controles
    private var controlsSection: some View {
        VStack(spacing: 16) {
            // Algoritmo de distribución
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Distribución Automática")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    Button("Aplicar") {
                        aplicarDistribucionAutomatica()
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline.weight(.medium))
                }
                
                Picker("Algoritmo", selection: $algoritmoDistribucion) {
                    ForEach(AlgoritmoDistribucion.allCases, id: \.self) { algoritmo in
                        HStack {
                            Image(systemName: algoritmo.icono)
                            Text(algoritmo.rawValue)
                        }
                        .tag(algoritmo)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text(algoritmoDistribucion.descripcion)
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            
            // Botones de acción rápida
            HStack(spacing: 12) {
                Button("Limpiar Todo") {
                    aportesSeleccionados.removeAll()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Seleccionar Todo") {
                    seleccionarTodosLosAportes()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Auto Óptimo") {
                    aplicarDistribucionOptima()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .background(glassMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Resumen de Distribución
    private var resumenDistribucionSection: some View {
        Group {
            if !aportesSeleccionados.isEmpty {
                VStack(spacing: 12) {
                    HStack {
                        Text("Vista Previa de Distribución")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        Text("\(aportesSeleccionados.count) aporte(s)")
                            .font(.caption)
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    ForEach(aportesSeleccionados) { seleccion in
                        DistribucionRowView(seleccion: seleccion)
                    }
                }
                .padding()
                .background(glassMaterial)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Lista de Aportes
    private var listaAportesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Aportes Disponibles")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Text("\(aportesDisponibles.count) disponible(s)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            
            ForEach(aportesDisponibles) { aporte in
                AporteMultipleRowView(
                    aporte: aporte,
                    seleccionado: aportesSeleccionados.first(where: { $0.aporte.id == aporte.id }),
                    onToggle: { toggleAporte(aporte) },
                    onMontoChange: { nuevoMonto in
                        actualizarMontoAporte(aporte, nuevoMonto: nuevoMonto)
                    }
                )
            }
        }
    }
    
    // MARK: - Estado Vacío
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No hay aportes disponibles")
                .font(.headline)
                .foregroundColor(primaryTextColor)
            
            Text("No hay aportes con saldo disponible para este pago")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Lógica de Distribución
    private func aplicarDistribucionAutomatica() {
        guard tieneSaldoSuficiente else { return }
        
        let distribucion = calcularDistribucion()
        aportesSeleccionados = distribucion
    }
    
    private func calcularDistribucion() -> [AporteSeleccionado] {
        guard montoRequerido > 0 else { return [] }
        
        switch algoritmoDistribucion {
        case .equilibrado:
            return distribucionEquilibrada()
        case .mayorPrimero:
            return distribucionMayorPrimero()
        case .menorPrimero:
            return distribucionMenorPrimero()
        case .proporcional:
            return distribucionProporcional()
        }
    }
    
    private func distribucionEquilibrada() -> [AporteSeleccionado] {
        let aportes = aportesDisponibles.sorted { $0.saldoDisponible > $1.saldoDisponible }
        var resultado: [AporteSeleccionado] = []
        var montoRestante = montoRequerido
        
        let numAportes = min(aportes.count, 3) // Máximo 3 aportes para equilibrio
        let montoPorAporte = montoRequerido / Double(numAportes)
        
        for (index, aporte) in aportes.prefix(numAportes).enumerated() {
            let montoAUsar: Double
            
            if index == numAportes - 1 {
                // Último aporte: usar todo el restante
                montoAUsar = min(montoRestante, aporte.saldoDisponible)
            } else {
                montoAUsar = min(montoPorAporte, aporte.saldoDisponible)
            }
            
            if montoAUsar > 0 {
                resultado.append(AporteSeleccionado(aporte: aporte, montoAUsar: montoAUsar))
                montoRestante -= montoAUsar
            }
        }
        
        return resultado
    }
    
    private func distribucionMayorPrimero() -> [AporteSeleccionado] {
        let aportes = aportesDisponibles.sorted { $0.saldoDisponible > $1.saldoDisponible }
        var resultado: [AporteSeleccionado] = []
        var montoRestante = montoRequerido
        
        for aporte in aportes {
            guard montoRestante > 0 else { break }
            
            let montoAUsar = min(montoRestante, aporte.saldoDisponible)
            if montoAUsar > 0 {
                resultado.append(AporteSeleccionado(aporte: aporte, montoAUsar: montoAUsar))
                montoRestante -= montoAUsar
            }
        }
        
        return resultado
    }
    
    private func distribucionMenorPrimero() -> [AporteSeleccionado] {
        let aportes = aportesDisponibles.sorted { $0.saldoDisponible < $1.saldoDisponible }
        var resultado: [AporteSeleccionado] = []
        var montoRestante = montoRequerido
        
        for aporte in aportes {
            guard montoRestante > 0 else { break }
            
            let montoAUsar = min(montoRestante, aporte.saldoDisponible)
            if montoAUsar > 0 {
                resultado.append(AporteSeleccionado(aporte: aporte, montoAUsar: montoAUsar))
                montoRestante -= montoAUsar
            }
        }
        
        return resultado
    }
    
    private func distribucionProporcional() -> [AporteSeleccionado] {
        let aportes = aportesDisponibles
        let saldoTotal = aportes.reduce(0) { $0 + $1.saldoDisponible }
        guard saldoTotal > 0 else { return [] }
        
        var resultado: [AporteSeleccionado] = []
        var montoRestante = montoRequerido
        
        for (index, aporte) in aportes.enumerated() {
            let proporcion = aporte.saldoDisponible / saldoTotal
            let montoAUsar: Double
            
            if index == aportes.count - 1 {
                // Último aporte: usar todo el restante
                montoAUsar = min(montoRestante, aporte.saldoDisponible)
            } else {
                montoAUsar = min(montoRequerido * proporcion, aporte.saldoDisponible)
            }
            
            if montoAUsar > 0 {
                resultado.append(AporteSeleccionado(aporte: aporte, montoAUsar: montoAUsar))
                montoRestante -= montoAUsar
            }
        }
        
        return resultado
    }
    
    private func aplicarDistribucionOptima() {
        // Algoritmo que minimiza el número de aportes utilizados
        let distribucion = presupuestoViewModel.calcularDistribucionAutomatica(monto: montoRequerido)
        aportesSeleccionados = distribucion.map { AporteSeleccionado(aporte: $0.aporte, montoAUsar: $0.montoAUsar) }
    }
    
    private func seleccionarTodosLosAportes() {
        aportesSeleccionados = aportesDisponibles.map { aporte in
            AporteSeleccionado(aporte: aporte, montoAUsar: 0)
        }
    }
    
    private func toggleAporte(_ aporte: Aporte) {
        if let index = aportesSeleccionados.firstIndex(where: { $0.aporte.id == aporte.id }) {
            aportesSeleccionados.remove(at: index)
        } else {
            let montoSugerido = min(montoRestante, aporte.saldoDisponible)
            aportesSeleccionados.append(AporteSeleccionado(aporte: aporte, montoAUsar: montoSugerido))
        }
    }
    
    private func actualizarMontoAporte(_ aporte: Aporte, nuevoMonto: Double) {
        guard let index = aportesSeleccionados.firstIndex(where: { $0.aporte.id == aporte.id }) else { return }
        
        let montoValidado = min(nuevoMonto, aporte.saldoDisponible)
        aportesSeleccionados[index].montoAUsar = max(0, montoValidado)
        
        // Si el monto es 0, remover de la selección
        if aportesSeleccionados[index].montoAUsar == 0 {
            aportesSeleccionados.remove(at: index)
        }
    }
    
    private func recalcularDistribucion() {
        // Ajustar distribución cuando cambia el monto requerido
        let montoTotal = montoTotalSeleccionado
        
        if montoTotal > montoRequerido {
            // Reducir proporcionalmente
            let factor = montoRequerido / montoTotal
            for index in aportesSeleccionados.indices {
                aportesSeleccionados[index].montoAUsar *= factor
            }
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

// MARK: - Vista de Fila de Distribución
struct DistribucionRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let seleccion: AporteSeleccionado
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(seleccion.aporte.usuario)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(primaryTextColor)
                
                Text("Saldo: $\(String(format: "%.0f", seleccion.aporte.saldoDisponible))")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.0f", seleccion.montoAUsar))")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.green)
                
                Text("\(String(format: "%.1f", seleccion.porcentajeUso))%")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .secondary
    }
}

// MARK: - Vista de Fila de Aporte Múltiple
struct AporteMultipleRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let aporte: Aporte
    let seleccionado: AporteSeleccionado?
    let onToggle: () -> Void
    let onMontoChange: (Double) -> Void
    
    @State private var montoText = ""
    @State private var editandoMonto = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Fila principal
            HStack(spacing: 12) {
                // Checkbox de selección
                Button(action: onToggle) {
                    Image(systemName: seleccionado != nil ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(seleccionado != nil ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Info del aporte
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(aporte.usuario)
                            .font(.headline.weight(.medium))
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.0f", aporte.saldoDisponible))")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.green)
                    }
                    
                    Text("Total: $\(String(format: "%.0f", aporte.monto))")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
                
                // Icono de estado
                Image(systemName: seleccionado != nil ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(seleccionado != nil ? .green : .gray)
            }
            
            // Editor de monto si está seleccionado
            if let seleccion = seleccionado {
                MontoEditorView(
                    montoActual: seleccion.montoAUsar,
                    montoMaximo: aporte.saldoDisponible,
                    onMontoChange: onMontoChange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(seleccionado != nil ? 
                    AnyShapeStyle(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.8 : 0.1)) : 
                    AnyShapeStyle(.ultraThinMaterial.opacity(colorScheme == .dark ? 0.4 : 0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(seleccionado != nil ? Color.blue : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private var glassMaterial: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.ultraThinMaterial.opacity(0.4))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.6))
        }
    }
    
    private var glassMaterialSelected: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.ultraThinMaterial.opacity(0.8))
        } else {
            return AnyShapeStyle(Color.blue.opacity(0.1))
        }
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .secondary
    }
}

// MARK: - Editor de Monto
struct MontoEditorView: View {
    @Environment(\.colorScheme) private var colorScheme
    let montoActual: Double
    let montoMaximo: Double
    let onMontoChange: (Double) -> Void
    
    @State private var montoString: String = ""
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Monto a usar:")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Campo de texto
                TextField("0", text: $montoString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    .onChange(of: montoString) { _, newValue in
                        if let monto = Double(newValue) {
                            onMontoChange(monto)
                        }
                    }
                
                // Botones rápidos
                Button("25%") { aplicarPorcentaje(0.25) }
                    .buttonStyle(QuickButtonStyle())
                
                Button("50%") { aplicarPorcentaje(0.50) }
                    .buttonStyle(QuickButtonStyle())
                
                Button("100%") { aplicarPorcentaje(1.0) }
                    .buttonStyle(QuickButtonStyle())
            }
            
            // Slider
            Slider(
                value: Binding(
                    get: { montoActual },
                    set: { onMontoChange($0) }
                ),
                in: 0...montoMaximo,
                step: 1000
            )
            .accentColor(.blue)
        }
        .onAppear {
            montoString = String(format: "%.0f", montoActual)
        }
        .onChange(of: montoActual) { oldValue, newValue in
            montoString = String(format: "%.0f", newValue)
        }
    }
    
    private func aplicarPorcentaje(_ porcentaje: Double) {
        let nuevoMonto = montoMaximo * porcentaje
        onMontoChange(nuevoMonto)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .secondary
    }
}

// MARK: - Estilos de Botón
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.blue.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct QuickButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption2.weight(.medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.blue.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
