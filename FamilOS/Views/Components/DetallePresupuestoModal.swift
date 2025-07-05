import SwiftUI

struct DetallePresupuestoModal: View {
    let mesInfo: MesPresupuestoInfo
    @EnvironmentObject var presupuestoViewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var mostrarVistaCompleta = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header con información del mes
                    headerDetalleMes
                    
                    // Resumen financiero detallado
                    resumenFinancieroDetallado
                    
                    // Vista de componentes reutilizados de la app
                    if mesInfo.tienePresupuesto {
                        componentesPresupuesto
                    } else {
                        vistaPresupuestoVacio
                    }
                }
                .padding(24)
            }
            .navigationTitle("Detalle \(mesInfo.nombre) \(mesInfo.año)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { 
                        dismiss() 
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("📋 Abrir Vista Completa") {
                            abrirVistaCompleta()
                        }
                        
                        if !mesInfo.estaCerrado {
                            Divider()
                            
                            Button("💰 Agregar Aporte") {
                                agregarAporte()
                            }
                            
                            Button("💳 Registrar Gasto") {
                                registrarGasto()
                            }
                            
                            if mesInfo.tienePresupuesto && mesInfo.saldoFinal > 0 {
                                Divider()
                                
                                Button("🔒 Cerrar Mes") {
                                    cerrarMes()
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button("📊 Ver Estadísticas") {
                            // TODO: Implementar vista de estadísticas del mes
                        }
                        
                        Button("📤 Exportar Datos") {
                            exportarDatosMes()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                    }
                }
            }
        }
        .onAppear {
            // Sincronizar el mes seleccionado en el PresupuestoViewModel
            presupuestoViewModel.mesSeleccionado = mesInfo.fecha
        }
    }
    
    // MARK: - Subvistas
    
    private var headerDetalleMes: some View {
        VStack(spacing: 16) {
            // Título y estado
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mesInfo.nombre)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(estadoDescripcion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                estadoBadge
            }
            
            // Métricas principales
            HStack(spacing: 20) {
                MetricaCard(
                    titulo: "Aportado", 
                    valor: mesInfo.totalAportes, 
                    color: .green
                )
                MetricaCard(
                    titulo: "Gastado", 
                    valor: mesInfo.totalGastos, 
                    color: .orange
                )
                MetricaCard(
                    titulo: "Saldo", 
                    valor: mesInfo.saldoDisponible, 
                    color: mesInfo.saldoDisponible >= 0 ? .blue : .red
                )
            }
            
            // Alertas del mes
            if !mesInfo.alertas.isEmpty {
                alertasMes
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private var resumenFinancieroDetallado: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Resumen Financiero")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if mesInfo.cantidadTransacciones > 0 {
                    Text("\(mesInfo.cantidadTransacciones) transacciones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
            }
            
            // Gráfico de progreso
            if mesInfo.tienePresupuesto {
                progresoMes
            }
            
            // Balance final
            balanceFinal
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
    
    private var componentesPresupuesto: some View {
        VStack(spacing: 20) {
            // Reutilizar componentes existentes de la app
            if presupuestoViewModel.mesSeleccionado.esMismoMes(que: mesInfo.fecha) {
                
                // Resumen financiero (reutilizando componente existente)
                Group {
                    Text("Aportes del Mes")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Lista simplificada de aportes
                    if !presupuestoViewModel.aportesDelMes.isEmpty {
                        VStack(spacing: 8) {
                            ForEach(presupuestoViewModel.aportesDelMes.prefix(3)) { aporte in
                                AporteResumenRow(aporte: aporte)
                            }
                            
                            if presupuestoViewModel.aportesDelMes.count > 3 {
                                Text("+ \(presupuestoViewModel.aportesDelMes.count - 3) aportes más")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.regularMaterial)
                        }
                    } else {
                        noDataView(mensaje: "No hay aportes registrados")
                    }
                }                    // Transacciones/Gastos del mes
                    Group {
                        Text("Gastos del Mes")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if !presupuestoViewModel.deudasDelMes.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(presupuestoViewModel.deudasDelMes.prefix(3)) { deuda in
                                    DeudaResumenRow(deuda: deuda)
                                }
                                
                                if presupuestoViewModel.deudasDelMes.count > 3 {
                                    Text("+ \(presupuestoViewModel.deudasDelMes.count - 3) gastos más")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.regularMaterial)
                            }
                        } else {
                            noDataView(mensaje: "No hay gastos registrados")
                        }
                    }
            }
        }
    }
    
    private var vistaPresupuestoVacio: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("Sin Presupuesto")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Este mes no tiene un presupuesto creado. Crea uno para comenzar a gestionar tus finanzas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Crear Presupuesto") {
                crearPresupuestoParaMes()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    private var estadoBadge: some View {
        Group {
            switch mesInfo.estadoMes {
            case .cerrado:
                Label("Cerrado", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.green.opacity(0.2)))
            case .activo:
                Label("Activo", systemImage: "circle.fill")
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.blue.opacity(0.2)))
            case .vacio:
                Label("Sin presupuesto", systemImage: "circle")
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.gray.opacity(0.2)))
            }
        }
        .font(.caption)
        .fontWeight(.medium)
    }
    
    private var alertasMes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Alertas")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(mesInfo.alertas) { alerta in
                HStack {
                    Image(systemName: alerta.icono)
                        .foregroundStyle(alerta.color)
                    Text(alerta.mensaje)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.orange.opacity(0.1))
        }
    }
    
    private var progresoMes: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progreso del gasto")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(mesInfo.porcentajeGastado * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(colorProgreso)
            }
            
            ProgressView(value: min(mesInfo.porcentajeGastado, 1.0), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(colorProgreso)
        }
    }
    
    private var balanceFinal: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Balance Final")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(mesInfo.saldoFinal.formatearComoMoneda())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(mesInfo.saldoFinal >= 0 ? .green : .red)
            }
            
            Spacer()
            
            Image(systemName: mesInfo.saldoFinal >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.title)
                .foregroundStyle(mesInfo.saldoFinal >= 0 ? .green : .red)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill((mesInfo.saldoFinal >= 0 ? Color.green : Color.red).opacity(0.1))
        }
    }
    
    // MARK: - Computed Properties
    
    private var estadoDescripcion: String {
        switch mesInfo.estadoMes {
        case .cerrado:
            return "Mes cerrado y finalizado"
        case .activo:
            return "Presupuesto activo y en uso"
        case .vacio:
            return "No hay presupuesto creado"
        }
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
    
    // MARK: - Funciones
    
    private func abrirVistaCompleta() {
        presupuestoViewModel.mesSeleccionado = mesInfo.fecha
        mostrarVistaCompleta = true
        dismiss()
    }
    
    private func agregarAporte() {
        // TODO: Implementar adición de aporte
        presupuestoViewModel.mesSeleccionado = mesInfo.fecha
        dismiss()
    }
    
    private func registrarGasto() {
        // TODO: Implementar registro de gasto
        presupuestoViewModel.mesSeleccionado = mesInfo.fecha
        dismiss()
    }
    
    private func cerrarMes() {
        Task {
            isLoading = true
            await presupuestoViewModel.cerrarMes()
            isLoading = false
            dismiss()
        }
    }
    
    private func crearPresupuestoParaMes() {
        Task {
            isLoading = true
            presupuestoViewModel.mesSeleccionado = mesInfo.fecha
            await presupuestoViewModel.crearPresupuestoMes()
            isLoading = false
        }
    }
    
    private func exportarDatosMes() {
        // TODO: Implementar exportación de datos del mes
        print("📤 Exportando datos de \(mesInfo.nombre) \(mesInfo.año)")
    }
    
    private func noDataView(mensaje: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.gray)
            
            Text(mensaje)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.opacity(0.1))
        }
    }
}

// MARK: - Componentes auxiliares

struct MetricaCard: View {
    let titulo: String
    let valor: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(valor.formatearComoMoneda())
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        }
    }
}

struct AporteResumenRow: View {
    let aporte: Aporte
    
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(aporte.usuario)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !aporte.comentario.isEmpty {
                    Text(aporte.comentario)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(aporte.monto.formatearComoMoneda())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                
                Text("Disponible: \(aporte.saldoDisponible.formatearComoMoneda())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DeudaResumenRow: View {
    let deuda: DeudaItem
    
    var body: some View {
        HStack {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(deuda.descripcion)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(deuda.responsable)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(deuda.monto.formatearComoMoneda())
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                
                if deuda.esPagado {
                    Text("Pagado")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Pendiente")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}
