import SwiftUI

// MARK: - FASE 2: Selector de Aportes para Pagos
struct SelectorAportesView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var presupuestoViewModel: PresupuestoViewModel
    let montoRequerido: Double
    @Binding var aporteSeleccionado: Aporte?
    @Binding var montoAUsar: Double
    
    @State private var mostrandoDetalles = false
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            
            if aportesDisponibles.isEmpty {
                emptyStateView
            } else {
                aportesList
                
                if let aporte = aporteSeleccionado {
                    selectedAporteDetails(aporte)
                }
            }
        }
        .onAppear {
            // Auto-seleccionar el primer aporte si hay suficiente saldo
            if aporteSeleccionado == nil, let primerAporte = aportesConSuficienteSaldo.first {
                aporteSeleccionado = primerAporte
                montoAUsar = min(montoRequerido, primerAporte.saldoDisponible)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var aportesDisponibles: [Aporte] {
        presupuestoViewModel.aportesDisponibles
    }
    
    private var aportesConSuficienteSaldo: [Aporte] {
        presupuestoViewModel.aportesQuePuedenCubrir(monto: montoRequerido)
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
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "wallet.pass")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Seleccionar Aporte")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(primaryTextColor)
                
                Spacer()
                
                Button(action: { mostrandoDetalles.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                Text("Monto requerido:")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                
                Spacer()
                
                Text("$\(String(format: "%.0f", montoRequerido))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(glassMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Lista de Aportes
    private var aportesList: some View {
        VStack(spacing: 12) {
            ForEach(aportesDisponibles) { aporte in
                AporteRowView(
                    aporte: aporte,
                    montoRequerido: montoRequerido,
                    isSelected: aporteSeleccionado?.id == aporte.id,
                    onSelect: {
                        aporteSeleccionado = aporte
                        montoAUsar = min(montoRequerido, aporte.saldoDisponible)
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Detalles del Aporte Seleccionado
    private func selectedAporteDetails(_ aporte: Aporte) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Aporte Seleccionado")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(primaryTextColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                detailRow("Usuario", value: aporte.usuario)
                detailRow("Saldo Disponible", value: "$\(String(format: "%.0f", aporte.saldoDisponible))")
                detailRow("Total Aporte", value: "$\(String(format: "%.0f", aporte.monto))")
                
                Divider()
                
                HStack {
                    Text("Monto a usar:")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.0f", montoAUsar))")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.green)
                }
                
                if montoAUsar < montoRequerido {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Saldo insuficiente. Faltan $\(String(format: "%.0f", montoRequerido - montoAUsar))")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(glassMaterial)
        .cornerRadius(12)
        .padding(.horizontal)
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
    
    // MARK: - Helper Views
    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(primaryTextColor)
        }
    }
}

// MARK: - Vista de Fila de Aporte
struct AporteRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    let aporte: Aporte
    let montoRequerido: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Indicador de selección
                Circle()
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .opacity(isSelected ? 1 : 0)
                    )
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(aporte.usuario)
                            .font(.headline.weight(.medium))
                            .foregroundColor(primaryTextColor)
                        
                        Spacer()
                        
                        // Badge de estado
                        statusBadge
                    }
                    
                    HStack {
                        Text("Saldo: $\(String(format: "%.0f", aporte.saldoDisponible))")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("Total: $\(String(format: "%.0f", aporte.monto))")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    // Barra de progreso
                    progressBar
                }
                
                // Icono de estado
                Image(systemName: aporte.saldoDisponible >= montoRequerido ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(aporte.saldoDisponible >= montoRequerido ? .green : .orange)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AnyShapeStyle(glassMaterialSelected) : AnyShapeStyle(glassMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    private var statusBadge: some View {
        let texto: String
        let color: Color
        
        if aporte.saldoDisponible >= montoRequerido {
            texto = "Suficiente"
            color = .green
        } else if aporte.saldoDisponible > 0 {
            texto = "Parcial"
            color = .orange
        } else {
            texto = "Agotado"
            color = .red
        }
        
        return Text(texto)
            .font(.caption.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
            )
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * min(1.0, aporte.porcentajeUtilizado / 100), height: 4),
                    alignment: .leading
                )
        }
        .frame(height: 4)
    }
    
    // MARK: - Estilos
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

// MARK: - Preview
#Preview {
    let presupuestoVM = PresupuestoViewModel()
    
    // Mock data
    let mockAportes = [
        Aporte(presupuestoId: "test", usuario: "leo@leo.com", monto: 50000, comentario: "Aporte mensual"),
        Aporte(presupuestoId: "test", usuario: "ana@ana.com", monto: 30000, comentario: "Aporte quincenal")
    ]
    
    SelectorAportesView(
        presupuestoViewModel: presupuestoVM,
        montoRequerido: 25000,
        aporteSeleccionado: .constant(nil),
        montoAUsar: .constant(0)
    )
    .onAppear {
        presupuestoVM.aportes = mockAportes
    }
    .padding()
    .preferredColorScheme(.light)
}
