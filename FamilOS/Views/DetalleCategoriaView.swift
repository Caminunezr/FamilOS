import SwiftUI

struct DetalleCategoriaView: View {
    let categoria: CategoriaPresupuestoAnalisis
    let presupuestoVM: PresupuestoViewModel
    let cuentasVM: CuentasViewModel
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var cuentasCategoria: [Cuenta] = []
    @State private var mostrarHistorial = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header con información principal
                    headerSection
                    
                    // Resumen financiero de la categoría
                    resumenFinanciero
                    
                    // Gráfico de progreso
                    progresoSection
                    
                    // Cuentas de esta categoría
                    cuentasSection
                    
                    // Análisis histórico
                    if mostrarHistorial {
                        historialSection
                    }
                    
                    // Recomendaciones
                    recomendacionesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle(categoria.nombre)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(mostrarHistorial ? "Ocultar Historial" : "Ver Historial") {
                        withAnimation {
                            mostrarHistorial.toggle()
                        }
                    }
                }
            }
        }
        .onAppear {
            cargarCuentasCategoria()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                // Icono y nombre
                HStack(spacing: 12) {
                    Circle()
                        .fill(categoria.estado.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: categoria.icono)
                                .foregroundColor(categoria.estado.color)
                                .font(.title2)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(categoria.nombre)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)
                        
                        HStack(spacing: 8) {
                            Image(systemName: categoria.estado.icono)
                                .foregroundColor(categoria.estado.color)
                                .font(.caption)
                            
                            Text(categoria.estado.mensaje)
                                .font(.subheadline)
                                .foregroundColor(categoria.estado.color)
                        }
                    }
                }
                
                Spacer()
                
                // Porcentaje usado
                VStack(spacing: 4) {
                    Text("\(Int(categoria.porcentajeUsado * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(categoria.estado.color)
                    
                    Text("Usado")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Resumen Financiero
    private var resumenFinanciero: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Resumen Financiero")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            HStack(spacing: 16) {
                FinanceDetailCard(
                    titulo: "Presupuesto",
                    valor: categoria.presupuestoMensual,
                    icono: "target",
                    color: .blue
                )
                
                FinanceDetailCard(
                    titulo: "Gastado",
                    valor: categoria.gastoActual,
                    icono: "minus.circle.fill",
                    color: categoria.gastoActual <= categoria.presupuestoMensual ? .green : .red
                )
            }
            
            HStack(spacing: 16) {
                FinanceDetailCard(
                    titulo: "Pendiente",
                    valor: categoria.gastoProyectado,
                    icono: "clock.circle.fill",
                    color: .orange
                )
                
                FinanceDetailCard(
                    titulo: categoria.diferencia >= 0 ? "Disponible" : "Excedido",
                    valor: abs(categoria.diferencia),
                    icono: categoria.diferencia >= 0 ? "checkmark.circle.fill" : "xmark.circle.fill",
                    color: categoria.diferencia >= 0 ? .green : .red
                )
            }
            
            // Proyección
            if categoria.gastoProyectado > 0 {
                VStack(spacing: 8) {
                    HStack {
                        Text("Proyección de Fin de Mes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(primaryTextColor)
                        Spacer()
                        Text("$\(String(format: "%.0f", categoria.proyeccionFinal))")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(categoria.excedeProyeccion ? .red : .green)
                    }
                    
                    if categoria.excedeProyeccion {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text("La proyección excederá el presupuesto en $\(String(format: "%.0f", categoria.proyeccionFinal - categoria.presupuestoMensual))")
                                .font(.caption)
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(categoria.excedeProyeccion ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Progreso Section
    private var progresoSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Progreso del Presupuesto")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Barra de progreso principal
                VStack(spacing: 8) {
                    HStack {
                        Text("Gastado")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(String(format: "%.0f", categoria.gastoActual)) / $\(String(format: "%.0f", categoria.presupuestoMensual))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(primaryTextColor)
                    }
                    
                    ProgressView(value: min(categoria.porcentajeUsado, 1.0), total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(categoria.estado.color)
                        .scaleEffect(y: 3)
                }
                
                // Barra de proyección
                if categoria.gastoProyectado > 0 {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Proyección")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("$\(String(format: "%.0f", categoria.proyeccionFinal)) / $\(String(format: "%.0f", categoria.presupuestoMensual))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(primaryTextColor)
                        }
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(categoria.excedeProyeccion ? .red : .orange)
                                .frame(width: CGFloat(min(categoria.proyeccionFinal / categoria.presupuestoMensual, 1.0)) * 300, height: 8)
                                .cornerRadius(4)
                        }
                        .frame(maxWidth: 300)
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Cuentas Section
    private var cuentasSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cuentas de \(categoria.nombre)")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
                Text("\(cuentasCategoria.count) cuenta(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if cuentasCategoria.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No hay cuentas registradas")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Las cuentas de esta categoría aparecerán aquí")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(cuentasCategoria) { cuenta in
                        CuentaMiniCard(cuenta: cuenta)
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Historial Section
    private var historialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Análisis Histórico")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Tendencia de gastos (simulada)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mes Anterior")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.0f", categoria.gastoActual * 0.85))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.red)
                        Text("+15%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Mes Actual")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("$\(String(format: "%.0f", categoria.gastoActual))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                // Promedio de 3 meses
                HStack {
                    Text("Promedio 3 meses:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.0f", categoria.gastoActual * 0.93))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(primaryTextColor)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Recomendaciones Section
    private var recomendacionesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Recomendaciones")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(generarRecomendaciones(), id: \.self) { recomendacion in
                    RecomendacionCard(texto: recomendacion)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Métodos auxiliares
    private func cargarCuentasCategoria() {
        let calendario = Calendar.current
        cuentasCategoria = cuentasVM.cuentas.filter { cuenta in
            cuenta.categoria == categoria.nombre &&
            calendario.isDate(cuenta.fechaVencimiento, equalTo: presupuestoVM.mesSeleccionado, toGranularity: .month)
        }.sorted { $0.fechaVencimiento < $1.fechaVencimiento }
    }
    
    private func generarRecomendaciones() -> [String] {
        var recomendaciones: [String] = []
        
        switch categoria.estado {
        case .excedido:
            recomendaciones.append("Considera reducir gastos en esta categoría o aumentar el presupuesto.")
            recomendaciones.append("Revisa las cuentas más costosas para identificar posibles ahorros.")
            
        case .cerca:
            if categoria.excedeProyeccion {
                recomendaciones.append("Las cuentas pendientes excederán el presupuesto. Considera posponer algunos gastos.")
            } else {
                recomendaciones.append("Estás cerca del límite. Monitorea los gastos restantes del mes.")
            }
            
        case .atencion:
            recomendaciones.append("Buen control del gasto, pero mantente atento a no exceder el límite.")
            
        case .enRango:
            recomendaciones.append("Excelente control del presupuesto en esta categoría.")
            if categoria.diferencia > categoria.presupuestoMensual * 0.3 {
                recomendaciones.append("Tienes margen para gastos adicionales si es necesario.")
            }
            
        case .sinPresupuesto:
            recomendaciones.append("Considera establecer un presupuesto para esta categoría.")
        }
        
        // Recomendaciones basadas en el historial (simuladas)
        if categoria.gastoActual > categoria.presupuestoMensual * 0.5 {
            recomendaciones.append("Este mes has gastado más que el promedio histórico.")
        }
        
        return recomendaciones
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

// MARK: - Componentes auxiliares

struct FinanceDetailCard: View {
    let titulo: String
    let valor: Double
    let icono: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icono)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(spacing: 2) {
                Text(titulo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("$\(String(format: "%.0f", valor))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

struct CuentaMiniCard: View {
    let cuenta: Cuenta
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Indicador de estado
            Circle()
                .fill(estadoColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cuenta.nombre.isEmpty ? cuenta.proveedor : cuenta.nombre)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(cuenta.proveedor)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.0f", cuenta.monto))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(fechaFormateada)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var estadoColor: Color {
        switch cuenta.estado {
        case .pagada: return .green
        case .pendiente: return .orange
        case .vencida: return .red
        }
    }
    
    private var fechaFormateada: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: cuenta.fechaVencimiento)
    }
}

struct RecomendacionCard: View {
    let texto: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.caption)
            
            Text(texto)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DetalleCategoriaView(
        categoria: CategoriaPresupuestoAnalisis(
            nombre: "Luz",
            icono: "lightbulb.fill",
            presupuestoMensual: 50000,
            gastoActual: 35000,
            gastoProyectado: 15000,
            porcentajeUsado: 0.7,
            estado: .atencion,
            cuentasPendientes: 2,
            cuentasPagadas: 3
        ),
        presupuestoVM: PresupuestoViewModel(),
        cuentasVM: CuentasViewModel()
    )
}
