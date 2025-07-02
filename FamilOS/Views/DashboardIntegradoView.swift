import SwiftUI

struct DashboardIntegradoView: View {
    @EnvironmentObject var cuentasViewModel: CuentasViewModel
    @EnvironmentObject var presupuestoViewModel: PresupuestoViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var resumenActual: ResumenFinancieroIntegrado?
    @State private var mostrarConfiguracion = false
    @State private var mostrarConfiguracionCategorias = false
    @State private var mostrarTestModal = false
    // @State private var categoriaSeleccionada: CategoriaFinanciera?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con resumen general
                    headerSection
                    
                    // Alertas importantes
                    if let resumen = resumenActual, !resumen.alertas.isEmpty {
                        alertasSection(resumen.alertas)
                    }
                    
                    // Resumen financiero principal
                    if let resumen = resumenActual {
                        resumenPrincipal(resumen)
                    }
                    
                    // Análisis por categorías
                    if let resumen = resumenActual {
                        categoriasSection(resumen.categorias)
                    }
                    
                    // Gráficos y análisis adicional
                    if let resumen = resumenActual {
                        graficosSection(resumen)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Dashboard Financiero")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { mostrarConfiguracion = true }) {
                            Label("Configurar Presupuesto", systemImage: "chart.pie")
                        }
                        
                        Button(action: { mostrarConfiguracionCategorias = true }) {
                            Label("Gestionar Categorías", systemImage: "folder.badge.gearshape")
                        }
                        
