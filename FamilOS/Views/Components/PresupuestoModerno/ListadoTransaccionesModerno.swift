import SwiftUI
import Foundation

// Definir localmente para evitar ambigüedad
enum TransaccionType: String, Codable {
    case aporte = "aporte"
    case gasto = "gasto"
    case ahorro = "ahorro"
    case deuda = "deuda"
    case pago = "pago"
}

struct ListadoTransaccionesModerno: View {
    let aportes: [AporteItem]
    let gastos: [GastoItem]
    let ahorros: [AhorroItem]
    let deudas: [DeudaItem]
    let onEliminar: (String, TipoTransaccion) -> Void
    let onVerDetalle: (DeudaItem) -> Void
    
    @State private var seccionSeleccionada: SeccionTransaccion = .aportes
    @State private var mostrarFiltros = false
    @State private var animarEntrada = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header con pestañas modernas
            headerView
            
            // Contenido de la sección seleccionada
            contenidoSeccion
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .primary.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .scaleEffect(animarEntrada ? 1.0 : 0.95)
        .opacity(animarEntrada ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.8), value: animarEntrada)
        .onAppear {
            animarEntrada = true
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Título principal
            HStack {
                Text("📋 Transacciones del Mes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mostrarFiltros.toggle()
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Pestañas de navegación
            HStack(spacing: 0) {
                ForEach(SeccionTransaccion.allCases, id: \.self) { seccion in
                    BotonPestana(
                        seccion: seccion,
                        seleccionada: seccionSeleccionada,
                        count: countForSeccion(seccion)
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            seccionSeleccionada = seccion
                        }
                    }
                }
            }
            .padding(4)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .primary.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Contenido Sección
    @ViewBuilder
    private var contenidoSeccion: some View {
        switch seccionSeleccionada {
        case .aportes:
            ModernAportesListView(aportes: aportes, onEliminar: onEliminar)
        case .gastos:
            GastosListView(gastos: gastos, onEliminar: onEliminar)
        case .ahorros:
            AhorrosListView(ahorros: ahorros, onEliminar: onEliminar)
        case .deudas:
            ModernDeudasListView(deudas: deudas, onEliminar: onEliminar, onVerDetalle: onVerDetalle)
        }
    }
    
    private func countForSeccion(_ seccion: SeccionTransaccion) -> Int {
        switch seccion {
        case .aportes: return aportes.count
        case .gastos: return gastos.count
        case .ahorros: return ahorros.count
        case .deudas: return deudas.count
        }
    }
}

// MARK: - Secciones de Lista

struct ModernAportesListView: View {
    let aportes: [AporteItem]
    let onEliminar: (String, TipoTransaccion) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if aportes.isEmpty {
                EmptyStateView(
                    icono: "💰",
                    titulo: "No hay aportes registrados",
                    descripcion: "Agrega el primer aporte del mes"
                )
            } else {
                ForEach(aportes.indices, id: \.self) { index in
                    let aporte = aportes[index]
                    AporteRowView(
                        aporte: aporte,
                        animationDelay: Double(index) * 0.1,
                        onEliminar: { onEliminar(aporte.id, .aporte) }
                    )
                }
            }
        }
    }
}

struct GastosListView: View {
    let gastos: [GastoItem] // Cambiado de [String] a [GastoItem]
    let onEliminar: (String, TipoTransaccion) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            EmptyStateView(
                icono: "💸",
                titulo: "No hay gastos registrados",
                descripcion: "Los gastos aparecerán aquí"
            )
        }
    }
}

struct AhorrosListView: View {
    let ahorros: [AhorroItem] // Cambiado de [String] a [AhorroItem]
    let onEliminar: (String, TipoTransaccion) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            EmptyStateView(
                icono: "🏦",
                titulo: "No hay ahorros registrados",
                descripcion: "Registra tus primeros ahorros"
            )
        }
    }
}

