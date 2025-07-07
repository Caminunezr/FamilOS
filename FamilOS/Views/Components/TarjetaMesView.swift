import SwiftUI

struct TarjetaMesView: View {
    let mesInfo: MesPresupuestoInfo
    let esMesActual: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // Animación de tap
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    scale = 1.0
                }
                onTap()
            }
        }) {
            VStack(spacing: 12) {
                // Header del mes
                headerMes
                
                // Indicadores de estado
                indicadoresEstado
                
                // Información financiera
                informacionFinanciera
                
                // Barra de progreso
                if mesInfo.tienePresupuesto {
                    barraProgreso
                }
                
                // Alertas (solo mostrar las más importantes)
                if !mesInfo.alertas.isEmpty {
                    alertasView
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                    .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            }
            .scaleEffect(scale)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Subvistas
    
    private var headerMes: some View {
        VStack(spacing: 4) {
            Text(mesInfo.nombre)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(esMesActual ? .white : .primary)
                .lineLimit(1)
            
            if esMesActual {
                Text("Mes Actual")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.white.opacity(0.2)))
            } else if mesInfo.año < Calendar.current.component(.year, from: Date()) {
                Text("Pasado")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var indicadoresEstado: some View {
        HStack {
            // Estado del presupuesto
            EstadoPresupuestoIcon(estado: mesInfo.estadoMes)
            
            Spacer()
            
            // Número de transacciones
            if mesInfo.cantidadTransacciones > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.caption2)
                    Text("\(mesInfo.cantidadTransacciones)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(.ultraThinMaterial))
            }
        }
    }
    
    private var informacionFinanciera: some View {
        VStack(spacing: 8) {
            // Fila de Aportado y Gastado
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aportado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(mesInfo.totalAportes.formatearComoMoneda())
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Gastado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(mesInfo.totalGastos.formatearComoMoneda())
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
            }
            
            // Fila de Utilizado y Disponible  
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Utilizado")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(mesInfo.totalAportesUtilizados.formatearComoMoneda())
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Disponible")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(mesInfo.saldoDisponible.formatearComoMoneda())
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var barraProgreso: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Progreso")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(Int(mesInfo.porcentajeGastado * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(colorProgreso)
            }
            
            ProgressView(value: min(mesInfo.porcentajeGastado, 1.0), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(colorProgreso)
                .scaleEffect(y: 0.8)
        }
    }
    
    private var alertasView: some View {
        HStack(spacing: 4) {
            ForEach(mesInfo.alertas.prefix(3)) { alerta in
                AlertaIndicador(alerta: alerta)
            }
            
            if mesInfo.alertas.count > 3 {
                Text("+\(mesInfo.alertas.count - 3)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties para estilos
    
    private var backgroundGradient: LinearGradient {
        if esMesActual {
            return LinearGradient(
                colors: [.blue.opacity(0.8), .blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [.primary.opacity(0.02), .primary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var borderColor: Color {
        if esMesActual {
            return .blue.opacity(0.4)
        } else {
            return mesInfo.colorIndicador.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        esMesActual ? 2 : 1
    }
    
    private var shadowColor: Color {
        if esMesActual {
            return .blue.opacity(0.3)
        } else {
            return .primary.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        isHovered ? 12 : 8
    }
    
    private var shadowY: CGFloat {
        isHovered ? 6 : 4
    }
    
    private var colorProgreso: Color {
        if mesInfo.porcentajeGastado > 1.0 {
            return .red
        } else if mesInfo.porcentajeGastado > 0.8 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#Preview {
    let mesInfo = MesPresupuestoInfo(
        mes: 7,
        año: 2025,
        fecha: Date(),
        nombre: "Julio",
        presupuesto: nil,
        totalAportes: 150000,
        totalAportesUtilizados: 120000,
        totalGastos: 90000,
        saldoDisponible: 30000,
        cantidadTransacciones: 5,
        estaCerrado: false,
        alertas: [
            AlertaFinancieraCalendario(
                tipo: .saldoBajo,
                mensaje: "Saldo bajo",
                color: .orange,
                icono: "exclamationmark.triangle.fill"
            )
        ]
    )
    
    HStack {
        TarjetaMesView(
            mesInfo: mesInfo,
            esMesActual: true,
            onTap: {}
        )
        .frame(width: 200, height: 250)
        
        TarjetaMesView(
            mesInfo: mesInfo,
            esMesActual: false,
            onTap: {}
        )
        .frame(width: 200, height: 250)
    }
    .padding()
}
