import SwiftUI

struct DetallePresupuestoModal: View {
    let mesInfo: MesPresupuestoInfo
    @EnvironmentObject var presupuestoViewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var mostrarVistaCompleta = false
    @State private var isLoading = false
    @State private var mostrarModalGasto = false
    @State private var mostrarModalAporte = false
    @State private var mostrarAlertaEliminarAporte = false
    @State private var aporteAEliminar: Aporte?
    @State private var vistaGastos: VistaGastos = .todos
    
    enum VistaGastos: String, CaseIterable {
        case todos = "Todos"
        case pagados = "Pagados"
        case pendientes = "Pendientes"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header con información del mes
                    headerDetalleMes
                    
                    // Resumen financiero detallado
                    if !presupuestoViewModel.aportes.isEmpty {
                        resumenFinancieroCompleto
                    } else {
                        noDataView(mensaje: "No hay aportes registrados")
                    }
                    
                    // Gastos del mes mejorado
                    gastosDelMesMejorado
                }
                .padding(.horizontal)
            }
            .background(.regularMaterial)
            .navigationTitle("Detalle del Mes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(.blue)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            mostrarModalAporte = true
                        } label: {
                            Label("Agregar Aporte", systemImage: "plus.circle")
                        }
                        
                        Button {
                            mostrarModalGasto = true
                        } label: {
                            Label("Registrar Gasto", systemImage: "minus.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $mostrarModalGasto) {
            NuevaDeudaView(viewModel: presupuestoViewModel)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $mostrarModalAporte) {
            NuevoAporteView(viewModel: presupuestoViewModel)
                .environmentObject(authViewModel)
        }
        .alert("Eliminar Aporte", isPresented: $mostrarAlertaEliminarAporte) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let aporte = aporteAEliminar {
                    eliminarAporte(aporte)
                }
            }
        } message: {
            if let aporte = aporteAEliminar {
                Text("¿Estás seguro de que quieres eliminar el aporte de \(aporte.monto.formatearComoMoneda()) de \(aporte.usuario)? Esta acción no se puede deshacer.")
            }
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
                    
                    Text("Balance: \(mesInfo.saldoFinal.formatearComoMoneda())")
                        .font(.subheadline)
                        .foregroundStyle(mesInfo.saldoFinal >= 0 ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(mesInfo.cantidadTransacciones)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Text("transacciones")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Métricas principales
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                MetricaCard(titulo: "Aportado", valor: mesInfo.totalAportes, color: .green)
                MetricaCard(titulo: "Gastado", valor: mesInfo.totalGastos, color: .orange)
                MetricaCard(titulo: "Balance", valor: mesInfo.saldoFinal, color: mesInfo.saldoFinal >= 0 ? .green : .red)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        }
    }
    
    private var resumenFinancieroCompleto: some View {
        VStack(spacing: 16) {
            // Header de aportes
            HStack {
                Text("Aportes del Mes")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button("Ver Todo") {
                    mostrarVistaCompleta.toggle()
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
            
            // Lista de aportes
            VStack(spacing: 8) {
                let aportesAMostrar = mostrarVistaCompleta ? presupuestoViewModel.aportes : Array(presupuestoViewModel.aportes.prefix(3))
                
                ForEach(aportesAMostrar) { aporte in
                    AporteResumenRow(aporte: aporte) {
                        aporteAEliminar = aporte
                        mostrarAlertaEliminarAporte = true
                    }
                }
                
                if !mostrarVistaCompleta && presupuestoViewModel.aportes.count > 3 {
                    Button("Ver \(presupuestoViewModel.aportes.count - 3) más") {
                        mostrarVistaCompleta = true
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.regularMaterial)
        }
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
    
    // MARK: - Vista mejorada de Gastos del Mes
    
    private var gastosDelMesMejorado: some View {
        Group {
            HStack {
                Text("Gastos del Mes")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Selector de filtro
                Picker("Vista", selection: $vistaGastos) {
                    ForEach(VistaGastos.allCases, id: \.self) { vista in
                        Text(vista.rawValue).tag(vista)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if !presupuestoViewModel.deudasDelMes.isEmpty {
                VStack(spacing: 16) {
                    // Cards de resumen
                    resumenGastos
                    
                    // Lista de gastos filtrada
                    listaGastosFiltrada
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
    
    private var resumenGastos: some View {
        HStack(spacing: 12) {
            // Total general
            CardResumenGasto(
                titulo: "Total",
                monto: totalGastos,
                color: .blue,
                icono: "creditcard"
            )
            
            // Pagado
            CardResumenGasto(
                titulo: "Pagado",
                monto: totalPagado,
                color: .green,
                icono: "checkmark.circle.fill"
            )
            
            // Pendiente
            CardResumenGasto(
                titulo: "Pendiente",
                monto: totalPendiente,
                color: .orange,
                icono: "clock.fill"
            )
        }
    }
    
    private var listaGastosFiltrada: some View {
        VStack(spacing: 8) {
            ForEach(gastosFiltrados) { deuda in
                FilaActividadFinanciera(deuda: deuda)
            }
            
            if gastosFiltrados.count < deudasSegunFiltro.count {
                Button("Ver todos (\(deudasSegunFiltro.count) gastos)") {
                    // Expandir lista completa
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
    }
    
    // MARK: - Computed Properties para filtros
    private var deudasSegunFiltro: [DeudaItem] {
        switch vistaGastos {
        case .todos:
            return presupuestoViewModel.deudasDelMes
        case .pagados:
            return presupuestoViewModel.deudasDelMes.filter { $0.esPagado }
        case .pendientes:
            return presupuestoViewModel.deudasDelMes.filter { !$0.esPagado }
        }
    }
    
    private var gastosFiltrados: [DeudaItem] {
        Array(deudasSegunFiltro.prefix(5)) // Mostrar máximo 5 elementos
    }
    
    private var totalGastos: Double {
        presupuestoViewModel.deudasDelMes.reduce(0) { $0 + $1.monto }
    }
    
    private var totalPagado: Double {
        presupuestoViewModel.deudasDelMes.filter { $0.esPagado }.reduce(0) { $0 + $1.monto }
    }
    
    private var totalPendiente: Double {
        presupuestoViewModel.deudasDelMes.filter { !$0.esPagado }.reduce(0) { $0 + $1.monto }
    }
    
    // MARK: - Acciones
    
    private func eliminarAporte(_ aporte: Aporte) {
        presupuestoViewModel.eliminarAporte(id: aporte.id)
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

struct CardResumenGasto: View {
    let titulo: String
    let monto: Double
    let color: Color
    let icono: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icono)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(monto, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        }
    }
}

struct FilaActividadFinanciera: View {
    let deuda: DeudaItem
    
    var body: some View {
        HStack {
            // Icono de estado
            Image(systemName: deuda.esPagado ? "checkmark.circle.fill" : "clock.fill")
                .foregroundStyle(deuda.esPagado ? .green : .orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(deuda.descripcion)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !deuda.categoria.isEmpty {
                    Text(deuda.categoria)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(deuda.monto, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(deuda.esPagado ? "Pagado" : "Pendiente")
                    .font(.caption)
                    .foregroundStyle(deuda.esPagado ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AporteResumenRow: View {
    let aporte: Aporte
    let onEliminar: () -> Void
    
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
            
            Button(action: onEliminar) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .padding(.leading, 8)
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