struct ModernDeudasListView: View {
    let deudas: [DeudaItem]
    let onEliminar: (String, TipoTransaccion) -> Void
    let onVerDetalle: (DeudaItem) -> Void
    
    var body: some View {
        LazyVStack(spacing: 12) {
            if deudas.isEmpty {
                EmptyStateView(
                    icono: "💳",
                    titulo: "No hay deudas registradas",
                    descripcion: "¡Perfecto! Mantén tus finanzas sanas"
                )
            } else {
                ForEach(deudas.indices, id: \.self) { index in
                    let deuda = deudas[index]
                    DeudaRowView(
                        deuda: deuda,
                        animationDelay: Double(index) * 0.1,
                        onEliminar: { onEliminar(deuda.id, .deuda) },
                        onVerDetalle: { onVerDetalle(deuda) }
                    )
                }
            }
        }
    }
}

// MARK: - Row Views

struct AporteRowView: View {
    let aporte: AporteItem
    let animationDelay: Double
    let onEliminar: () -> Void
    
    @State private var isVisible = false
    @State private var showDeleteConfirmation = false
    
    private var iconoUsuario: some View {
        Circle()
            .fill(.green.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay {
                Text("👤")
                    .font(.title3)
            }
    }
    
    private var informacionPrincipal: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(aporte.usuario)
                .font(.headline)
                .fontWeight(.semibold)
            
            if !aporte.comentario.isEmpty {
                Text(aporte.comentario)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Text(formatoFecha(aporte.fecha))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            iconoUsuario
            
            informacionPrincipal
            
            Spacer()
            
            // Monto
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatoMoneda(aporte.monto))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
                
                Button("Eliminar") {
                    showDeleteConfirmation = true
                }
                .font(.caption)
                .foregroundStyle(.red)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .green.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.2), lineWidth: 1)
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: isVisible)
        .onAppear { isVisible = true }
        .confirmationDialog(
            "¿Eliminar aporte?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                onEliminar()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

struct DeudaRowView: View {
    let deuda: DeudaItem
    let animationDelay: Double
    let onEliminar: () -> Void
    let onVerDetalle: () -> Void
    
    @State private var isVisible = false
    @State private var showDeleteConfirmation = false
    
    private var iconoEstado: some View {
        Circle()
            .fill(deuda.esPagado ? .green.opacity(0.2) : .orange.opacity(0.2))
            .frame(width: 40, height: 40)
            .overlay {
                Text(deuda.esPagado ? "✅" : "💳")
                    .font(.title3)
            }
    }
    
    private var informacionDeuda: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deuda.descripcion.isEmpty ? "Deuda" : deuda.descripcion)
                .font(.headline)
                .fontWeight(.semibold)
            
            if !deuda.categoria.isEmpty {
                Text(deuda.categoria)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("Pago único")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var montoYAcciones: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(formatoMoneda(deuda.monto))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.orange)
            
            HStack(spacing: 8) {
                Button("Ver Detalle") {
                    onVerDetalle()
                }
                .font(.caption)
                .foregroundStyle(.blue)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                iconoEstado
                
                informacionDeuda
                
                Spacer()
                
                montoYAcciones
                
                Button("Eliminar") {
                    showDeleteConfirmation = true
                }
                .font(.caption)
                .foregroundStyle(.red)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: (deuda.esPagado ? Color.green : Color.orange).opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke((deuda.esPagado ? Color.green : Color.orange).opacity(0.2), lineWidth: 1)
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: isVisible)
        .onAppear { isVisible = true }
        .confirmationDialog(
            "¿Eliminar deuda?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                onEliminar()
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

struct GastoRowView: View {
    let gasto: GastoItem
    let animationDelay: Double
    let onEliminar: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icono categoría
            Circle()
                .fill(.red.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(iconoCategoria(gasto.categoria))
                        .font(.title3)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gasto.descripcion.isEmpty ? "Gasto" : gasto.descripcion)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if !gasto.categoria.isEmpty {
                    Text(gasto.categoria)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(formatoMoneda(gasto.monto))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.red)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .red.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: isVisible)
        .onAppear { isVisible = true }
    }
    
    private func iconoCategoria(_ categoria: String) -> String {
        let cat = categoria.lowercased()
        if cat.contains("salud") { return "🩺" }
        if cat.contains("comida") || cat.contains("supermercado") { return "🛒" }
        if cat.contains("transporte") { return "🚗" }
        if cat.contains("educación") { return "📚" }
        return "💸"
    }
}

