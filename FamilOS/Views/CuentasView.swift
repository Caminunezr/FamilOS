import SwiftUI

struct CuentasView: View {
    @StateObject var viewModel = CuentasViewModel()
    @State private var mostrarFormularioNuevaCuenta = false
    @State private var cuentaSeleccionada: Cuenta? = nil
    
    var body: some View {
        NavigationSplitView {
            List {
                Section(header: Text("Filtros")) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Buscar cuentas...", text: $viewModel.busquedaTexto)
                    }
                    
                    Picker("Estado", selection: $viewModel.filtroEstado) {
                        Text("Todos").tag(nil as Cuenta.EstadoCuenta?)
                        Text("Pendientes").tag(Cuenta.EstadoCuenta.pendiente as Cuenta.EstadoCuenta?)
                        Text("Pagadas").tag(Cuenta.EstadoCuenta.pagada as Cuenta.EstadoCuenta?)
                        Text("Vencidas").tag(Cuenta.EstadoCuenta.vencida as Cuenta.EstadoCuenta?)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Mis Cuentas")) {
                    ForEach(viewModel.cuentasFiltradas) { cuenta in
                        CuentaItemView(cuenta: cuenta)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                cuentaSeleccionada = cuenta
                            }
                    }
                }
            }
            .navigationTitle("Gestión de Cuentas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        mostrarFormularioNuevaCuenta = true
                    }) {
                        Label("Agregar Cuenta", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let cuenta = cuentaSeleccionada {
                CuentaDetalleView(cuenta: cuenta)
            } else {
                Text("Selecciona una cuenta para ver sus detalles")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $mostrarFormularioNuevaCuenta) {
            NuevaCuentaView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.cargarDatosEjemplo()
        }
    }
}

struct CuentaItemView: View {
    let cuenta: Cuenta
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(cuenta.nombre)
                    .font(.headline)
                Text(cuenta.proveedor)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(cuenta.monto, specifier: "%.2f")")
                    .font(.headline)
                
                Text(estadoFormateado)
                    .font(.caption)
                    .padding(5)
                    .background(colorEstado)
                    .foregroundColor(.white)
                    .cornerRadius(5)
            }
        }
        .padding(.vertical, 5)
    }
    
    var colorEstado: Color {
        switch cuenta.estado {
        case .pagada: return .green
        case .pendiente: return .blue
        case .vencida: return .red
        }
    }
    
    var estadoFormateado: String {
        switch cuenta.estado {
        case .pagada: return "PAGADA"
        case .pendiente: return "PENDIENTE"
        case .vencida: return "VENCIDA"
        }
    }
}

struct CuentaDetalleView: View {
    let cuenta: Cuenta
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado con monto y estado
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text(cuenta.nombre)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(cuenta.proveedor)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(cuenta.monto, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(estadoFormateado)
                            .font(.headline)
                            .padding(8)
                            .background(colorEstado)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Detalles de la cuenta
                VStack(alignment: .leading, spacing: 15) {
                    DetalleItem(titulo: "Categoría", valor: cuenta.categoria)
                    
                    DetalleItem(titulo: "Fecha de Emisión", 
                              valor: cuenta.fechaEmision?.formatted(date: .long, time: .omitted) ?? "No disponible")
                    
                    DetalleItem(titulo: "Fecha de Vencimiento", 
                              valor: cuenta.fechaVencimiento.formatted(date: .long, time: .omitted))
                    
                    if !cuenta.descripcion.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Descripción")
                                .font(.headline)
                            
                            Text(cuenta.descripcion)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    if cuenta.facturaURL != nil {
                        Button(action: {
                            // Acción para ver la factura
                        }) {
                            Label("Ver Factura", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Detalles de Cuenta")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    // Acción para editar la cuenta
                }) {
                    Text("Editar")
                }
            }
        }
    }
    
    var colorEstado: Color {
        switch cuenta.estado {
        case .pagada: return .green
        case .pendiente: return .blue
        case .vencida: return .red
        }
    }
    
    var estadoFormateado: String {
        switch cuenta.estado {
        case .pagada: return "PAGADA"
        case .pendiente: return "PENDIENTE"
        case .vencida: return "VENCIDA"
        }
    }
}

struct DetalleItem: View {
    let titulo: String
    let valor: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(titulo)
                .font(.headline)
            Text(valor)
                .font(.body)
        }
    }
}

struct NuevaCuentaView: View {
    @ObservedObject var viewModel: CuentasViewModel
    @State private var monto: Double = 0
    @State private var proveedor: String = ""
    @State private var fechaVencimiento: Date = Date()
    @State private var fechaEmision: Date? = nil
    @State private var usarFechaEmision: Bool = false
    @State private var categoria: String = ""
    @State private var descripcion: String = ""
    @State private var nombre: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información Básica")) {
                    TextField("Monto", value: $monto, format: .number)
                        .keyboardType(.decimalPad)
                    
                    TextField("Proveedor", text: $proveedor)
                    
                    TextField("Nombre (opcional)", text: $nombre)
                    
                    Picker("Categoría", selection: $categoria) {
                        ForEach(viewModel.categoriasDisponibles, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                        Text("Otra").tag("Otra")
                    }
                    
                    if categoria == "Otra" {
                        TextField("Especificar categoría", text: $categoria)
                    }
                }
                
                Section(header: Text("Fechas")) {
                    DatePicker("Fecha de Vencimiento", selection: $fechaVencimiento, displayedComponents: .date)
                    
                    Toggle("Incluir fecha de emisión", isOn: $usarFechaEmision)
                    
                    if usarFechaEmision {
                        DatePicker("Fecha de Emisión", selection: Binding(
                            get: { fechaEmision ?? Date() },
                            set: { fechaEmision = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                Section(header: Text("Detalles")) {
                    TextField("Descripción", text: $descripcion, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Nueva Cuenta")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let nuevaCuenta = Cuenta(
                            monto: monto,
                            proveedor: proveedor,
                            fechaVencimiento: fechaVencimiento,
                            categoria: categoria,
                            creador: "Usuario",
                            fechaEmision: usarFechaEmision ? fechaEmision : nil,
                            descripcion: descripcion,
                            nombre: nombre
                        )
                        
                        viewModel.agregarCuenta(nuevaCuenta)
                        dismiss()
                    }
                    .disabled(proveedor.isEmpty || monto <= 0 || categoria.isEmpty)
                }
            }
        }
    }
}