                        Button(action: { mostrarTestModal = true }) {
                            Label("Probar Modal Pago (DEBUG)", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            // Actualizar resumen
            resumenActual = presupuestoViewModel.resumenFinancieroIntegrado()
        }
        .sheet(isPresented: $mostrarConfiguracion) {
            ConfiguracionPresupuestoView(viewModel: presupuestoViewModel)
        }
        .sheet(isPresented: $mostrarConfiguracionCategorias) {
            ConfiguracionCategoriasView()
        }
        .sheet(isPresented: $mostrarTestModal) {
            ModalRegistrarPagoAvanzado(
                cuenta: Cuenta(
                    monto: 1000.0,
                    proveedor: "Test Provider",
                    fechaVencimiento: Date(),
                    categoria: "Test",
                    creador: "Usuario Test"
                ),
                cuentasViewModel: cuentasViewModel,
                presupuestoViewModel: presupuestoViewModel
            )
        }
        /*
        .sheet(item: $categoriaSeleccionada) { categoria in
            DetalleCategoriaView(categoria: categoria, presupuestoVM: presupuestoViewModel, cuentasVM: cuentasViewModel)
        }
        */
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard Financiero")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    Text(fechaFormateada)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Indicador del estado general
                if let resumen = resumenActual {
                    estadoGeneralIndicador(resumen)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private func estadoGeneralIndicador(_ resumen: ResumenFinancieroIntegrado) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(estadoGeneralColor(resumen))
                .frame(width: 16, height: 16)
            
            Text(estadoGeneralTexto(resumen))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func estadoGeneralColor(_ resumen: ResumenFinancieroIntegrado) -> Color {
        if resumen.excedePresupuesto {
            return .red
        } else if resumen.proyeccionExcede {
            return .orange
        } else if resumen.porcentajeUsado > 0.8 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private func estadoGeneralTexto(_ resumen: ResumenFinancieroIntegrado) -> String {
        if resumen.excedePresupuesto {
            return "Excedido"
        } else if resumen.proyeccionExcede {
            return "Riesgo"
        } else if resumen.porcentajeUsado > 0.8 {
            return "Atención"
        } else {
            return "Saludable"
        }
    }
    
    // MARK: - Alertas Section
    private func alertasSection(_ alertas: [AlertaFinanciera]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Alertas Importantes")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(alertas.prefix(3)) { alerta in
                    AlertaCard(alerta: alerta)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Resumen Principal
    private func resumenPrincipal(_ resumen: ResumenFinancieroIntegrado) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Resumen del Mes")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            HStack(spacing: 16) {
                FinanceCard(
                    titulo: "Presupuesto",
                    valor: resumen.presupuestoTotal,
                    icono: "dollarsign.circle.fill",
                    color: .blue
                )
                
                FinanceCard(
                    titulo: "Gastado",
                    valor: resumen.gastoActual,
                    icono: "minus.circle.fill",
                    color: resumen.excedePresupuesto ? .red : .green
                )
                
                FinanceCard(
                    titulo: "Pendiente",
                    valor: resumen.gastoProyectado,
                    icono: "clock.circle.fill",
                    color: .orange
                )
                
                FinanceCard(
                    titulo: "Disponible",
                    valor: resumen.disponible,
                    icono: resumen.disponible >= 0 ? "checkmark.circle.fill" : "xmark.circle.fill",
                    color: resumen.disponible >= 0 ? .green : .red
                )
            }
            
            // Barra de progreso general
            VStack(spacing: 8) {
                HStack {
                    Text("Progreso del Presupuesto")
                        .font(.subheadline)
                        .foregroundColor(primaryTextColor)
                    Spacer()
                    Text("\(Int(resumen.porcentajeUsado * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)
                }
                
                ProgressView(value: resumen.porcentajeUsado, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(estadoGeneralColor(resumen))
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Categorías Section
    private func categoriasSection(_ categorias: [CategoriaPresupuestoAnalisis]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Análisis por Categoría")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
                Text("Toca para detalles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(categorias) { categoria in
                    CategoriaAnalisisCard(categoria: categoria)
                        .onTapGesture {
                            // categoriaSeleccionada = categoria
                        }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Gráficos Section
    private func graficosSection(_ resumen: ResumenFinancieroIntegrado) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Análisis Visual")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Gráfico de distribución por estado
                estadosDistribucionChart(resumen.categorias)
                
                // Gráfico de top categorías por gasto
                topCategoriasChart(resumen.categorias)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    private func estadosDistribucionChart(_ categorias: [CategoriaPresupuestoAnalisis]) -> some View {
        VStack(spacing: 8) {
            Text("Estados del Presupuesto")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(primaryTextColor)
            
            let estadosCount = Dictionary(grouping: categorias, by: { $0.estado })
                .mapValues { $0.count }
            
            VStack(spacing: 4) {
                ForEach(EstadoPresupuesto.allCases, id: \.self) { estado in
                    if let count = estadosCount[estado], count > 0 {
                        HStack {
                            Circle()
                                .fill(estado.color)
                                .frame(width: 8, height: 8)
                            Text(estado.mensaje)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(primaryTextColor)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
    
    private func topCategoriasChart(_ categorias: [CategoriaPresupuestoAnalisis]) -> some View {
        let topCategorias = getTopCategorias(categorias)
        
        return VStack(spacing: 8) {
            Text("Top Gastos")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(primaryTextColor)
            
            VStack(spacing: 4) {
                ForEach(Array(topCategorias.enumerated()), id: \.offset) { index, categoria in
                    topCategoriaRow(index: index, categoria: categoria)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
    
    private func getTopCategorias(_ categorias: [CategoriaPresupuestoAnalisis]) -> Array<CategoriaPresupuestoAnalisis>.SubSequence {
        return categorias
            .filter { $0.gastoActual > 0 }
            .sorted(by: { $0.gastoActual > $1.gastoActual })
            .prefix(5)
    }
    
    private func topCategoriaRow(index: Int, categoria: CategoriaPresupuestoAnalisis) -> some View {
        HStack {
            Text("\(index + 1)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Image(systemName: categoria.icon)
                .foregroundColor(CategoriaFinanciera(rawValue: categoria.nombre)?.colorPrimario ?? .blue)
                .frame(width: 16)
            
            Text(categoria.nombre)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            Spacer()
            
            Text("$\(Int(categoria.gastoActual))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(primaryTextColor)
        }
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Métodos auxiliares
    private func cargarDatos() {
        // Actualizar resumen
        resumenActual = presupuestoViewModel.resumenFinancieroIntegrado()
    }
    
    private var fechaFormateada: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: presupuestoViewModel.mesSeleccionado).capitalized
    }
    
    // MARK: - Estilos adaptativos
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }
    
    private var cardBackground: some ShapeStyle {
        if colorScheme == .dark {
            return AnyShapeStyle(.ultraThinMaterial.opacity(0.6))
        } else {
            return AnyShapeStyle(Color.white)
        }
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .white.opacity(0.1) : .black.opacity(0.1)
    }
}

// MARK: - Vista para análisis de categorías
struct CategoriaAnalisisCard: View {
    let categoria: CategoriaPresupuestoAnalisis
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: categoria.icon)
                    .foregroundColor(categoria.estado.color)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoria.nombre)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .lineLimit(1)
                    
                    Text("\(Int(categoria.porcentajeUsado * 100))% usado")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: categoria.estado.icono)
                    .foregroundColor(categoria.estado.color)
                    .font(.caption)
            }
            
            // Barra de progreso
            ProgressView(value: min(categoria.porcentajeUsado, 1.0), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(categoria.estado.color)
                .scaleEffect(y: 1.5)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gastado")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(Int(categoria.gastoActual))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Presupuesto")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(Int(categoria.presupuestoMensual))")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white)
                .stroke(categoria.estado.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Componentes auxiliares

struct FinanceCard: View {
    let titulo: String
    let valor: Double
    let icono: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icono)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("$\(Int(valor))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

struct CategoriaCard: View {
    let categoria: CategoriaFinanciera
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            headerSection
            proveedoresSection
            if categoria.proveedoresComunes.count > 5 {
                proyeccionSection
            }
        }
        .padding()
        .background(categoria.colorPrimario.opacity(0.1))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: categoria.icono)
                .foregroundColor(categoria.colorPrimario)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(categoria.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)
                
                Text(categoria.descripcion)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
    
    private var proveedoresSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Proveedores")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(categoria.proveedoresComunes.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Configurado")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("✓")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
        }
    }
    
    private var proyeccionSection: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.orange)
                .font(.caption2)
            Text("Muchos proveedores disponibles")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

struct AlertaCard: View {
    let alerta: AlertaFinanciera
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(alerta.urgencia.color)
                .frame(width: 8, height: 8)
            
            Text(alerta.mensaje)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(alerta.urgencia.color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    DashboardIntegradoView()
}