struct AhorroRowView: View {
    let ahorro: AhorroItem
    let animationDelay: Double
    let onEliminar: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay {
                    Text("🏦")
                        .font(.title3)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ahorro.descripcion.isEmpty ? "Ahorro" : ahorro.descripcion)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(formatoFecha(ahorro.fechaRegistro))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Text(formatoMoneda(ahorro.monto))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .blue.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.5).delay(animationDelay), value: isVisible)
        .onAppear { isVisible = true }
    }
}

// MARK: - Supporting Views

struct BotonPestana: View {
    let seccion: SeccionTransaccion
    let seleccionada: SeccionTransaccion
    let count: Int
    let accion: () -> Void
    
    var isSelected: Bool { seccion == seleccionada }
    
    var body: some View {
        Button(action: accion) {
            HStack(spacing: 6) {
                Text(seccion.icono)
                    .font(.caption)
                
                Text(seccion.titulo)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(isSelected ? .white.opacity(0.3) : .gray.opacity(0.2))
                        }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    let icono: String
    let titulo: String
    let descripcion: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text(icono)
                .font(.system(size: 48))
            
            VStack(spacing: 8) {
                Text(titulo)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(descripcion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

// MARK: - Data Models y Enums

enum SeccionTransaccion: CaseIterable {
    case aportes, gastos, ahorros, deudas
    
    var titulo: String {
        switch self {
        case .aportes: return "Aportes"
        case .gastos: return "Gastos"
        case .ahorros: return "Ahorros"
        case .deudas: return "Deudas"
        }
    }
    
    var icono: String {
        switch self {
        case .aportes: return "💰"
        case .gastos: return "💸"
        case .ahorros: return "🏦"
        case .deudas: return "💳"
        }
    }
}

// MARK: - Helper Functions

private func formatoMoneda(_ valor: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "CLP"
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: valor)) ?? "$0"
}

private func formatoFecha(_ fecha: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.locale = Locale(identifier: "es_ES")
    return formatter.string(from: fecha)
}

// MARK: - GradientProgressViewStyle

struct GradientProgressViewStyle: ProgressViewStyle {
    let gradient: LinearGradient
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(gradient)
                    .frame(
                        width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0),
                        height: 6
                    )
                    .animation(.easeInOut(duration: 0.8), value: configuration.fractionCompleted)
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    let aportes = [
        Aporte(presupuestoId: "1", usuario: "Juan Pérez", monto: 800000, comentario: "Sueldo mensual"),
        Aporte(presupuestoId: "1", usuario: "María García", monto: 200000, comentario: "Trabajo freelance")
    ]
    
    let deudas = [
        DeudaItem(id: "1", descripcion: "Supermercado", monto: 150000, categoria: "Alimentación", fechaRegistro: Date(), esPagado: false, responsable: "Juan Pérez"),
        DeudaItem(id: "2", descripcion: "Tarjeta de crédito", monto: 500000, categoria: "Financiero", fechaRegistro: Date(), esPagado: false, responsable: "María García")
    ]
    
    ListadoTransaccionesModerno(
        aportes: aportes.map { AporteItem(from: $0) },
        gastos: [],
        ahorros: [],
        deudas: deudas,
        onEliminar: { _, _ in },
        onVerDetalle: { _ in }
    )
    .preferredColorScheme(ColorScheme.light)
    .padding()
}
