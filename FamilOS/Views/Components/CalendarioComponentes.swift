import SwiftUI

// MARK: - Componente para el icono de estado del presupuesto

struct EstadoPresupuestoIcon: View {
    let estado: EstadoMes
    
    var body: some View {
        Image(systemName: icono)
            .font(.title3)
            .foregroundStyle(color)
    }
    
    private var icono: String {
        switch estado {
        case .vacio:
            return "circle"
        case .activo:
            return "circle.fill"
        case .cerrado:
            return "checkmark.circle.fill"
        }
    }
    
    private var color: Color {
        switch estado {
        case .vacio:
            return .gray
        case .activo:
            return .blue
        case .cerrado:
            return .green
        }
    }
}

// MARK: - Tarjeta de métrica para resumen

struct ResumenMetricaCard: View {
    let titulo: String
    let valor: Double
    let color: Color
    let icono: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icono)
                    .foregroundStyle(color)
                Text(titulo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Text(valor.formatearComoMoneda())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        }
    }
}

// MARK: - Componente para indicadores de alertas

struct AlertaIndicador: View {
    let alerta: AlertaFinancieraCalendario
    
    var body: some View {
        Image(systemName: alerta.icono)
            .font(.caption)
            .foregroundStyle(alerta.color)
            .help(alerta.mensaje)
    }
}

// MARK: - Vista de estadísticas rápidas

struct EstadisticasRapidasView: View {
    let mesesConPresupuesto: Int
    let mesesCerrados: Int
    let totalMeses: Int = 12
    
    var body: some View {
        HStack(spacing: 20) {
            EstadisticaItem(
                titulo: "Con Presupuesto",
                valor: "\(mesesConPresupuesto)/\(totalMeses)",
                color: .blue,
                icono: "calendar.circle.fill"
            )
            
            EstadisticaItem(
                titulo: "Cerrados",
                valor: "\(mesesCerrados)/\(totalMeses)",
                color: .green,
                icono: "checkmark.circle.fill"
            )
            
            EstadisticaItem(
                titulo: "Progreso",
                valor: "\(Int((Double(mesesCerrados)/Double(totalMeses)) * 100))%",
                color: .orange,
                icono: "chart.line.uptrend.xyaxis.circle.fill"
            )
        }
    }
}

struct EstadisticaItem: View {
    let titulo: String
    let valor: String
    let color: Color
    let icono: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icono)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(valor)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(titulo)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Selector de año con animación

struct SelectorAñoView: View {
    @Binding var añoSeleccionado: Int
    let onCambioAño: (Int) -> Void
    
    private let añoMinimo = 2020
    private let añoMaximo = 2030
    
    var body: some View {
        HStack {
            Button(action: { cambiarAño(-1) }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .disabled(añoSeleccionado <= añoMinimo)
            
            Spacer()
            
            Text("\(añoSeleccionado)")
                .font(.title2)
                .fontWeight(.semibold)
                .contentTransition(.numericText())
            
            Spacer()
            
            Button(action: { cambiarAño(1) }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .disabled(añoSeleccionado >= añoMaximo)
        }
        .padding(.horizontal, 20)
    }
    
    private func cambiarAño(_ incremento: Int) {
        let nuevoAño = añoSeleccionado + incremento
        if nuevoAño >= añoMinimo && nuevoAño <= añoMaximo {
            withAnimation(.easeInOut(duration: 0.3)) {
                añoSeleccionado = nuevoAño
            }
            onCambioAño(nuevoAño)
        }
    }
}

// MARK: - Loading View personalizada

struct CalendarioLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            Text("Cargando datos del calendario...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Error View

struct CalendarioErrorView: View {
    let mensaje: String
    let onReintentar: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("Error al cargar datos")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(mensaje)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Reintentar") {
                onReintentar()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
