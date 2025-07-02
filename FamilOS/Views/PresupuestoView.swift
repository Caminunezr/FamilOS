import SwiftUI
import Charts // Importar Charts para los gráficos

struct PresupuestoView: View {
    @EnvironmentObject var viewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var mostrarFormularioAporte = false
    @State private var mostrarFormularioDeuda = false
    @State private var mostrarAlertaTransferencia = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Selector de mes
                    HStack {
                        Button {
                            viewModel.cambiarMes(avanzar: false)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(mesFormateado(viewModel.mesSeleccionado))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button {
                            viewModel.cambiarMes(avanzar: true)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Resumen financiero
                    ResumenFinancieroView(viewModel: viewModel)
                    
                    // Gráficos
                    GraficosPresupuestoView(viewModel: viewModel)
                    
                    // Lista de aportes
                    AportesListView(
                        aportes: viewModel.aportesDelMes,
                        total: viewModel.totalAportes,
                        onDelete: viewModel.eliminarAporte
                    )
                    
                    // Lista de gastos/deudas
                    DeudasListView(
                        deudas: viewModel.deudasDelMes,
                        total: viewModel.totalDeudasMensuales,
                        onDelete: { deudaId in viewModel.eliminarDeuda(deudaId) }
                    )
                    
                    // Acciones de presupuesto
                    AccionesPresupuestoView(
                        viewModel: viewModel,
                        mostrarAlertaTransferencia: $mostrarAlertaTransferencia
                    )
                }
                .padding()
            }
            .navigationTitle("Presupuesto Mensual")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        mostrarFormularioAporte = true
                    }) {
                        Label("Nuevo Aporte", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $mostrarFormularioAporte) {
            NuevoAporteView(viewModel: viewModel)
                .frame(width: 600, height: 750)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $mostrarFormularioDeuda) {
            NuevaDeudaView(viewModel: viewModel)
        }
    }
    
    // MARK: - Helper Methods
    private func mesFormateado(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: fecha).capitalized
    }
}

// MARK: - Vistas Complementarias

struct SelectorMesView: View {
    @Binding var mesSeleccionado: Date
    let cambiarMes: (Bool) -> Void
    
    var body: some View {
        HStack {
            Button {
                cambiarMes(false)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(mesFormateado)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button {
                cambiarMes(true)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var mesFormateado: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES") // Para nombres de mes en español
        return formatter.string(from: mesSeleccionado).capitalized
    }
}

struct ResumenFinancieroView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Resumen Financiero")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                PresupuestoCard(
                    titulo: "Ingresos",
                    valor: viewModel.totalAportes,
                    colorFondo: .green.opacity(0.2),
                    colorTexto: .green
                )
                
                PresupuestoCard(
                    titulo: "Gastos",
                    valor: viewModel.totalDeudasMensuales,
                    colorFondo: .red.opacity(0.2),
                    colorTexto: .red
                )
                
                PresupuestoCard(
                    titulo: "Disponible",
                    valor: viewModel.saldoDisponible,
                    colorFondo: .blue.opacity(0.2),
                    colorTexto: .blue
                )
            }
            
            // Mostrar sobrante transferido si existe
            if let presupuesto = viewModel.presupuestoActual, presupuesto.sobranteTransferido > 0 {
                HStack {
                    Image(systemName: "arrow.left.circle.fill")
                        .foregroundColor(.blue)
                    Text("Transferido del mes anterior: ")
                        .font(.subheadline)
                    Text("$\(presupuesto.sobranteTransferido, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct PresupuestoCard: View {
    let titulo: String
    let valor: Double
    let colorFondo: Color
    let colorTexto: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titulo)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("$\(valor, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(colorTexto)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(colorFondo)
        .cornerRadius(8)
    }
}

struct GraficosPresupuestoView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @State private var seleccionGrafico = 0
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Gráficos")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Picker("Tipo de Gráfico", selection: $seleccionGrafico) {
                Text("Aportes").tag(0)
                Text("Gastos").tag(1)
            }
            .pickerStyle(.segmented)
            
