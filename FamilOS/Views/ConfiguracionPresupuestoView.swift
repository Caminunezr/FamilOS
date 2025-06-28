import SwiftUI

struct ConfiguracionPresupuestoView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var editandoCategoria: String? = nil
    @State private var nuevoMonto: String = ""
    @State private var mostrarSugerencias = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Categorías existentes
                    categoriasExistentesSection
                    
                    // Categorías sin presupuesto
                    categoriasSinPresupuestoSection
                    
                    // Sugerencias automáticas
                    if mostrarSugerencias {
                        sugerenciasSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Configurar Presupuestos")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        guardarCambios()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            cargarDatos()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gestión de Presupuestos")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    
                    Text("Define límites de gasto por categoría")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { mostrarSugerencias.toggle() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        Text("Sugerencias")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // Resumen total
            let totalPresupuesto = viewModel.presupuestosPorCategoria.values.reduce(0, +)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Presupuesto Total")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("$\(String(format: "%.0f", totalPresupuesto))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Categorías")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.presupuestosPorCategoria.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Categorías Existentes
    private var categoriasExistentesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Presupuestos Configurados")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.presupuestosPorCategoria.keys.sorted()), id: \.self) { categoria in
                    CategoriaPresupuestoRow(
                        categoria: categoria,
                        monto: viewModel.presupuestosPorCategoria[categoria] ?? 0,
                        editando: editandoCategoria == categoria,
                        onEdit: { iniciarEdicion(categoria) },
                        onSave: { nuevoMonto in
                            guardarCambioCategoria(categoria, monto: nuevoMonto)
                        },
                        onCancel: { cancelarEdicion() },
                        onDelete: { eliminarCategoria(categoria) }
                    )
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Categorías Sin Presupuesto
    @ViewBuilder
    private var categoriasSinPresupuestoSection: some View {
        let categoriasSinPresupuesto = viewModel.categoriasConGastosSinPresupuesto()
        
        if !categoriasSinPresupuesto.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Categorías sin Presupuesto")
                        .font(.headline)
                        .foregroundColor(primaryTextColor)
                    Spacer()
                }
                
                LazyVStack(spacing: 8) {
                    ForEach(categoriasSinPresupuesto, id: \.self) { categoria in
                        CategoriaSinPresupuestoRow(
                            categoria: categoria,
                            sugerencia: viewModel.sugerirPresupuestoParaCategoria(categoria),
                            onAdd: { monto in
                                viewModel.actualizarPresupuestoCategoria(categoria, monto: monto)
                            }
                        )
                    }
                }
                
                Text("Estas categorías tienen gastos registrados pero no tienen presupuesto asignado.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
            .background(cardBackground)
            .cornerRadius(16)
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Sugerencias
    private var sugerenciasSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Sugerencias Inteligentes")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                SugerenciaCard(
                    titulo: "Regla 50/30/20",
                    descripcion: "50% necesidades, 30% gustos, 20% ahorros",
                    icono: "chart.pie.fill",
                    color: .blue,
                    accion: aplicarRegla502030
                )
                
                SugerenciaCard(
                    titulo: "Basado en Historial",
                    descripcion: "Ajustar según gastos de meses anteriores",
                    icono: "chart.line.uptrend.xyaxis",
                    color: .green,
                    accion: aplicarSugerenciasHistorial
                )
                
                SugerenciaCard(
                    titulo: "Presupuesto Conservador",
                    descripcion: "Reducir 10% para mayor margen de seguridad",
                    icono: "shield.fill",
                    color: .orange,
                    accion: aplicarPresupuestoConservador
                )
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Métodos
    private func cargarDatos() {
        // Los datos ya están cargados en el viewModel
    }
    
    private func iniciarEdicion(_ categoria: String) {
        editandoCategoria = categoria
        nuevoMonto = String(format: "%.0f", viewModel.presupuestosPorCategoria[categoria] ?? 0)
    }
    
    private func cancelarEdicion() {
        editandoCategoria = nil
        nuevoMonto = ""
    }
    
    private func guardarCambioCategoria(_ categoria: String, monto: Double) {
        viewModel.actualizarPresupuestoCategoria(categoria, monto: monto)
        editandoCategoria = nil
        nuevoMonto = ""
    }
    
    private func eliminarCategoria(_ categoria: String) {
        viewModel.presupuestosPorCategoria.removeValue(forKey: categoria)
    }
    
    private func guardarCambios() {
        // Los cambios se guardan automáticamente en el viewModel
    }
    
    // MARK: - Sugerencias
    private func aplicarRegla502030() {
        // Implementar lógica de la regla 50/30/20
        let totalIngresos = viewModel.totalAportes
        let necesidades = totalIngresos * 0.5
        let gustos = totalIngresos * 0.3
        // Los ahorros serían el 20% restante
        
        // Distribuir entre categorías básicas
        viewModel.actualizarPresupuestoCategoria("Arriendo", monto: necesidades * 0.6)
        viewModel.actualizarPresupuestoCategoria("Alimentación", monto: necesidades * 0.2)
        viewModel.actualizarPresupuestoCategoria("Luz", monto: necesidades * 0.05)
        viewModel.actualizarPresupuestoCategoria("Agua", monto: necesidades * 0.03)
        viewModel.actualizarPresupuestoCategoria("Gas", monto: necesidades * 0.02)
        viewModel.actualizarPresupuestoCategoria("Internet", monto: necesidades * 0.03)
        viewModel.actualizarPresupuestoCategoria("Transporte", monto: necesidades * 0.07)
        
        viewModel.actualizarPresupuestoCategoria("Entretenimiento", monto: gustos * 0.7)
        viewModel.actualizarPresupuestoCategoria("Otros", monto: gustos * 0.3)
    }
    
    private func aplicarSugerenciasHistorial() {
        for categoria in viewModel.presupuestosPorCategoria.keys {
            let sugerencia = viewModel.sugerirPresupuestoParaCategoria(categoria)
            if sugerencia > 0 {
                viewModel.actualizarPresupuestoCategoria(categoria, monto: sugerencia)
            }
        }
    }
    
    private func aplicarPresupuestoConservador() {
        for (categoria, monto) in viewModel.presupuestosPorCategoria {
            viewModel.actualizarPresupuestoCategoria(categoria, monto: monto * 0.9)
        }
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

struct CategoriaPresupuestoRow: View {
    let categoria: String
    let monto: Double
    let editando: Bool
    let onEdit: () -> Void
    let onSave: (Double) -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @State private var montoTexto: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono de categoría
            Image(systemName: iconoCategoria(categoria))
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(categoria)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                if !editando {
                    Text("$\(String(format: "%.0f", monto))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if editando {
                HStack(spacing: 8) {
                    TextField("0", text: $montoTexto)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    
                    Button("✓") {
                        if let nuevoMonto = Double(montoTexto) {
                            onSave(nuevoMonto)
                        }
                    }
                    .foregroundColor(.green)
                    
                    Button("✕") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                }
            } else {
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .onAppear {
            montoTexto = String(format: "%.0f", monto)
        }
    }
    
    private func iconoCategoria(_ categoria: String) -> String {
        switch categoria {
        case "Luz": return "lightbulb.fill"
        case "Agua": return "drop.fill"
        case "Gas": return "flame.fill"
        case "Internet": return "wifi"
        case "Arriendo": return "house.fill"
        case "Alimentación": return "fork.knife"
        case "Transporte": return "car.fill"
        case "Salud": return "cross.case.fill"
        case "Entretenimiento": return "tv.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

struct CategoriaSinPresupuestoRow: View {
    let categoria: String
    let sugerencia: Double
    let onAdd: (Double) -> Void
    
    @State private var montoTexto: String = ""
    @State private var mostrarFormulario = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(categoria)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                if sugerencia > 0 {
                    Text("Sugerencia: $\(String(format: "%.0f", sugerencia))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if mostrarFormulario {
                HStack(spacing: 8) {
                    TextField("0", text: $montoTexto)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    
                    Button("✓") {
                        if let monto = Double(montoTexto) {
                            onAdd(monto)
                            mostrarFormulario = false
                        }
                    }
                    .foregroundColor(.green)
                    
                    Button("✕") {
                        mostrarFormulario = false
                    }
                    .foregroundColor(.red)
                }
            } else {
                HStack(spacing: 8) {
                    if sugerencia > 0 {
                        Button("Usar Sugerencia") {
                            onAdd(sugerencia)
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                    }
                    
                    Button("Personalizar") {
                        mostrarFormulario = true
                        montoTexto = sugerencia > 0 ? String(format: "%.0f", sugerencia) : ""
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SugerenciaCard: View {
    let titulo: String
    let descripcion: String
    let icono: String
    let color: Color
    let accion: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: accion) {
            HStack(spacing: 12) {
                Image(systemName: icono)
                    .foregroundColor(color)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text(descripcion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ConfiguracionPresupuestoView(viewModel: PresupuestoViewModel())
}
