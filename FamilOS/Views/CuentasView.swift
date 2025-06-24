import SwiftUI
import Combine

struct CuentasView: View {
    @StateObject var viewModel = CuentasViewModel()
    @State private var mostrarFormularioNuevaCuenta = false
    @State private var cuentaSeleccionada: Cuenta? = nil
    @State private var mostrarFiltrosAvanzados = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar con dashboard y navegación
            dashboardSidebar
        } detail: {
            if let cuenta = cuentaSeleccionada {
                CuentaDetalleView(cuenta: cuenta, viewModel: viewModel)
            } else {
                dashboardPrincipal
            }
        }
        .sheet(isPresented: $mostrarFormularioNuevaCuenta) {
            NuevaCuentaView(viewModel: viewModel, mostrarFormulario: $mostrarFormularioNuevaCuenta)
        }
        .onAppear {
            viewModel.cargarDatosEjemplo()
        }
    }
    
    // MARK: - Dashboard Sidebar
    private var dashboardSidebar: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header con navegación temporal
                navegacionTemporal
                
                // Resumen rápido
                resumenRapido
                
                // Cuentas próximas a vencer
                cuentasProximasVencer
                
                // Lista de cuentas por año (única vista)
                listaCuentasPorAño
                
                // Filtros avanzados
                if mostrarFiltrosAvanzados {
                    seccionFiltros
                }
            }
            .padding()
        }
        .navigationTitle("Gestión Inteligente")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    mostrarFormularioNuevaCuenta = true
                }) {
                    Label("Nueva Cuenta", systemImage: "plus.circle.fill")
                }
            }
            
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    mostrarFiltrosAvanzados.toggle()
                }) {
                    Label("Filtros", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
    
    // MARK: - Navegación Temporal
    private var navegacionTemporal: some View {
        VStack(spacing: 12) {
            // Ya solo tenemos "Por Año", así que podemos simplificar
            HStack {
                Text("Vista: Por Año")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
            }
            
            // Navegación para filtro por estado
            navegacionFiltroEstado
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Navegación Filtro Estado
    private var navegacionFiltroEstado: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Filtrar por Estado:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            HStack(spacing: 8) {
                FilterChip(texto: "Todas", seleccionado: viewModel.filtroEstadoOrganizacion == .todas) {
                    viewModel.filtroEstadoOrganizacion = .todas
                }
                
                FilterChip(texto: "Pendientes", seleccionado: viewModel.filtroEstadoOrganizacion == .pendientes) {
                    viewModel.filtroEstadoOrganizacion = .pendientes
                }
                
                FilterChip(texto: "Pagadas", seleccionado: viewModel.filtroEstadoOrganizacion == .pagadas) {
                    viewModel.filtroEstadoOrganizacion = .pagadas
                }
                
                FilterChip(texto: "Vencidas", seleccionado: viewModel.filtroEstadoOrganizacion == .vencidas) {
                    viewModel.filtroEstadoOrganizacion = .vencidas
                }
            }
            
            // Mostrar contador de cuentas filtradas
            if viewModel.filtroEstadoOrganizacion != .todas {
                let estado = viewModel.filtroEstadoOrganizacion
                let cuentasFiltradas = viewModel.cuentasPorAñoYMesFiltradas.reduce(0) { $0 + $1.totalCuentas }
                Text("\(cuentasFiltradas) cuentas \(estado.rawValue.lowercased())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(viewModel.cuentas.count) cuentas en total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    

    
    // MARK: - Resumen Rápido
    private var resumenRapido: some View {
        let resumen = viewModel.resumenMensual
        
        return VStack(spacing: 12) {
            Text("Resumen del Mes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ResumenCard(
                    titulo: "Total",
                    valor: String(format: "%.0f", resumen.totalMonto),
                    icono: "creditcard",
                    color: .blue
                )
                
                ResumenCard(
                    titulo: "Pagado",
                    valor: String(format: "%.0f", resumen.montoPagado),
                    icono: "checkmark.circle",
                    color: .green
                )
                
                ResumenCard(
                    titulo: "Pendiente",
                    valor: String(format: "%.0f", resumen.montoPendiente),
                    icono: "clock",
                    color: .orange
                )
                
                ResumenCard(
                    titulo: "Vencido",
                    valor: String(format: "%.0f", resumen.montoVencido),
                    icono: "exclamationmark.triangle",
                    color: .red
                )
            }
            
            // Barra de progreso
            ProgressView(value: resumen.porcentajePagado, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .background(Color.gray.opacity(0.2))
            
            Text("\(resumen.porcentajePagado, specifier: "%.1f")% completado")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Cuentas Próximas a Vencer
    private var cuentasProximasVencer: some View {
        let cuentasProximas = viewModel.cuentasProximasVencer
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Próximas a Vencer")
                .font(.headline)
                .foregroundColor(.orange)
            
            if cuentasProximas.isEmpty {
                Text("No hay cuentas próximas a vencer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ForEach(cuentasProximas) { cuenta in
                    CuentaCompactaView(cuenta: cuenta) {
                        cuentaSeleccionada = cuenta
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .cornerRadius(12)
    }
    

    
    // MARK: - Lista de Cuentas por Año
    private var listaCuentasPorAño: some View {
        let cuentasOrganizadas = viewModel.cuentasPorAñoYMesFiltradas
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Organización por Año → Mes")
                    .font(.headline)
                
                Spacer()
                
                let totalCuentas = cuentasOrganizadas.reduce(0) { $0 + $1.totalCuentas }
                Text("\(totalCuentas) cuentas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if cuentasOrganizadas.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.filtroEstadoOrganizacion.icono)
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No hay cuentas \(viewModel.filtroEstadoOrganizacion.rawValue.lowercased())")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Cambia el filtro para ver más cuentas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else {
                ForEach(cuentasOrganizadas) { añoCuentas in
                    VStack(alignment: .leading, spacing: 12) {
                        // Header del año
                        AñoHeaderView(añoCuentas: añoCuentas)
                        
                        // Meses del año
                        ForEach(añoCuentas.meses) { mesCuentas in
                            MesSeccionView(
                                mesCuentas: mesCuentas,
                                cuentaSeleccionada: $cuentaSeleccionada
                            )
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    

    
    // MARK: - Sección Filtros
    private var seccionFiltros: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filtros Avanzados")
                .font(.headline)
            
            // Filtro por categoría
            VStack(alignment: .leading, spacing: 8) {
                Text("Categoría")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(texto: "Todas", seleccionado: viewModel.filtroCategorias.isEmpty) {
                            viewModel.filtroCategorias.removeAll()
                        }
                        
                        ForEach(viewModel.categoriasDisponibles, id: \.self) { categoria in
                            FilterChip(
                                texto: categoria, 
                                seleccionado: viewModel.filtroCategorias.contains(categoria)
                            ) {
                                if viewModel.filtroCategorias.contains(categoria) {
                                    viewModel.filtroCategorias.remove(categoria)
                                } else {
                                    viewModel.filtroCategorias.insert(categoria)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Filtro por estado
            VStack(alignment: .leading, spacing: 8) {
                Text("Estado")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    FilterChip(texto: "Todas", seleccionado: viewModel.filtroEstado == nil) {
                        viewModel.filtroEstado = nil
                    }
                    
                    FilterChip(texto: "Pendientes", seleccionado: viewModel.filtroEstado == .pendiente) {
                        viewModel.filtroEstado = .pendiente
                    }
                    
                    FilterChip(texto: "Pagadas", seleccionado: viewModel.filtroEstado == .pagada) {
                        viewModel.filtroEstado = .pagada
                    }
                    
                    FilterChip(texto: "Vencidas", seleccionado: viewModel.filtroEstado == .vencida) {
                        viewModel.filtroEstado = .vencida
                    }
                }
            }
            
            // Botón para limpiar filtros
            Button(action: viewModel.limpiarFiltros) {
                Text("Limpiar Filtros")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Dashboard Principal
    private var dashboardPrincipal: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header con estadísticas
                estadisticasGenerales
                
                // Gráficos y análisis
                graficosAnalisis
                
                // Análisis por categoría
                analisisPorCategoria
                
                // Resumen por proveedor
                resumenProveedores
            }
            .padding()
        }
        .navigationTitle("Dashboard Principal")
    }
    
    // MARK: - Estadísticas Generales
    private var estadisticasGenerales: some View {
        let resumen = viewModel.resumenMensual
        
        return VStack(spacing: 16) {
            Text("Estadísticas del Mes")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                EstadisticaCard(
                    titulo: "Total Cuentas",
                    valor: "\(viewModel.cuentasMesActual.count)",
                    icono: "doc.text",
                    color: .blue
                )
                
                EstadisticaCard(
                    titulo: "Promedio",
                    valor: String(format: "%.0f", resumen.totalMonto / Double(max(1, viewModel.cuentasMesActual.count))),
                    icono: "chart.bar",
                    color: .purple
                )
                
                EstadisticaCard(
                    titulo: "Ahorro",
                    valor: String(format: "%.0f", max(0, resumen.totalMonto - resumen.montoPagado)),
                    icono: "banknote",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Gráficos y Análisis
    private var graficosAnalisis: some View {
        VStack(spacing: 16) {
            Text("Análisis Visual")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Distribución por estado (gráfico de barras simple)
            HStack(alignment: .bottom, spacing: 12) {
                let resumen = viewModel.resumenMensual
                
                BarraGrafico(
                    valor: resumen.montoPagado,
                    total: resumen.totalMonto,
                    titulo: "Pagado",
                    color: .green
                )
                
                BarraGrafico(
                    valor: resumen.montoPendiente,
                    total: resumen.totalMonto,
                    titulo: "Pendiente",
                    color: .orange
                )
                
                BarraGrafico(
                    valor: resumen.montoVencido,
                    total: resumen.totalMonto,
                    titulo: "Vencido",
                    color: .red
                )
            }
            .frame(height: 150)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Análisis por Categoría
    private var analisisPorCategoria: some View {
        let analisisCategoria = viewModel.analisisPorCategoria
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Gastos por Categoría")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(analisisCategoria, id: \.categoria) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.categoria)
                            .font(.headline)
                        
                        Text("\(item.cantidad) cuenta(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(item.total, specifier: "%.0f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("\(item.porcentaje, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.02))
        .cornerRadius(16)
    }
    
    // MARK: - Resumen por Proveedor
    private var resumenProveedores: some View {
        let topProveedores = viewModel.topProveedores
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Top Proveedores")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(topProveedores.prefix(5), id: \.proveedor) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.proveedor)
                            .font(.headline)
                        
                        Text("\(item.cantidad) cuenta(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$\(item.total, specifier: "%.0f")")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.02))
        .cornerRadius(16)
    }
}

// MARK: - Componentes Auxiliares

struct ResumenCard: View {
    let titulo: String
    let valor: String
    let icono: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icono)
                .font(.title2)
                .foregroundColor(color)
            
            Text(valor)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EstadisticaCard: View {
    let titulo: String
    let valor: String
    let icono: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icono)
                .font(.title2)
                .foregroundColor(color)
            
            Text(valor)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let texto: String
    let seleccionado: Bool
    let accion: () -> Void
    
    var body: some View {
        Button(action: accion) {
            Text(texto)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(seleccionado ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(seleccionado ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CuentaCompactaView: View {
    let cuenta: Cuenta
    let accion: () -> Void
    
    var body: some View {
        Button(action: accion) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(cuenta.nombre.isEmpty ? cuenta.proveedor : cuenta.nombre)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("Vence: \(cuenta.fechaVencimiento, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(cuenta.monto, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(estadoTexto)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colorEstado)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.8))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var estadoTexto: String {
        switch cuenta.estado {
        case .pagada: return "PAGADA"
        case .pendiente: return "PENDIENTE"
        case .vencida: return "VENCIDA"
        }
    }
    
    private var colorEstado: Color {
        switch cuenta.estado {
        case .pagada: return .green
        case .pendiente: return .orange
        case .vencida: return .red
        }
    }
}

struct BarraGrafico: View {
    let valor: Double
    let total: Double
    let titulo: String
    let color: Color
    
    private var porcentaje: Double {
        guard total > 0 else { return 0 }
        return (valor / total) * 100
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Barra
            VStack {
                Spacer()
                
                Rectangle()
                    .fill(color)
                    .frame(height: max(4, porcentaje * 1.2))  // Altura mínima de 4
                    .cornerRadius(4)
            }
            .frame(maxHeight: .infinity)
            
            // Etiquetas
            VStack(spacing: 2) {
                Text("$\(valor, specifier: "%.0f")")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(titulo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(porcentaje, specifier: "%.0f")%")
                    .font(.caption2)
                    .foregroundColor(color)
            }
        }
        .frame(minWidth: 60)
    }
}

struct CuentaItemView: View {
    let cuenta: Cuenta
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(cuenta.nombre.isEmpty ? cuenta.proveedor : cuenta.nombre)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(cuenta.categoria)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text(cuenta.proveedor)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(cuenta.monto, specifier: "%.0f")")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text("Vence: \(cuenta.fechaVencimiento, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(estadoFormateado)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(colorEstado)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var colorEstado: Color {
        switch cuenta.estado {
        case .pagada: return .green
        case .pendiente: return .blue
        case .vencida: return .red
        }
    }
    
    private var estadoFormateado: String {
        switch cuenta.estado {
        case .pagada: return "PAGADA"
        case .pendiente: return "PENDIENTE"
        case .vencida: return "VENCIDA"
        }
    }
}

struct CuentaDetalleView: View {
    let cuenta: Cuenta
    @ObservedObject var viewModel: CuentasViewModel
    @State private var mostrarFormularioPago = false
    @State private var mostrarVisorArchivos = false
    @State private var mostrarEdicion = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Encabezado con monto y estado
                encabezadoCuenta
                
                // Detalles de la cuenta
                detallesCuenta
                
                // Sección de archivos
                seccionArchivos
                
                // Sección de pagos
                seccionPagos
                
                // Acciones principales
                accionesPrincipales
            }
            .padding()
        }
        .navigationTitle("Detalles de Cuenta")
        .sheet(isPresented: $mostrarFormularioPago) {
            FormularioPagoView(cuenta: cuenta, viewModel: viewModel)
        }
        .sheet(isPresented: $mostrarVisorArchivos) {
            VisorArchivosView(cuenta: cuenta)
        }
        .sheet(isPresented: $mostrarEdicion) {
            EditarCuentaView(cuenta: cuenta, viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    mostrarEdicion = true
                }) {
                    Label("Editar", systemImage: "pencil")
                }
            }
        }
    }
    
    // MARK: - Encabezado
    private var encabezadoCuenta: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cuenta.nombre.isEmpty ? cuenta.proveedor : cuenta.nombre)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if !cuenta.nombre.isEmpty {
                        Text(cuenta.proveedor)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(cuenta.categoria)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("$\(cuenta.monto, specifier: "%.0f")")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(estadoFormateado)
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(colorEstado)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            // Días hasta vencimiento
            if cuenta.estado != .pagada {
                let diasVencimiento = Calendar.current.dateComponents([.day], from: Date(), to: cuenta.fechaVencimiento).day ?? 0
                
                HStack {
                    Image(systemName: diasVencimiento < 0 ? "exclamationmark.triangle.fill" : "clock")
                        .foregroundColor(diasVencimiento < 0 ? .red : .orange)
                    
                    Text(diasVencimiento < 0 ? 
                         "Vencida hace \(abs(diasVencimiento)) días" : 
                         "Vence en \(diasVencimiento) días")
                        .font(.subheadline)
                        .foregroundColor(diasVencimiento < 0 ? .red : .orange)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [colorEstado.opacity(0.1), colorEstado.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    // MARK: - Detalles
    private var detallesCuenta: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Información Detallada")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DetalleCard(titulo: "Fecha de Emisión", 
                          valor: cuenta.fechaEmision?.formatted(date: .abbreviated, time: .omitted) ?? "No disponible")
                
                DetalleCard(titulo: "Fecha de Vencimiento", 
                          valor: cuenta.fechaVencimiento.formatted(date: .abbreviated, time: .omitted))
                
                if let fechaPago = cuenta.fechaPago {
                    DetalleCard(titulo: "Fecha de Pago", 
                              valor: fechaPago.formatted(date: .abbreviated, time: .omitted))
                    DetalleCard(titulo: "Monto Pagado", 
                              valor: String(format: "%.2f", cuenta.montoPagado ?? 0))
                }
            }
            
            if !cuenta.descripcion.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Descripción")
                        .font(.headline)
                    
                    Text(cuenta.descripcion)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.03))
        .cornerRadius(16)
    }
    
    // MARK: - Sección de Archivos
    private var seccionArchivos: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Archivos y Documentos")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                if cuenta.facturaURL != nil {
                    ArchivoCard(
                        titulo: "Factura",
                        icono: "doc.text",
                        color: .blue
                    ) {
                        mostrarVisorArchivos = true
                    }
                }
                
                if cuenta.comprobanteURL != nil {
                    ArchivoCard(
                        titulo: "Comprobante",
                        icono: "doc.badge.checkmark",
                        color: .green
                    ) {
                        mostrarVisorArchivos = true
                    }
                }
                
                ArchivoCard(
                    titulo: "Agregar",
                    icono: "plus.circle",
                    color: .orange
                ) {
                    // Acción para agregar archivo
                }
            }
            
            if cuenta.facturaURL == nil && cuenta.comprobanteURL == nil {
                Text("No hay archivos adjuntos")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.03))
        .cornerRadius(16)
    }
    
    // MARK: - Sección de Pagos
    private var seccionPagos: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gestión de Pagos")
                .font(.title2)
                .fontWeight(.bold)
            
            if cuenta.estado == .pagada {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Cuenta Pagada")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    
                    if let fechaPago = cuenta.fechaPago {
                        Text("Pagada el \(fechaPago.formatted(date: .long, time: .omitted))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Monto pagado: $\(cuenta.montoPagado ?? 0, specifier: "%.0f")")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if let montoPagado = cuenta.montoPagado, montoPagado != cuenta.monto {
                            Text("Diferencia: $\(cuenta.monto - montoPagado, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(montoPagado > cuenta.monto ? .green : .red)
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: {
                    mostrarFormularioPago = true
                }) {
                    Label("Registrar Pago", systemImage: "creditcard")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.03))
        .cornerRadius(16)
    }
    
    // MARK: - Acciones Principales
    private var accionesPrincipales: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    // Duplicar cuenta
                    viewModel.duplicarCuenta(cuenta)
                }) {
                    Label("Duplicar", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // Compartir cuenta
                }) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
            
            Button(action: {
                // Eliminar cuenta
                viewModel.eliminarCuenta(cuenta)
            }) {
                Label("Eliminar Cuenta", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.03))
        .cornerRadius(16)
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

// MARK: - Componentes para Detalle de Cuenta

struct DetalleCard: View {
    let titulo: String
    let valor: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(valor)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ArchivoCard: View {
    let titulo: String
    let icono: String
    let color: Color
    let accion: () -> Void
    
    var body: some View {
        Button(action: accion) {
            VStack(spacing: 8) {
                Image(systemName: icono)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(titulo)
                    .font(.caption)
                    .foregroundColor(color)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FormularioPagoView: View {
    let cuenta: Cuenta
    @ObservedObject var viewModel: CuentasViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var montoPago: Double = 0
    @State private var fechaPago: Date = Date()
    @State private var notas: String = ""
    @State private var tieneComprobante: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Información del Pago")) {
                    HStack {
                        Text("Cuenta:")
                        Spacer()
                        Text(cuenta.nombre.isEmpty ? cuenta.proveedor : cuenta.nombre)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Monto original:")
                        Spacer()
                        Text("$\(cuenta.monto, specifier: "%.0f")")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Monto a pagar:")
                        TextField("0", value: $montoPago, format: .number)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    DatePicker("Fecha de pago", selection: $fechaPago, displayedComponents: .date)
                }
                
                Section(header: Text("Detalles Adicionales")) {
                    TextField("Notas (opcional)", text: $notas, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Toggle("Tengo comprobante", isOn: $tieneComprobante)
                }
                
                if montoPago != cuenta.monto && montoPago > 0 {
                    Section {
                        HStack {
                            Text("Diferencia:")
                            Spacer()
                            Text("$\(abs(cuenta.monto - montoPago), specifier: "%.0f")")
                                .foregroundColor(montoPago > cuenta.monto ? .green : .red)
                            Text(montoPago > cuenta.monto ? "(Sobrepago)" : "(Pago parcial)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Registrar Pago")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        viewModel.registrarPago(
                            cuenta: cuenta,
                            monto: montoPago,
                            fecha: fechaPago,
                            notas: notas,
                            tieneComprobante: tieneComprobante
                        )
                        dismiss()
                    }
                    .disabled(montoPago <= 0)
                }
            }
            .onAppear {
                montoPago = cuenta.monto
            }
        }
    }
}

struct VisorArchivosView: View {
    let cuenta: Cuenta
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if cuenta.facturaURL != nil {
                        ArchivoVisualizador(
                            titulo: "Factura Original",
                            url: cuenta.facturaURL,
                            icono: "doc.text"
                        )
                    }
                    
                    if cuenta.comprobanteURL != nil {
                        ArchivoVisualizador(
                            titulo: "Comprobante de Pago",
                            url: cuenta.comprobanteURL,
                            icono: "doc.badge.checkmark"
                        )
                    }
                    
                    if cuenta.facturaURL == nil && cuenta.comprobanteURL == nil {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No hay archivos disponibles")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Los archivos adjuntos aparecerán aquí una vez que sean agregados.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 50)
                    }
                }
                .padding()
            }
            .navigationTitle("Archivos")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ArchivoVisualizador: View {
    let titulo: String
    let url: URL?
    let icono: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icono)
                    .foregroundColor(.blue)
                
                Text(titulo)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // Abrir archivo
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                }
            }
            
            // Placeholder para vista previa del archivo
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("Vista previa del archivo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct EditarCuentaView: View {
    let cuenta: Cuenta
    @ObservedObject var viewModel: CuentasViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var monto: Double = 0
    @State private var proveedor: String = ""
    @State private var fechaVencimiento: Date = Date()
    @State private var fechaEmision: Date? = nil
    @State private var usarFechaEmision: Bool = false
    @State private var categoria: String = ""
    @State private var descripcion: String = ""
    @State private var nombre: String = ""
    
    var body: some View {
        ZStack {
            // Fondo con efecto vidrio esmerilado estilo macOS
            backgroundView
            
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header con icono
                        headerSection
                        
                        // Formulario con estilo glassmorphism
                        formularioSection
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 24)
                }
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            viewModel.actualizarCuenta(
                                cuenta,
                                monto: monto,
                                proveedor: proveedor,
                                fechaVencimiento: fechaVencimiento,
                                categoria: categoria,
                                descripcion: descripcion,
                                nombre: nombre,
                                fechaEmision: usarFechaEmision ? fechaEmision : nil
                            )
                            dismiss()
                        }
                        .disabled(proveedor.isEmpty || monto <= 0 || categoria.isEmpty)
                        .buttonStyle(GlassButtonStyle(isDisabled: proveedor.isEmpty || monto <= 0 || categoria.isEmpty))
                    }
                }
                .onAppear {
                    viewModel.cargarDatosEjemplo()
                }
            }
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
                
                Circle()
                    .fill(Color.white.opacity(0.01))
                    .frame(width: 150, height: 150)
                    .position(x: geometry.size.width * 0.6, y: geometry.size.height * 0.1)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icono principal
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.9), Color.gray.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.black)
                )
                .shadow(color: .white.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 4) {
                Text("Editar Cuenta")
                    .font(.title.weight(.semibold))
                    .foregroundColor(.white)
                
                Text("Modifica los detalles de tu cuenta")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var formularioSection: some View {
        VStack(spacing: 20) {
            // Información Básica
            glassSection(title: "Información Básica") {
                VStack(spacing: 16) {
                    glassTextField("Monto", value: $monto)
                    glassTextField("Proveedor", text: $proveedor)
                    glassTextField("Nombre (opcional)", text: $nombre)
                    
                    glassPicker("Categoría", selection: $categoria, options: viewModel.categoriasDisponibles)
                    
                    if categoria == "Otra" {
                        glassTextField("Especificar categoría", text: $categoria)
                    }
                }
            }
            
            // Fechas
            glassSection(title: "Fechas") {
                VStack(spacing: 16) {
                    glassDatePicker("Fecha de Vencimiento", selection: $fechaVencimiento)
                    
                    glassToggle("Incluir fecha de emisión", isOn: $usarFechaEmision)
                    
                    if usarFechaEmision {
                        glassDatePicker("Fecha de Emisión", selection: Binding(
                            get: { fechaEmision ?? Date() },
                            set: { fechaEmision = $0 }
                        ))
                    }
                }
            }
            
            // Detalles
            glassSection(title: "Detalles") {
                glassTextEditor("Descripción", text: $descripcion)
            }
            
            // Información adicional de la cuenta
            glassSection(title: "Información de la Cuenta") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Estado actual:")
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(cuenta.estado.rawValue.capitalized)
                            .foregroundColor(cuenta.estado == .pagada ? .green : cuenta.estado == .pendiente ? .orange : .red)
                            .fontWeight(.medium)
                    }
                    
                    if let fechaPago = cuenta.fechaPago {
                        HStack {
                            Text("Último pago:")
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text(fechaPago.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    HStack {
                        Text("Creado por:")
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(cuenta.creador)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Componentes de Glass (reutilizados)
    private func glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            VStack(spacing: 16) {
                content()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func glassTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(GlassTextFieldStyle())
    }
    
    private func glassTextField(_ placeholder: String, value: Binding<Double>) -> some View {
        TextField(placeholder, value: value, format: .number)
            .textFieldStyle(GlassTextFieldStyle())
    }
    
    private func glassTextEditor(_ placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .frame(height: 80)
            
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: text)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
    }
    
    private func glassPicker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.7))
            
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
                Text("Otra").tag("Otra")
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
        }
    }
    
    private func glassDatePicker(_ title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.white.opacity(0.7))
            
            DatePicker("", selection: selection, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
        }
    }
    
    private func glassToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .white.opacity(0.8)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Estilos Personalizados
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

struct GlassButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color.gray.opacity(0.3) : Color.white.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(isDisabled ? .white.opacity(0.5) : .black)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Componentes Auxiliares para Organización Temporal

struct AñoHeaderView: View {
    let añoCuentas: AñoCuentas
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(añoCuentas.año)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(añoCuentas.totalCuentas) cuentas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(añoCuentas.totalMonto, specifier: "%.0f")")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text("\(añoCuentas.cuentasPagadas) pagadas")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("\(añoCuentas.cuentasPendientes) pendientes")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MesSeccionView: View {
    let mesCuentas: MesCuentas
    @Binding var cuentaSeleccionada: Cuenta?
    @State private var expandido = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header del mes
            mesHeader
            
            // Lista de cuentas del mes (expandible)
            if expandido {
                LazyVStack(spacing: 6) {
                    ForEach(mesCuentas.cuentas) { cuenta in
                        CuentaCompactaView(cuenta: cuenta) {
                            cuentaSeleccionada = cuenta
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var mesHeader: some View {
        Button(action: {
            withAnimation(.spring()) {
                expandido.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: expandido ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(mesCuentas.nombreMes)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(mesCuentas.totalMonto, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 4) {
                        Text("\(mesCuentas.cuentasPagadas)")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Text("/")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(mesCuentas.totalCuentas)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CuentaCronologicaView: View {
    let cuenta: Cuenta
    
    var body: some View {
        HStack(spacing: 12) {
            // Fecha
            VStack(alignment: .center, spacing: 2) {
                Text(cuenta.fechaVencimiento, style: .date)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(cuenta.fechaVencimiento, format: .dateTime.day())
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .frame(width: 50)
            
            // Información de la cuenta
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(cuenta.proveedor)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f", cuenta.monto))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text(cuenta.categoria)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Estado badge
                    Text(cuenta.estado == .pagada ? "PAGADA" : cuenta.estado == .pendiente ? "PENDIENTE" : "VENCIDA")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(cuenta.estado == .pagada ? Color.green : cuenta.estado == .pendiente ? Color.orange : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            // Indicador de tiempo
            VStack {
                let diasRestantes = Calendar.current.dateComponents([.day], from: Date(), to: cuenta.fechaVencimiento).day ?? 0
                
                if diasRestantes < 0 {
                    Text("Vencida")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else if diasRestantes == 0 {
                    Text("Hoy")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if diasRestantes <= 7 {
                    Text("\(diasRestantes)d")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else {
                    Text("\(diasRestantes)d")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct NuevaCuentaView: View {
    @ObservedObject var viewModel: CuentasViewModel
    @Binding var mostrarFormulario: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var monto: String = ""
    @State private var proveedor: String = ""
    @State private var fechaVencimiento: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var fechaEmision: Date = Date()
    @State private var usarFechaEmision: Bool = false
    @State private var categoria: String = "Luz"
    @State private var categoriaPersonalizada: String = ""
    @State private var descripcion: String = ""
    @State private var nombre: String = ""
    @State private var mostrandoError: Bool = false
    @State private var mensajeError: String = ""
    @State private var creandoCuenta: Bool = false
    
    private var categoriasDisponibles: [String] {
        return Cuenta.CategoriasCuentas.allCases.map { $0.rawValue }
    }
    
    private var categoriaFinal: String {
        if categoria == "Otros" && !categoriaPersonalizada.isEmpty {
            return categoriaPersonalizada
        }
        return categoria
    }
    
    private var esFormularioValido: Bool {
        !proveedor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !monto.isEmpty &&
        Double(monto) != nil &&
        Double(monto)! > 0 &&
        !categoriaFinal.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente
                backgroundView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Formulario principal
                        formularioSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        cerrarModal()
                    }
                    .foregroundColor(.white)
                    .disabled(creandoCuenta)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    HStack {
                        if creandoCuenta {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        
                        Button(creandoCuenta ? "Creando..." : "Crear Cuenta") {
                            crearCuenta()
                        }
                        .disabled(!esFormularioValido || creandoCuenta)
                        .foregroundColor(esFormularioValido && !creandoCuenta ? .white : .gray)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .alert("Error", isPresented: $mostrandoError) {
            Button("OK") { }
        } message: {
            Text(mensajeError)
        }
    }
    
    // MARK: - Fondo
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.8),
                Color.purple.opacity(0.6),
                Color.black.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icono
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("Nueva Cuenta")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                
                Text("Agrega una nueva cuenta a tu gestión")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Formulario
    private var formularioSection: some View {
        VStack(spacing: 20) {
            // Información básica
            seccionFormulario(titulo: "Información Básica", icono: "info.circle") {
                VStack(spacing: 16) {
                    campoTexto("Proveedor", texto: $proveedor, placeholder: "Ej: CFE, Totalplay, etc.")
                    campoTexto("Nombre (opcional)", texto: $nombre, placeholder: "Nombre descriptivo")
                    campoMonto("Monto", valor: $monto)
                }
            }
            
            // Categoría
            seccionFormulario(titulo: "Categoría", icono: "tag") {
                VStack(spacing: 12) {
                    selectorCategoria
                    
                    if categoria == "Otros" {
                        campoTexto("Especificar categoría", texto: $categoriaPersonalizada, placeholder: "Ingresa la categoría")
                    }
                }
            }
            
            // Fechas
            seccionFormulario(titulo: "Fechas", icono: "calendar") {
                VStack(spacing: 16) {
                    selectorFecha("Fecha de Vencimiento", fecha: $fechaVencimiento)
                    
                    Toggle("Incluir fecha de emisión", isOn: $usarFechaEmision)
                        .foregroundColor(.white)
                    
                    if usarFechaEmision {
                        selectorFecha("Fecha de Emisión", fecha: $fechaEmision)
                    }
                }
            }
            
            // Descripción
            seccionFormulario(titulo: "Descripción", icono: "text.alignleft") {
                campoTextoMultilinea("Descripción (opcional)", texto: $descripcion)
            }
        }
    }
    
    // MARK: - Componentes del formulario
    private func seccionFormulario<Content: View>(titulo: String, icono: String, @ViewBuilder contenido: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icono)
                    .foregroundColor(.white.opacity(0.9))
                Text(titulo)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            VStack(spacing: 16) {
                contenido()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func campoTexto(_ titulo: String, texto: Binding<String>, placeholder: String = "") -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            TextField(placeholder, text: texto)
                .textFieldStyle(EstiloCampoGlass())
        }
    }
    
    private func campoMonto(_ titulo: String, valor: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            HStack {
                Text("$")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.headline)
                
                TextField("0.00", text: valor)
                    .onReceive(valor.wrappedValue.publisher.collect()) {
                        let filtered = String($0.filter { "0123456789.".contains($0) })
                        if filtered != valor.wrappedValue {
                            valor.wrappedValue = filtered
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
        }
    }
    
    private func campoTextoMultilinea(_ titulo: String, texto: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .frame(height: 80)
                
                if texto.wrappedValue.isEmpty {
                    Text("Descripción opcional...")
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: texto)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
    }
    
    private var selectorCategoria: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Seleccionar categoría")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            Menu {
                ForEach(categoriasDisponibles, id: \.self) { cat in
                    Button(cat) {
                        categoria = cat
                        if cat != "Otros" {
                            categoriaPersonalizada = ""
                        }
                    }
                }
            } label: {
                HStack {
                    if let categoriaEnum = Cuenta.CategoriasCuentas(rawValue: categoria) {
                        Image(systemName: categoriaEnum.icono)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(categoria)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private func selectorFecha(_ titulo: String, fecha: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            DatePicker("", selection: fecha, displayedComponents: .date)
                .datePickerStyle(.compact)
                .colorScheme(.dark)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Lógica de creación
    private func crearCuenta() {
        creandoCuenta = true
        
        guard let montoDouble = Double(monto), montoDouble > 0 else {
            mostrarError("El monto debe ser un número válido mayor a 0")
            creandoCuenta = false
            return
        }
        
        let proveedorLimpio = proveedor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !proveedorLimpio.isEmpty else {
            mostrarError("El proveedor es obligatorio")
            creandoCuenta = false
            return
        }
        
        guard !categoriaFinal.isEmpty else {
            mostrarError("La categoría es obligatoria")
            creandoCuenta = false
            return
        }
        
        let nuevaCuenta = Cuenta(
            monto: montoDouble,
            proveedor: proveedorLimpio,
            fechaVencimiento: fechaVencimiento,
            categoria: categoriaFinal,
            creador: "Usuario",
            fechaEmision: usarFechaEmision ? fechaEmision : nil,
            descripcion: descripcion.trimmingCharacters(in: .whitespacesAndNewlines),
            nombre: nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        viewModel.agregarCuenta(nuevaCuenta)
        creandoCuenta = false
        cerrarModal()
    }
    
    private func cerrarModal() {
        // Limpiar el formulario al cerrar
        limpiarFormulario()
        mostrarFormulario = false
        dismiss()
    }
    
    private func limpiarFormulario() {
        monto = ""
        proveedor = ""
        fechaVencimiento = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        fechaEmision = Date()
        usarFechaEmision = false
        categoria = "Luz"
        categoriaPersonalizada = ""
        descripcion = ""
        nombre = ""
        creandoCuenta = false
    }
    
    private func mostrarError(_ mensaje: String) {
        mensajeError = mensaje
        mostrandoError = true
    }
}

// MARK: - Estilo personalizado para campos de texto
struct EstiloCampoGlass: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
    }
}

// Fin del archivo. No agregar structs ni declaraciones después de esta línea.