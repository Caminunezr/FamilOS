import SwiftUI
import Combine

struct CuentasView: View {
    @EnvironmentObject var viewModel: CuentasViewModel
    @EnvironmentObject var presupuestoViewModel: PresupuestoViewModel
    @State private var mostrarFormularioNuevaCuenta = false
    @State private var cuentaSeleccionada: Cuenta? = nil
    @State private var mostrarFiltrosAvanzados = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar con dashboard y navegación
            dashboardSidebar
        } detail: {
            if let cuenta = cuentaSeleccionada {
                CuentaDetalleView(cuenta: cuenta, viewModel: viewModel, presupuestoViewModel: presupuestoViewModel, cuentaSeleccionada: $cuentaSeleccionada)
            } else {
                dashboardPrincipal
            }
        }
        .sheet(isPresented: $mostrarFormularioNuevaCuenta) {
            NuevaCuentaView(viewModel: viewModel, mostrarFormulario: $mostrarFormularioNuevaCuenta)
        }
    }
    
    // MARK: - Dashboard Sidebar
    private var dashboardSidebar: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Navegación principal - Dashboard Home
                navegacionDashboard
                
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
    
    // MARK: - Navegación Dashboard
    private var navegacionDashboard: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cuentaSeleccionada = nil
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: cuentaSeleccionada == nil ? "house.fill" : "house")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Dashboard")
                            .font(.subheadline.weight(.medium))
                        
                        if cuentaSeleccionada != nil {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(cuentaSeleccionada == nil ? .blue : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(cuentaSeleccionada == nil ? Color.blue.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if let cuenta = cuentaSeleccionada {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(cuenta.nombre.isEmpty ? cuenta.proveedor : cuenta.nombre)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        
                        Text("$\(cuenta.monto, specifier: "%.0f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if cuentaSeleccionada != nil {
                Divider()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
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
                
                // Botón para ir al mes actual
                Button(action: {
                    // Scroll automático al mes actual si es necesario
                    print("Navegando al mes actual")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.circle")
                            .foregroundColor(.blue)
                        Text("Mes Actual")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
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
        let resumen = viewModel.resumenGeneral // ✅ Cambiar a estadísticas generales
        
        return VStack(spacing: 12) {
            Text("Resumen General") // ✅ Cambiar título
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
                // Header de navegación mejorado
                dashboardHeader
                
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if cuentaSeleccionada != nil {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cuentaSeleccionada = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Volver")
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Dashboard Header
    private var dashboardHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estadísticas Financieras")
                        .font(.title.weight(.bold))
                    
                    Text("Resumen de tu gestión mensual")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Botón de navegación a las cuentas
                Button(action: {
                    // No hacemos nada aquí, solo visual
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Ver Cuentas")
                            .font(.subheadline.weight(.medium))
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Indicador de mes actual
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                
                Text("Datos del mes actual: \(Date().formatted(.dateTime.month(.wide).year()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Actualizado ahora")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
        }
    }
    
    // MARK: - Estadísticas Generales
    private var estadisticasGenerales: some View {
        let resumen = viewModel.resumenGeneral // ✅ Cambiar a estadísticas generales
        
        return VStack(spacing: 16) {
            Text("Estadísticas Generales")  // ✅ Cambiar título
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
                    valor: "\(viewModel.cuentas.count)", // ✅ Usar todas las cuentas
                    icono: "doc.text",
                    color: .blue
                )
                
                EstadisticaCard(
                    titulo: "Promedio",
                    valor: String(format: "%.0f", resumen.totalMonto / Double(max(1, viewModel.cuentas.count))), // ✅ Usar todas las cuentas
                    icono: "chart.bar",
                    color: .purple
                )
                
                EstadisticaCard(
                    titulo: "Pendiente",
                    valor: String(format: "%.0f", resumen.montoPendiente), // ✅ Mostrar monto pendiente
                    icono: "clock",
                    color: .orange
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
                let resumen = viewModel.resumenGeneral // ✅ Cambiar a estadísticas generales
                
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
        let analisisCategoria = viewModel.analisisPorCategoriaGeneral // ✅ Usar análisis general
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Gastos por Categoría (Todas las Cuentas)") // ✅ Aclarar que son todas las cuentas
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
        let topProveedores = viewModel.topProveedoresGeneral // ✅ Usar análisis general
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Top Proveedores (Todas las Cuentas)") // ✅ Aclarar que son todas las cuentas
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
    @ObservedObject var presupuestoViewModel: PresupuestoViewModel
    @Binding var cuentaSeleccionada: Cuenta?
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
            ModalRegistrarPagoAvanzado(cuenta: cuenta, cuentasViewModel: viewModel, presupuestoViewModel: presupuestoViewModel)
        }
        .sheet(isPresented: $mostrarVisorArchivos) {
            VisorArchivosView(cuenta: cuenta)
        }
        .sheet(isPresented: $mostrarEdicion) {
            EditarCuentaView(cuenta: cuenta, viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cuentaSeleccionada = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("Dashboard")
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
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
    @Environment(\.colorScheme) var colorScheme
    
    @State private var montoPago: Double = 0
    @State private var fechaPago: Date = Date()
    @State private var notas: String = ""
    @State private var tieneComprobante: Bool = false
    @State private var registrandoPago: Bool = false
    @State private var mostrandoError: Bool = false
    @State private var mensajeError: String = ""
    
    private var esFormularioValido: Bool {
        montoPago > 0
    }
    
    var body: some View {
        ZStack {
            // Fondo adaptativo
            backgroundView
            
            NavigationStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Formulario principal
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
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .disabled(registrandoPago)
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        HStack {
                            if registrandoPago {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .white : .blue))
                            }
                            
                            Button(registrandoPago ? "Registrando..." : "Registrar Pago") {
                                registrarPago()
                            }
                            .disabled(!esFormularioValido || registrandoPago)
                            .foregroundColor(esFormularioValido && !registrandoPago ? 
                                           (colorScheme == .dark ? .white : .blue) : .gray)
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .onAppear {
            montoPago = cuenta.monto
        }
        .alert("Error", isPresented: $mostrandoError) {
            Button("OK") { }
        } message: {
            Text(mensajeError)
        }
    }
    
    // MARK: - Fondo adaptativo
    private var backgroundView: some View {
        Group {
            if colorScheme == .dark {
                // Fondo oscuro con gradiente
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
                // Fondo claro con gradiente suave
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
        VStack(spacing: 16) {
            // Icono principal
            Circle()
                .fill(glassMaterial)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white : .blue)
                )
                .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("Registrar Pago")
                    .font(.title.weight(.bold))
                    .foregroundColor(primaryTextColor)
                
                Text("Confirma el pago de tu cuenta")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Formulario
    private var formularioSection: some View {
        VStack(spacing: 20) {
            // Información de la cuenta
            glassSection(title: "Información de la Cuenta", icon: "doc.text") {
                VStack(spacing: 16) {
                    infoRow("Proveedor", value: cuenta.proveedor)
                    infoRow("Cuenta", value: cuenta.nombre.isEmpty ? "Sin nombre" : cuenta.nombre)
                    infoRow("Categoría", value: cuenta.categoria)
                    infoRow("Monto Original", value: String(format: "$%.0f", cuenta.monto))
                }
            }
            
            // Detalles del pago
            glassSection(title: "Detalles del Pago", icon: "creditcard") {
                VStack(spacing: 16) {
                    glassNumberField("Monto a Pagar", value: $montoPago)
                    glassDatePicker("Fecha de Pago", selection: $fechaPago)
                    glassTextEditor("Notas (opcional)", text: $notas)
                    glassToggle("Tengo comprobante", isOn: $tieneComprobante)
                }
            }
            
            // Cálculo de diferencia
            if montoPago != cuenta.monto && montoPago > 0 {
                glassSection(title: "Resumen", icon: "calculator") {
                    VStack(spacing: 12) {
                        let diferencia = abs(cuenta.monto - montoPago)
                        let esSobrepago = montoPago > cuenta.monto
                        
                        HStack {
                            Text("Diferencia:")
                                .foregroundColor(secondaryTextColor)
                            Spacer()
                            Text(String(format: "$%.0f", diferencia))
                                .foregroundColor(esSobrepago ? .green : .orange)
                                .fontWeight(.semibold)
                        }
                        
                        HStack {
                            Text("Tipo:")
                                .foregroundColor(secondaryTextColor)
                            Spacer()
                            Text(esSobrepago ? "Sobrepago" : "Pago parcial")
                                .foregroundColor(esSobrepago ? .green : .orange)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Componentes Glass
    private func glassSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .blue)
                Text(title)
                    .font(.headline.weight(.medium))
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            VStack(spacing: 16) {
                content()
            }
            .padding(20)
            .background(glassMaterial)
            .cornerRadius(16)
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        }
    }
    
    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(secondaryTextColor)
            Spacer()
            Text(value)
                .foregroundColor(primaryTextColor)
                .fontWeight(.medium)
        }
    }
    
    private func glassNumberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            HStack {
                Text("$")
                    .foregroundColor(secondaryTextColor)
                    .font(.headline)
                
                TextField("0.00", value: value, format: .number)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(fieldBackground)
            .cornerRadius(12)
        }
    }
    
    private func glassDatePicker(_ title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            DatePicker("", selection: selection, displayedComponents: .date)
                .datePickerStyle(.compact)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(fieldBackground)
                .cornerRadius(12)
        }
    }
    
    private func glassTextEditor(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(fieldBackground)
                    .frame(height: 80)
                
                if text.wrappedValue.isEmpty {
                    Text("Agrega notas sobre este pago...")
                        .foregroundColor(secondaryTextColor.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
    }
    
    private func glassToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(primaryTextColor)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: colorScheme == .dark ? .white.opacity(0.8) : .blue))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(fieldBackground)
        .cornerRadius(12)
    }
    
    // MARK: - Lógica de pago
    private func registrarPago() {
        registrandoPago = true
        
        guard montoPago > 0 else {
            mostrarError("El monto debe ser mayor a 0")
            registrandoPago = false
            return
        }
        
        viewModel.registrarPago(
            cuenta: cuenta,
            monto: montoPago,
            fecha: fechaPago,
            notas: notas,
            tieneComprobante: tieneComprobante
        )
        
        registrandoPago = false
        dismiss()
    }
    
    private func mostrarError(_ mensaje: String) {
        mensajeError = mensaje
        mostrandoError = true
    }
    
    // MARK: - Estilos adaptivos
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
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.7) : .secondary
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1)
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
                .toolbar(content: {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Guardar") {
                            var cuentaActualizada = cuenta
                            cuentaActualizada.monto = monto
                            cuentaActualizada.proveedor = proveedor
                            cuentaActualizada.fechaVencimiento = fechaVencimiento
                            cuentaActualizada.categoria = categoria
                            cuentaActualizada.descripcion = descripcion
                            cuentaActualizada.nombre = nombre
                            cuentaActualizada.fechaEmision = usarFechaEmision ? fechaEmision : nil
                            
                            viewModel.actualizarCuenta(cuentaActualizada)
                            dismiss()
                        }
                        .disabled(proveedor.isEmpty || monto <= 0 || categoria.isEmpty)
                        .buttonStyle(GlassButtonStyle(isDisabled: proveedor.isEmpty || monto <= 0 || categoria.isEmpty))
                    }
                })
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
            // Header del mes con indicadores temporales
            mesHeaderMejorado
            
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
    
    private var mesHeaderMejorado: some View {
        Button(action: {
            withAnimation(.spring()) {
                expandido.toggle()
            }
        }) {
            HStack(spacing: 12) {
                // Indicador temporal
                indicadorTemporal
                
                Image(systemName: expandido ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mesCuentas.nombreMes)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(etiquetaTemporal)
                        .font(.caption2)
                        .foregroundColor(colorEtiquetaTemporal)
                }
                
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
            .padding(.vertical, 10)
            .background(colorFondoMes)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Indicadores temporales
    private var indicadorTemporal: some View {
        Circle()
            .fill(colorIndicadorTemporal)
            .frame(width: 8, height: 8)
    }
    
    private var etiquetaTemporal: String {
        let calendar = Calendar.current
        let ahora = Date()
        let mesActual = calendar.component(.month, from: ahora)
        let añoActual = calendar.component(.year, from: ahora)
        
        if mesCuentas.año == añoActual {
            if mesCuentas.mes == mesActual {
                return "Mes actual"
            } else if mesCuentas.mes == mesActual - 1 {
                return "Mes anterior"
            } else if mesCuentas.mes < mesActual {
                let diferencia = mesActual - mesCuentas.mes
                return "Hace \(diferencia) mes\(diferencia > 1 ? "es" : "")"
            } else {
                return "Próximo"
            }
        } else if mesCuentas.año == añoActual - 1 {
            return "Año anterior"
        } else {
            let diferencia = añoActual - mesCuentas.año
            return "Hace \(diferencia) año\(diferencia > 1 ? "s" : "")"
        }
    }
    
    private var colorEtiquetaTemporal: Color {
        let calendar = Calendar.current
        let ahora = Date()
        let mesActual = calendar.component(.month, from: ahora)
        let añoActual = calendar.component(.year, from: ahora)
        
        if mesCuentas.año == añoActual && mesCuentas.mes == mesActual {
            return .blue  // Mes actual
        } else if mesCuentas.año == añoActual && mesCuentas.mes == mesActual - 1 {
            return .orange  // Mes anterior
        } else {
            return .secondary  // Meses más antiguos
        }
    }
    
    private var colorIndicadorTemporal: Color {
        let calendar = Calendar.current
        let ahora = Date()
        let mesActual = calendar.component(.month, from: ahora)
        let añoActual = calendar.component(.year, from: ahora)
        
        if mesCuentas.año == añoActual && mesCuentas.mes == mesActual {
            return .blue  // Mes actual
        } else if mesCuentas.año == añoActual && mesCuentas.mes == mesActual - 1 {
            return .orange  // Mes anterior
        } else {
            return .gray  // Meses más antiguos
        }
    }
    
    private var colorFondoMes: Color {
        let calendar = Calendar.current
        let ahora = Date()
        let mesActual = calendar.component(.month, from: ahora)
        let añoActual = calendar.component(.year, from: ahora)
        
        if mesCuentas.año == añoActual && mesCuentas.mes == mesActual {
            return Color.blue.opacity(0.1)  // Mes actual destacado
        } else {
            return Color.gray.opacity(0.05)  // Fondo normal
        }
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
    @State private var fechaVencimiento: Date = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var fechaEmision: Date = Date()
    @State private var usarFechaEmision: Bool = false
    @State private var categoriaSeleccionada: CategoriaFinanciera = .luz
    @State private var proveedorSeleccionado: String = ""
    @State private var descripcion: String = ""
    @State private var nombre: String = ""
    @State private var mostrandoError: Bool = false
    @State private var mensajeError: String = ""
    @State private var creandoCuenta: Bool = false
    
    private var esFormularioValido: Bool {
        !proveedorSeleccionado.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !monto.isEmpty &&
        Double(monto) != nil &&
        Double(monto)! > 0
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
            // Categoría y Proveedor - Sección principal
            seccionFormulario(titulo: "Categoría y Proveedor", icono: "tag") {
                SelectorCategoriaProveedor(
                    categoriaSeleccionada: $categoriaSeleccionada,
                    proveedorSeleccionado: $proveedorSeleccionado
                )
            }
            
            // Información básica
            seccionFormulario(titulo: "Información Básica", icono: "info.circle") {
                VStack(spacing: 16) {
                    campoMonto("Monto", valor: $monto)
                    campoTexto("Nombre (opcional)", texto: $nombre, placeholder: "Nombre descriptivo - se genera automáticamente si está vacío")
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
        EmptyView()
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
        
        let proveedorLimpio = proveedorSeleccionado.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !proveedorLimpio.isEmpty else {
            mostrarError("El proveedor es obligatorio")
            creandoCuenta = false
            return
        }
        
        let nuevaCuenta = Cuenta(
            monto: montoDouble,
            proveedor: proveedorLimpio,
            fechaVencimiento: fechaVencimiento,
            categoria: categoriaSeleccionada.rawValue,
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
        fechaVencimiento = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        fechaEmision = Date()
        usarFechaEmision = false
        categoriaSeleccionada = .luz
        proveedorSeleccionado = ""
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