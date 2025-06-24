import SwiftUI
import Charts

struct PresupuestoView: View {
    @StateObject private var viewModel = PresupuestoViewModel()
    @State private var mostrarFormularioAporte = false
    @State private var mostrarFormularioDeuda = false
    @State private var mostrarAlertaTransferencia = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Selector de mes
                    SelectorMesView(
                        mesSeleccionado: $viewModel.mesSeleccionado,
                        cambiarMes: viewModel.cambiarMes
                    )
                    
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
                        onDelete: viewModel.eliminarDeuda
                    )
                    
                    // Acciones de presupuesto
                    if let presupuesto = viewModel.presupuestoActual {
                        VStack(spacing: 15) {
                            Text("Acciones del Presupuesto")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
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
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Presupuesto Mensual")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            mostrarFormularioAporte = true
                        } label: {
                            Label("Agregar Aporte", systemImage: "plus.circle")
                        }
                        
                        Button {
                            mostrarFormularioDeuda = true
                        } label: {
                            Label("Agregar Gasto/Deuda", systemImage: "minus.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $mostrarFormularioAporte) {
            NuevoAporteView(viewModel: viewModel)
        }
        .sheet(isPresented: $mostrarFormularioDeuda) {
            NuevaDeudaView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.cargarDatosEjemplo()
        }
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
    let onDelete: (UUID) -> Void
    
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
                            
                            Text(aporte.fecha.formatted(date: .abbreviated, time: .omitted))
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
    let onDelete: (UUID) -> Void
    
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
    @State private var usuario: String = ""
    @State private var monto: Double = 0
    @State private var comentario: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles del Aporte")) {
                    TextField("Usuario", text: $usuario)
                    
                    TextField("Monto", value: $monto, format: .number)
                    
                    TextField("Comentario (opcional)", text: $comentario)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("Nuevo Aporte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guard let presupuestoActual = viewModel.presupuestoActual else { return }
                        
                        let nuevoAporte = Aporte(
                            presupuestoId: presupuestoActual.id,
                            usuario: usuario,
                            monto: monto,
                            comentario: comentario
                        )
                        
                        viewModel.agregarAporte(nuevoAporte)
                        dismiss()
                    }
                    .disabled(usuario.isEmpty || monto <= 0)
                }
            }
        }
    }
}

struct NuevaDeudaView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @State private var categoria: String = ""
    @State private var montoTotal: Double = 0
    @State private var cuotasTotales: Int = 1
    @State private var tasaInteres: Double = 0
    @State private var descripcion: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles del Gasto/Deuda")) {
                    TextField("Categoría", text: $categoria)
                    
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
                            categoria: categoria,
                            montoTotal: montoTotal,
                            cuotasTotales: cuotasTotales,
                            tasaInteres: tasaInteres,
                            fechaInicio: presupuestoActual.fechaMes,
                            descripcion: descripcion
                        )
                        
                        viewModel.agregarDeuda(nuevaDeuda)
                        dismiss()
                    }
                    .disabled(categoria.isEmpty || montoTotal <= 0)
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

struct PresupuestoView_Previews: PreviewProvider {
    static var previews: some View {
        PresupuestoView()
    }
}