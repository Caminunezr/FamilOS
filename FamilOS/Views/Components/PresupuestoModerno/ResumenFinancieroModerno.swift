import SwiftUI

struct ResumenFinancieroModerno: View {
    let resumen: ResumenPresupuesto
    let presupuesto: PresupuestoMensual?
    let isLoading: Bool
    
    init(resumen: ResumenPresupuesto, presupuesto: PresupuestoMensual? = nil, isLoading: Bool = false) {
        self.resumen = resumen
        self.presupuesto = presupuesto
        self.isLoading = isLoading
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header del resumen
            headerView
            
            // Grid de tarjetas financieras
            LazyVGrid(columns: columnas, spacing: 16) {
                ForEach(tarjetasFinancieras.indices, id: \.self) { index in
                    let tarjeta = tarjetasFinancieras[index]
                    TarjetaFinanciera(
                        titulo: tarjeta.titulo,
                        valor: tarjeta.valor,
                        color: tarjeta.color,
                        icono: tarjeta.icono,
                        descripcion: tarjeta.descripcion,
                        porcentaje: tarjeta.porcentaje,
                        gradiente: tarjeta.gradiente,
                        animationDelay: Double(index) * 0.1
                    )
                    .opacity(isLoading ? 0.6 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .primary.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("💰 Resumen Financiero")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                if let presupuesto = presupuesto {
                    Text("Período: \(mesFormateado(presupuesto.fechaMes))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Sobrante disponible destacado
            VStack(alignment: .trailing, spacing: 4) {
                Text("Sobrante Disponible")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(formatoMoneda(resumen.saldoAportes))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(colorSobrante)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradienteSobrante)
                    .shadow(color: colorSobrante.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .foregroundStyle(.white)
        }
    }
    
    // MARK: - Computed Properties
    private var columnas: [GridItem] {
        [
            GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 16)
        ]
    }
    
    private var colorSobrante: Color {
        resumen.saldoAportes >= 0 ? .green : .red
    }
    
    private var gradienteSobrante: LinearGradient {
        LinearGradient(
            colors: resumen.saldoAportes >= 0 
                ? [.green.opacity(0.8), .green]
                : [.red.opacity(0.8), .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var tarjetasFinancieras: [TarjetaData] {
        [
            TarjetaData(
                titulo: "Total Aportado",
                valor: resumen.totalAportado,
                color: .green,
                icono: "💰",
                descripcion: "Dinero ingresado al presupuesto familiar",
                porcentaje: nil,
                gradiente: LinearGradient(colors: [.green.opacity(0.8), .green], startPoint: .topLeading, endPoint: .bottomTrailing)
            ),
            TarjetaData(
                titulo: "Total Gastado",
                valor: resumen.totalGastado,
                color: .red,
                icono: "💸",
                descripcion: "\(String(format: "%.1f", resumen.porcentajeGastado))% del total aportado",
                porcentaje: resumen.porcentajeGastado,
                gradiente: LinearGradient(colors: [.red.opacity(0.8), .red], startPoint: .topLeading, endPoint: .bottomTrailing)
            ),
            TarjetaData(
                titulo: "Total Ahorrado",
                valor: resumen.totalAhorrado,
                color: .blue,
                icono: "🏦",
                descripcion: "\(String(format: "%.1f", resumen.porcentajeAhorrado))% del total aportado",
                porcentaje: resumen.porcentajeAhorrado,
                gradiente: LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            ),
            TarjetaData(
                titulo: "Deuda Activa",
                valor: resumen.totalDeuda,
                color: .orange,
                icono: "💳",
                descripcion: "Deudas pendientes de pago",
                porcentaje: nil,
                gradiente: LinearGradient(colors: [.orange.opacity(0.8), .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        ]
    }
    
    private func mesFormateado(_ fecha: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: fecha).capitalized
    }
    
    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CLP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: valor)) ?? "$0"
    }
}

// MARK: - Supporting Views

fileprivate struct TarjetaData {
    let titulo: String
    let valor: Double
    let color: Color
    let icono: String
    let descripcion: String
    let porcentaje: Double?
    let gradiente: LinearGradient
}

struct TarjetaFinanciera: View {
    let titulo: String
    let valor: Double
    let color: Color
    let icono: String
    let descripcion: String
    let porcentaje: Double?
    let gradiente: LinearGradient
    let animationDelay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header con icono y título
            HStack(spacing: 12) {
                Text(icono)
                    .font(.title2)
                    .accessibilityLabel("Icono de \(titulo)")
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(formatoMoneda(valor))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
            }
            
            // Descripción
            if !descripcion.isEmpty {
                Text(descripcion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Barra de progreso si hay porcentaje
            if let porcentaje = porcentaje {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progreso")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", porcentaje))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                    }
                    
                    ProgressView(value: min(porcentaje, 100), total: 100)
                        .progressViewStyle(GradientProgressViewStyle(gradient: gradiente))
                        .scaleEffect(x: isVisible ? 1.0 : 0.0, anchor: .leading)
                        .animation(.easeOut(duration: 1.0).delay(animationDelay + 0.5), value: isVisible)
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        }
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
    
    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CLP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: valor)) ?? "$0"
    }
}

struct LoadingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Cargando datos financieros...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
    }
}

// MARK: - Data Models

// Se elimina GradientProgressViewStyle duplicado (se usa el de ListadoTransaccionesModerno)

// Se eliminan los modelos locales `TarjetaData`, `ResumenFinanciero` y `Presupuesto`.
// Ahora se utilizan los modelos globales definidos en la capa de Modelo de la aplicación.

#Preview {
    let resumenEjemplo = ResumenPresupuesto(
        totalAportado: 2500000,
        totalGastado: 1800000,
        totalAhorrado: 500000,
        totalDeuda: 200000
    )
    
    let presupuestoEjemplo = PresupuestoMensual(
        fechaMes: Date(),
        creador: "usuario1"
    )
    
    ResumenFinancieroModerno(
        resumen: resumenEjemplo,
        presupuesto: presupuestoEjemplo,
        isLoading: false
    )
    .preferredColorScheme(.light)
    .padding()
}