            if seleccionGrafico == 0 {
                GraficoAportes(datos: viewModel.datosGraficoAportes())
                    .frame(height: 220)
            } else {
                GraficoGastos(datos: viewModel.datosGraficoGastos())
                    .frame(height: 220)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct GraficoAportes: View {
    let datos: [(String, Double)]
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(datos, id: \.0) { item in
                        SectorMark(
                            angle: .value("Monto", item.1),
                            innerRadius: .ratio(0.6),
                            outerRadius: .ratio(1.0)
                        )
                        .foregroundStyle(by: .value("Categoría", item.0))
                        .annotation(position: .overlay) {
                            Text("\(Int(item.1 / datos.reduce(0) { $0 + $1.1 } * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                    }
                }
                .chartLegend(position: .bottom, alignment: .center)
            } else {
                // Fallback para versiones anteriores
                Text("Gráfico no disponible en esta versión de macOS")
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Leyenda alternativa para versiones anteriores
            VStack(alignment: .leading, spacing: 5) {
                ForEach(datos, id: \.0) { item in
                    HStack {
                        Circle()
                            .fill(Color.blue) // Usar colores dinámicos en implementación real
                            .frame(width: 12, height: 12)
                        
                        Text(item.0)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("$\(item.1, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.top, 5)
        }
    }
}

struct GraficoGastos: View {
    let datos: [(String, Double)]
    
    var body: some View {
        VStack {
            if #available(macOS 13.0, *) {
                Chart {
                    ForEach(datos, id: \.0) { item in
                        BarMark(
                            x: .value("Categoría", item.0),
                            y: .value("Monto", item.1)
                        )
                        .foregroundStyle(by: .value("Categoría", item.0))
                    }
                }
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisValueLabel {
                            if let string = value.as(String.self) {
                                Text(string)
                                    .font(.caption)
                                    .rotationEffect(.degrees(-45))
                            }
                        }
                    }
                }
            } else {
                // Fallback para versiones anteriores
                Text("Gráfico no disponible en esta versión de macOS")
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Leyenda alternativa
            VStack(alignment: .leading, spacing: 5) {
                ForEach(datos, id: \.0) { item in
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red) // Usar colores dinámicos en implementación real
                            .frame(width: 12, height: 12)
                        
                        Text(item.0)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text("$\(item.1, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(.top, 5)
        }
    }
}

struct AportesListView: View {
    let aportes: [Aporte]
    let total: Double
    let onDelete: (String) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Aportes")
                    .font(.headline)
                
                Spacer()
                
                Text("Total: $\(total, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if aportes.isEmpty {
                Text("No hay aportes registrados")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            } else {
                ForEach(aportes) { aporte in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(aporte.usuario)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(aporte.fechaDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(aporte.monto, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button {
                            onDelete(aporte.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct DeudasListView: View {
    let deudas: [DeudaPresupuesto]
    let total: Double
    let onDelete: (String) -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Gastos y Deudas")
                    .font(.headline)
                
                Spacer()
                
                Text("Total: $\(total, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if deudas.isEmpty {
                Text("No hay gastos registrados")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            } else {
                ForEach(deudas) { deuda in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(deuda.categoria)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            if deuda.cuotasTotales > 1 {
                                Text("Cuota mensual (\(deuda.cuotasTotales) cuotas)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Pago único")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("$\(deuda.montoCuotaMensual, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button {
                            onDelete(deuda.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Formularios

struct NuevoAporteView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Estados del formulario
    @State private var monto: Double = 0
    @State private var montoTexto: String = ""
    @State private var comentario: String = ""
    @State private var categoriaDetectada: CategoriaFinanciera? = nil
    @State private var mostrarNotasCompletas = false
    
    // Estados de UI
    @State private var mostrarSugerencias = false
    @State private var animacionMonto = false
    @State private var validacionActiva = false
    
    // Datos mockeados para los miembros de la familia
    // Sugerencias rápidas de montos
    private let sugerenciasRapidas = [100, 500, 1000, 1500, 2000, 5000]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                headerSection
                informacionUsuarioSection
                inputMontoSection
                categoriaDetectadaSection
                notasSection
                previewSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            
            ToolbarItem(placement: .confirmationAction) {
                saveButton
            }
        }
        .onAppear {
            // Inicialización si es necesaria
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("💰")
                    .font(.title)
                Text("Agregar Aporte")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Registra un nuevo ingreso al presupuesto familiar")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var informacionUsuarioSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Usuario")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let usuario = authViewModel.usuarioActual {
                HStack(spacing: 12) {
                    // Avatar del usuario
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(String(usuario.nombre.prefix(1)).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(usuario.nombre)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("Realizando aporte")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
            } else {
                Text("Error: Usuario no identificado")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal)
    }
    
    private var inputMontoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Monto del aporte")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Campo de entrada principal
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $montoTexto)
                        .font(.title2)
                        .fontWeight(.medium)
                        .onChange(of: montoTexto) { _, newValue in
                            if let valor = Double(newValue) {
                                monto = valor
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    animacionMonto = valor > 0
                                    mostrarSugerencias = false
                                }
                                detectarCategoria()
                            }
                        }
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                mostrarSugerencias = true
                            }
                        }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(inputBackground)
                .overlay(inputBorder)
                
                // Sugerencias rápidas
                if mostrarSugerencias {
                    sugerenciasRapidasGrid
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var inputBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                animacionMonto ? Color.blue : Color.clear,
                lineWidth: 2
            )
            .animation(.easeInOut(duration: 0.3), value: animacionMonto)
    }
    
    private var sugerenciasRapidasGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(sugerenciasRapidas, id: \.self) { sugerencia in
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        montoTexto = String(sugerencia)
                        monto = Double(sugerencia)
                        mostrarSugerencias = false
                        animacionMonto = true
                    }
                    detectarCategoria()
                } label: {
                    Text("$\(sugerencia)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    @ViewBuilder
    private var categoriaDetectadaSection: some View {
        if let categoria = categoriaDetectada {
            HStack {
                Image(systemName: categoria.icono)
                    .foregroundColor(.blue)
                Text("Categoría detectada: \(categoria.displayName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var notasSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Notas (opcional)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        mostrarNotasCompletas.toggle()
                    }
                } label: {
                    Image(systemName: mostrarNotasCompletas ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            if mostrarNotasCompletas {
                TextField(placeholderInteligente, text: $comentario, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 12)
                    .background(inputBackground)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var previewSection: some View {
        if monto > 0, let usuario = authViewModel.usuarioActual {
            VStack(spacing: 12) {
                Text("Vista previa")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(usuario.nombre.prefix(1)).uppercased())
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(Color.blue))
                            Text(usuario.nombre)
                                .fontWeight(.medium)
                        }
                        
                        Text("Aporte: $\(monto, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        if !comentario.isEmpty {
                            Text(comentario)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Nuevo total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("$\(viewModel.totalAportes + monto, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(previewBackground)
            }
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    private var previewBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color.green.opacity(0.1) : Color.green.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var saveButton: some View {
        Button("Guardar") {
            guardarAporte()
        }
        .fontWeight(.bold)
        .foregroundColor(formularioValido ? .blue : .gray)
        .disabled(!formularioValido)
        .scaleEffect(validacionActiva && formularioValido ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: validacionActiva)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                colorScheme == .dark ? Color.black.opacity(0.7) : Color.white.opacity(0.9),
                colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Computed Properties
    
    private var formularioValido: Bool {
        monto > 0 && authViewModel.usuarioActual != nil
    }
    
    private var placeholderInteligente: String {
        if monto > 0 {
            switch monto {
            case 0...500:
                return "Ej: Propina, regalo, venta pequeña..."
            case 501...2000:
                return "Ej: Bono, trabajo extra, reembolso..."
            case 2001...10000:
                return "Ej: Sueldo, comisión, préstamo familiar..."
            default:
                return "Ej: Sueldo principal, venta importante, herencia..."
            }
        }
        return "Describe el origen del aporte..."
    }
    
    // MARK: - Helper Methods
    
    private func detectarCategoria() {
        // Lógica simple de detección basada en el monto
        withAnimation(.easeInOut(duration: 0.3)) {
            switch monto {
            case 0...1000:
                categoriaDetectada = .varios // Ingresos pequeños
            case 1001...5000:
                categoriaDetectada = .servicios // Ingresos medianos
            case 5001...20000:
                categoriaDetectada = .vivienda // Sueldo principal
            default:
                categoriaDetectada = .varios // Ingresos grandes
            }
        }
    }
    
    private func guardarAporte() {
        guard let usuario = authViewModel.usuarioActual else { 
            print("❌ Error: No hay usuario autenticado")
            return 
        }
        
        guard let familiaId = viewModel.familiaId else {
            print("❌ Error: No hay familiaId configurado")
            return
        }
        
        print("🚀 Iniciando guardarAporte...")
        print("   - Usuario: \(usuario.nombre)")
        print("   - Monto: \(monto)")
        print("   - Comentario: '\(comentario)'")
        print("   - FamiliaId: \(familiaId)")
        
        Task {
            do {
                // Si no hay presupuesto actual, crearlo automáticamente
                let presupuestoParaAporte: PresupuestoMensual
                
                if let presupuestoExistente = viewModel.presupuestoActual {
                    print("📊 Usando presupuesto existente: \(presupuestoExistente.id)")
                    presupuestoParaAporte = presupuestoExistente
                } else {
                    print("📊 No hay presupuesto actual, creando uno nuevo...")
                    let nuevoPresupuesto = PresupuestoMensual(
                        fechaMes: viewModel.mesSeleccionado,
                        creador: usuario.nombre,
                        cerrado: false,
                        sobranteTransferido: 0
                    )
                    
                    try await viewModel.firebaseService.crearPresupuesto(
                        nuevoPresupuesto,
                        familiaId: familiaId
                    )
                    
                    print("✅ Presupuesto creado exitosamente: \(nuevoPresupuesto.id)")
                    presupuestoParaAporte = nuevoPresupuesto
                }
                
                // Crear el aporte con el presupuesto garantizado
                await crearAporteConPresupuesto(usuario: usuario, presupuesto: presupuestoParaAporte)
                
            } catch {
                print("❌ Error en el proceso de guardado: \(error.localizedDescription)")
                await MainActor.run {
                    // Aquí podrías mostrar un alert de error al usuario
                    viewModel.error = "Error al guardar el aporte: \(error.localizedDescription)"
                }
            }
        }
    }
    
    @MainActor
    private func crearAporteConPresupuesto(usuario: Usuario, presupuesto: PresupuestoMensual) async {
        print("📊 Creando aporte con presupuesto: \(presupuesto.id)")
        
        let nuevoAporte = Aporte(
            presupuestoId: presupuesto.id,
            usuario: usuario.nombre,
            monto: monto,
            comentario: comentario
        )
        
        print("📊 Aporte creado:")
        print("   - ID: \(nuevoAporte.id)")
        print("   - PresupuestoId: \(nuevoAporte.presupuestoId)")
        print("   - Usuario: \(nuevoAporte.usuario)")
        print("   - Monto: \(nuevoAporte.monto)")
        print("   - Fecha (timestamp): \(nuevoAporte.fecha)")
        print("   - Comentario: '\(nuevoAporte.comentario)'")
        
        viewModel.agregarAporte(nuevoAporte)
        
        // Cerrar con animación
        withAnimation(.easeInOut(duration: 0.3)) {
            dismiss()
        }
    }
}

struct NuevaDeudaView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @State private var categoriaSeleccionada: CategoriaFinanciera = .luz
    @State private var proveedorSeleccionado: String = ""
    @State private var montoTotal: Double = 0
    @State private var cuotasTotales: Int = 1
    @State private var tasaInteres: Double = 0
    @State private var descripcion: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Categoría y Proveedor")) {
                    SelectorCategoriaProveedor(
                        categoriaSeleccionada: $categoriaSeleccionada,
                        proveedorSeleccionado: $proveedorSeleccionado
                    )
                }
                
                Section(header: Text("Detalles del Gasto/Deuda")) {
                    TextField("Monto Total", value: $montoTotal, format: .number)
                    
                    Stepper("Cuotas: \(cuotasTotales)", value: $cuotasTotales, in: 1...60)
                    
                    if cuotasTotales > 1 {
                        TextField("Tasa de Interés (%)", value: $tasaInteres, format: .number)
                    }
                    
                    TextField("Descripción (opcional)", text: $descripcion)
                        .lineLimit(1...3)
                }
                
                Section(header: Text("Resumen")) {
                    if cuotasTotales > 1 {
                        let montoCuota = calcularCuotaMensual(montoTotal: montoTotal, cuotas: cuotasTotales, tasa: tasaInteres)
                        
                        Text("Cuota mensual: $\(montoCuota, specifier: "%.2f")")
                        
                        if tasaInteres > 0 {
                            Text("Total a pagar: $\(montoCuota * Double(cuotasTotales), specifier: "%.2f")")
                            
                            Text("Intereses: $\(montoCuota * Double(cuotasTotales) - montoTotal, specifier: "%.2f")")
                        }
                    }
                }
            }
            .navigationTitle("Nuevo Gasto/Deuda")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard let presupuestoActual = viewModel.presupuestoActual else { return }
                        
                        let nuevaDeuda = DeudaPresupuesto(
                            presupuestoId: presupuestoActual.id,
                            categoria: categoriaSeleccionada.rawValue,
                            montoTotal: montoTotal,
                            cuotasTotales: cuotasTotales,
                            tasaInteres: tasaInteres,
                            fechaInicio: presupuestoActual.fechaMes,
                            descripcion: descripcion
                        )
                        
                        viewModel.agregarDeuda(nuevaDeuda)
                        dismiss()
                    }
                    .disabled(proveedorSeleccionado.isEmpty || montoTotal <= 0)
                }
            }
        }
    }
    
    private func calcularCuotaMensual(montoTotal: Double, cuotas: Int, tasa: Double) -> Double {
        if tasa > 0 {
            let tasaDecimal = tasa / 100 / 12
            let factor = pow(1 + tasaDecimal, Double(cuotas))
            return montoTotal * tasaDecimal * factor / (factor - 1)
        } else {
            return montoTotal / Double(cuotas)
        }
    }
}

// MARK: - AccionesPresupuestoView

struct AccionesPresupuestoView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @Binding var mostrarAlertaTransferencia: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Acciones del Presupuesto")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let presupuesto = viewModel.presupuestoActual {
                // Presupuesto existente
                if !presupuesto.cerrado {
                    Button {
                        mostrarAlertaTransferencia = true
                    } label: {
                        Label("Cerrar Mes y Transferir Sobrante", systemImage: "arrow.right.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .alert("¿Transferir sobrante al próximo mes?", isPresented: $mostrarAlertaTransferencia) {
                        Button("Cancelar", role: .cancel) { }
                        Button("Transferir") {
                            viewModel.transferirSobrante()
                        }
                    } message: {
                        Text("Se transferirá \(viewModel.saldoDisponible, specifier: "%.2f") al siguiente mes y se cerrará el presupuesto actual.")
                    }
                } else {
                    Text("Este presupuesto está cerrado")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                // No hay presupuesto para este mes
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("No hay presupuesto para \(mesFormateado(viewModel.mesSeleccionado))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text("Los presupuestos se crean automáticamente al agregar el primer aporte del mes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(modernCardBackground)
        .cornerRadius(12)
        .shadow(color: cardShadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var modernCardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.ultraThinMaterial.opacity(0.6))
        } else {
            return AnyShapeStyle(Color.white.opacity(0.8))
        }
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1)
    }
    
    private func mesFormateado(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: fecha).capitalized
    }
}

// MARK: - NuevoPresupuestoView

struct NuevoPresupuestoView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var nombre: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    
                    VStack(spacing: 20) {
                        // Campo de nombre/título
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nombre del Presupuesto")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Ej: Presupuesto Familiar Enero", text: $nombre)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(inputBackground)
                                .cornerRadius(12)
                        }
                        
                        // Vista previa
                        previewSection
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Nuevo Presupuesto")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        crearPresupuesto()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(formularioValido ? .blue : .gray)
                    .disabled(!formularioValido)
                }
            }
        }
        .onAppear {
            // Generar nombre por defecto
            nombre = "Presupuesto \(mesFormateado(viewModel.mesSeleccionado))"
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📊")
                    .font(.title)
                Text("Crear Presupuesto")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Define un nuevo presupuesto para \(mesFormateado(viewModel.mesSeleccionado))")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var previewSection: some View {
        if !nombre.isEmpty {
            VStack(spacing: 12) {
                Text("Vista previa")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(nombre)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Mes: \(mesFormateado(viewModel.mesSeleccionado))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(previewBackground)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    // MARK: - Computed Properties
    
    private var formularioValido: Bool {
        !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.8))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var previewBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
    
    // MARK: - Methods
    
    private func crearPresupuesto() {
        let nuevoPresupuesto = PresupuestoMensual(
            fechaMes: viewModel.mesSeleccionado,
            creador: "Usuario", // En una implementación real, esto vendría del usuario autenticado
            cerrado: false,
            sobranteTransferido: 0
        )
        
        viewModel.crearPresupuestoMensual(nuevoPresupuesto)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            dismiss()
        }
    }
    
    private func mesFormateado(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: fecha).capitalized
    }
}

// MARK: - Previews

struct PresupuestoView_Previews: PreviewProvider {
    static var previews: some View {
        PresupuestoView()
    }
}