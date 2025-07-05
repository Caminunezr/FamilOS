import SwiftUI

struct CalendarioPresupuestoView: View {
    @StateObject private var viewModel = CalendarioPresupuestoViewModel()
    @EnvironmentObject var presupuestoViewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var mesSeleccionado: MesPresupuestoInfo?
    @State private var mostrarDetalleMes = false
    @State private var mostrarEstadisticas = false
    @State private var vistaActual: VistaPresupuesto = .calendario
    
    enum VistaPresupuesto: String, CaseIterable {
        case calendario = "Calendario"
        case mensual = "Mensual"
        case moderna = "Moderna"
        
        var icono: String {
            switch self {
            case .calendario: return "calendar"
            case .mensual: return "list.bullet"
            case .moderna: return "rectangle.grid.2x2"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header con selector de vista
                headerView
                
                // Contenido principal
                contenidoPrincipal
            }
            .navigationTitle("Presupuesto Familiar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if vistaActual == .calendario {
                            Button("📊 Estadísticas del Año") {
                                mostrarEstadisticas = true
                            }
                            
                            Button("💰 Crear Presupuesto Rápido") {
                                crearPresupuestoRapido()
                            }
                            
                            Divider()
                            
                            Button("📤 Exportar Datos del Año") {
                                exportarDatosAño()
                            }
                        } else {
                            Button("💰 Nuevo Aporte") {
                                // Acción para nuevo aporte en vista mensual
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $mostrarDetalleMes) {
            if let mes = mesSeleccionado {
                DetallePresupuestoModal(mesInfo: mes)
                    .environmentObject(presupuestoViewModel)
                    .environmentObject(authViewModel)
                    .frame(width: 900, height: 800)
            }
        }
        .sheet(isPresented: $mostrarEstadisticas) {
            EstadisticasAnualesView(año: viewModel.añoActual)
                .environmentObject(presupuestoViewModel)
                .frame(width: 1000, height: 900)
        }
        .onAppear {
            configurarViewModel()
        }
        .onChange(of: presupuestoViewModel.mesSeleccionado) { _, nuevoMes in
            // Sincronizar con cambios externos del mes seleccionado
            if vistaActual != .calendario {
                sincronizarMesSeleccionado(nuevoMes)
            }
        }
    }
    
    // MARK: - Subvistas
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Selector de vista
            Picker("Vista", selection: $vistaActual) {
                ForEach(VistaPresupuesto.allCases, id: \.self) { vista in
                    Label(vista.rawValue, systemImage: vista.icono)
                        .tag(vista)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Selector de año (solo para vista calendario)
            if vistaActual == .calendario {
                SelectorAñoView(
                    añoSeleccionado: $viewModel.añoActual,
                    onCambioAño: { nuevoAño in
                        viewModel.cargarDatosAño(nuevoAño)
                    }
                )
            }
        }
        .padding(.vertical)
        .background(.regularMaterial)
    }
    
    private var contenidoPrincipal: some View {
        Group {
            switch vistaActual {
            case .calendario:
                calendarioView
            case .mensual:
                PresupuestoView()
                    .environmentObject(presupuestoViewModel)
                    .environmentObject(authViewModel)
            case .moderna:
                PresupuestoViewModerna()
                    .environmentObject(presupuestoViewModel)
                    .environmentObject(authViewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: vistaActual)
    }
    
    private var calendarioView: some View {
        Group {
            if viewModel.isLoading {
                CalendarioLoadingView()
            } else if let errorMessage = viewModel.errorMessage {
                CalendarioErrorView(
                    mensaje: errorMessage,
                    onReintentar: {
                        Task {
                            await viewModel.recargarDatos()
                        }
                    }
                )
            } else {
                contenidoCalendario
            }
        }
    }
    
    private var contenidoCalendario: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Resumen del año
                resumenAnualView
                
                // Estadísticas rápidas
                EstadisticasRapidasView(
                    mesesConPresupuesto: viewModel.mesesConPresupuesto,
                    mesesCerrados: viewModel.mesesCerrados
                )
                .padding(.horizontal, 20)
                
                // Grid de meses
                LazyVGrid(columns: crearColumnas(), spacing: 16) {
                    ForEach(viewModel.mesesInfo) { mesInfo in
                        TarjetaMesView(
                            mesInfo: mesInfo,
                            esMesActual: esMesActual(mesInfo),
                            onTap: {
                                mesSeleccionado = mesInfo
                                mostrarDetalleMes = true
                            }
                        )
                        .animation(.spring(response: 0.5), value: mesInfo)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.recargarDatos()
        }
    }
    
    private var resumenAnualView: some View {
        VStack(spacing: 16) {
            Text("Resumen \(viewModel.añoActual)")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                ResumenMetricaCard(
                    titulo: "Total Aportado",
                    valor: viewModel.totalAportadoAño,
                    color: .green,
                    icono: "plus.circle.fill"
                )
                
                ResumenMetricaCard(
                    titulo: "Total Gastado",
                    valor: viewModel.totalGastadoAño,
                    color: .orange,
                    icono: "minus.circle.fill"
                )
                
                ResumenMetricaCard(
                    titulo: "Balance Final",
                    valor: viewModel.balanceAño,
                    color: viewModel.balanceAño >= 0 ? .blue : .red,
                    icono: viewModel.balanceAño >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Funciones auxiliares
    
    private func configurarViewModel() {
        if viewModel.presupuestoViewModel == nil {
            viewModel.configurar(presupuestoViewModel: presupuestoViewModel)
        }
    }
    
    private func crearColumnas() -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    }
    
    private func esMesActual(_ mesInfo: MesPresupuestoInfo) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.isDate(mesInfo.fecha, equalTo: now, toGranularity: .month)
    }
    
    private func sincronizarMesSeleccionado(_ fecha: Date) {
        if viewModel.obtenerMesInfo(para: fecha) != nil {
            // Actualizar el año si es necesario
            let añoMes = Calendar.current.component(.year, from: fecha)
            if añoMes != viewModel.añoActual {
                viewModel.cargarDatosAño(añoMes)
            }
        }
    }
    
    private func crearPresupuestoRapido() {
        Task {
            await presupuestoViewModel.crearPresupuestoMes()
        }
    }
    
    private func exportarDatosAño() {
        viewModel.exportarDatosAño(viewModel.añoActual)
    }
}

// MARK: - Vista temporal para estadísticas anuales

struct EstadisticasAnualesView: View {
    let año: Int
    @EnvironmentObject var presupuestoViewModel: PresupuestoViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Estadísticas de \(año)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Vista detallada de estadísticas anuales")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // TODO: Implementar gráficos y estadísticas detalladas
                    
                    Spacer(minLength: 200)
                }
                .padding()
            }
            .navigationTitle("Estadísticas \(año)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarioPresupuestoView()
        .environmentObject(PresupuestoViewModel())
        .environmentObject(AuthViewModel())
}
