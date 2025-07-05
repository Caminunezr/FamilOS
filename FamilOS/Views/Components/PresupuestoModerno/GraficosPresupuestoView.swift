import SwiftUI
import Charts

struct GraficosPresupuestoView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Gráficos del Presupuesto")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                // Gráfico de aportes
                graficoAportes
                
                // Gráfico de gastos
                graficoGastos
            }
            
            // Gráfico de balance temporal
            if !viewModel.aportesDelMes.isEmpty || !viewModel.deudasDelMes.isEmpty {
                balanceTemporal
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Subvistas
    
    private var graficoAportes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aportes por Usuario")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !viewModel.aportesDelMes.isEmpty {
                Chart(aportesAgrupados, id: \.usuario) { item in
                    SectorMark(
                        angle: .value("Monto", item.total),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .cornerRadius(8)
                    .foregroundStyle(by: .value("Usuario", item.usuario))
                    .opacity(0.8)
                }
                .frame(height: 180)
                .chartAngleSelection(value: .constant(nil as Double?))
                .chartLegend(position: .bottom, alignment: .leading, spacing: 4)
            } else {
                VStack {
                    Image(systemName: "chart.pie")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    
                    Text("Sin aportes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var graficoGastos: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gastos por Categoría")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !viewModel.deudasDelMes.isEmpty {
                Chart(gastosAgrupados, id: \.categoria) { item in
                    BarMark(
                        x: .value("Monto", item.total),
                        y: .value("Categoría", item.categoria)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(.orange.gradient)
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(position: .bottom)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
            } else {
                VStack {
                    Image(systemName: "chart.bar")
                        .font(.title2)
                        .foregroundStyle(.gray)
                    
                    Text("Sin gastos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var balanceTemporal: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Balance Acumulado")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Chart {
                ForEach(balanceAcumulado, id: \.dia) { item in
                    LineMark(
                        x: .value("Día", item.dia),
                        y: .value("Balance", item.balance)
                    )
                    .foregroundStyle(.blue.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Día", item.dia),
                        y: .value("Balance", item.balance)
                    )
                    .foregroundStyle(.blue.gradient.opacity(0.2))
                }
            }
            .frame(height: 120)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisValueLabel()
                        .font(.caption)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let balance = value.as(Double.self) {
                            Text(balance.formatearComoMoneda())
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    // MARK: - Computed Properties
    
    private var aportesAgrupados: [(usuario: String, total: Double)] {
        let agrupados = Dictionary(grouping: viewModel.aportesDelMes) { $0.usuario }
        return agrupados.map { (usuario, aportes) in
            (usuario: usuario, total: aportes.reduce(0) { $0 + $1.monto })
        }.sorted { $0.total > $1.total }
    }
    
    private var gastosAgrupados: [(categoria: String, total: Double)] {
        let agrupados = Dictionary(grouping: viewModel.deudasDelMes) { $0.categoria }
        return agrupados.map { (categoria, deudas) in
            (categoria: categoria, total: deudas.reduce(0) { $0 + $1.monto })
        }.sorted { $0.total > $1.total }
    }
    
    private var balanceAcumulado: [(dia: Int, balance: Double)] {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        
        var balance: Double = 0
        var resultados: [(dia: Int, balance: Double)] = []
        
        // Obtener el rango de días del mes
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        
        for day in 1...min(daysInMonth, calendar.component(.day, from: today)) {
            let fecha = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) ?? today
            
            // Sumar aportes del día
            let aportesDelDia = viewModel.aportesDelMes.filter {
                calendar.isDate(Date(timeIntervalSince1970: $0.fecha), inSameDayAs: fecha)
            }.reduce(0) { $0 + $1.monto }
            
            // Restar gastos del día
            let gastosDelDia = viewModel.deudasDelMes.filter {
                calendar.isDate($0.fechaRegistro, inSameDayAs: fecha)
            }.reduce(0) { $0 + $1.monto }
            
            balance += aportesDelDia - gastosDelDia
            resultados.append((dia: day, balance: balance))
        }
        
        return resultados
    }
}

// MARK: - Preview
#Preview {
    GraficosPresupuestoView(viewModel: PresupuestoViewModel())
        .padding()
}
