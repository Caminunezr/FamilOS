import SwiftUI

struct PresupuestoViewModerna: View {
    @EnvironmentObject var viewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var mostrarFormularioAporte = false
    @State private var mostrarFormularioDeuda = false
    @State private var mostrarFormularioAhorro = false
    @State private var mostrarDetalleDeuda = false
    @State private var deudaSeleccionada: DeudaItem?
    @State private var mostrarSelectorMes = false
    @State private var animarEntrada = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        // Selector de mes moderno
                        SelectorMesModerno(
                            mesSeleccionado: .constant(viewModel.mesSeleccionado),
                            cambiarMes: { avanzar in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.cambiarMes(avanzar: avanzar)
                                }
                            },
                            crearPresupuesto: {
                                Task {
                                    await viewModel.crearPresupuestoMes()
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                        
                        // Resumen financiero moderno
                        ResumenFinancieroModerno(
                            resumen: resumenFinanciero,
                            presupuesto: presupuestoActual,
                            isLoading: viewModel.isLoading
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        
                        // Estado del mes y acciones de cierre
                        EstadoMesModerno(
                            resumen: resumenFinanciero,
                            presupuesto: presupuestoActual,
                            onCerrarMes: {
                                Task {
                                    await viewModel.cerrarMes()
                                }
                            },
                            accionLoading: viewModel.isPerformingAction
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        
                        // Acciones rápidas modernas
                        AccionesRapidasModernas(
                            onAgregarAporte: {
                                mostrarFormularioAporte = true
                            },
                            onRegistrarDeuda: {
                                mostrarFormularioDeuda = true
                            },
                            onRegistrarAhorro: {
                                mostrarFormularioAhorro = true
                            },
                            onCerrarMes: {
                                Task {
                                    await viewModel.cerrarMes()
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                        
                        // Listado de transacciones moderno
                        ListadoTransaccionesModerno(
                            aportes: aportesFormateados,
                            gastos: gastosFormateados,
                            ahorros: ahorrosFormateados,
                            deudas: deudasFormateadas,
                            onEliminar: { id, tipo in
                                eliminarTransaccion(id: id, tipo: tipo)
                            },
                            onVerDetalle: { deuda in
                                deudaSeleccionada = deuda
                                mostrarDetalleDeuda = true
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        
                        // Gráficos (componente existente reutilizado)
                        if !viewModel.aportesDelMes.isEmpty || !viewModel.deudasDelMes.isEmpty {
                            GraficosPresupuestoView(viewModel: viewModel)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                                    removal: .scale(scale: 0.9).combined(with: .opacity)
                                ))
                        }
                        
                        // Espaciado final
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, geometry.size.width > 800 ? 40 : 20)
                    .padding(.vertical, 20)
                    .scaleEffect(animarEntrada ? 1.0 : 0.98)
                    .opacity(animarEntrada ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 1.0), value: animarEntrada)
                }
                .background {
                    // Fondo con gradiente sutil
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.05),
                            Color.primary.opacity(0.02),
                            Color.secondary.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }
            }
            .navigationTitle("Presupuesto Familiar")
            .toolbar {
                toolbarContent
            }
        }
        .sheet(isPresented: $mostrarFormularioAporte) {
            NuevoAporteView(viewModel: viewModel)
                .frame(width: 600, height: 750)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $mostrarFormularioDeuda) {
            NuevaDeudaView(viewModel: viewModel)
                .frame(width: 600, height: 750)
        }
        .sheet(isPresented: $mostrarFormularioAhorro) {
            NuevoAhorroView(viewModel: viewModel)
                .frame(width: 500, height: 600)
        }
        .sheet(isPresented: $mostrarDetalleDeuda) {
            if let deuda = deudaSeleccionada {
                DetalleDeudaView(deuda: deuda, viewModel: viewModel)
                    .frame(width: 700, height: 800)
            }
        }
        .onAppear {
            Task {
                await viewModel.cargarDatos()
                withAnimation(.easeOut(duration: 1.0)) {
                    animarEntrada = true
                }
            }
        }
        .refreshable {
            await viewModel.cargarDatos()
        }
    }
    
    // MARK: - Toolbar Content
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button(action: { mostrarFormularioAporte = true }) {
                    Label("Nuevo Aporte", systemImage: "plus.circle.fill")
                }
                
                Button(action: { mostrarFormularioDeuda = true }) {
                    Label("Nueva Deuda", systemImage: "creditcard.fill")
                }
                
                Button(action: { mostrarFormularioAhorro = true }) {
                    Label("Nuevo Ahorro", systemImage: "banknote.fill")
                }
                
                Divider()
                
                Button(action: {
                    Task {
                        await viewModel.cargarDatos()
                    }
                }) {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .menuStyle(.borderlessButton)
        }
        
        #if DEBUG
        ToolbarItem(placement: .secondaryAction) {
            Menu("Debug") {
                Button("Recargar Aportes") {
                    Task {
                        await viewModel.forzarRecargaAportes()
                    }
                }
                
                Button("Comparar con Firebase") {
                    Task {
                        await viewModel.compararAportesConFirebase()
                    }
                }
                
                Button("Simular Datos") {
                    Task {
                        await simularDatos()
                    }
                }
            }
        }
        #endif
    }
    
    // MARK: - Computed Properties
    
    private var resumenFinanciero: ResumenPresupuesto {
        ResumenPresupuesto(
            totalAportado: viewModel.totalAportes,
            totalGastado: viewModel.totalGastos,
            totalAhorrado: viewModel.totalAhorros,
            totalDeuda: viewModel.totalDeudasMensuales
        )
    }
    
    private var presupuestoActual: PresupuestoMensual? {
        return viewModel.presupuestoActual
    }
    
    private var aportesFormateados: [AporteItem] {
        viewModel.aportesDelMes.map { aporte in
            AporteItem(
                id: aporte.id,
                usuario: aporte.usuario,
                monto: aporte.monto,
                montoUtilizado: aporte.montoUtilizado,
                comentario: aporte.comentario,
                fecha: Date(timeIntervalSince1970: aporte.fecha)
            )
        }
    }
    
    private var gastosFormateados: [GastoItem] {
        // TODO: Implementar cuando se añada el soporte para gastos
        return []
    }
    
    private var ahorrosFormateados: [AhorroItem] {
        // TODO: Implementar cuando se añada el soporte para ahorros
        return []
    }
    
    private var deudasFormateadas: [DeudaItem] {
        viewModel.deudasDelMes.map { deuda in
            DeudaItem(
                id: deuda.id,
                descripcion: deuda.descripcion,
                monto: deuda.monto,
                categoria: deuda.categoria,
                fechaRegistro: deuda.fechaRegistro,
                esPagado: deuda.esPagado,
                responsable: deuda.responsable
            )
        }
    }
    
    // MARK: - Actions
    
    private func eliminarTransaccion(id: String, tipo: TipoTransaccion) {
        switch tipo {
        case .aporte:
            viewModel.eliminarAporte(id: id)
        case .gasto:
            Task {
                await viewModel.eliminarGasto(id)
            }
        case .ahorro:
            Task {
                await viewModel.eliminarAhorro(id)
            }
        case .deuda:
            viewModel.eliminarDeuda(id: id)
        case .pago:
            // TODO: Implementar eliminación de pagos
            print("⚠️ Eliminación de pagos no implementada")
        }
    }
    
    #if DEBUG
    private func simularDatos() async {
        // Simular algunos aportes
        let aportes = [
            ("Juan Pérez", 800000.0, "Sueldo mensual"),
            ("María García", 600000.0, "Trabajo freelance"),
            ("Pedro López", 200000.0, "Bono extra")
        ]
        
        for (nombre, monto, _) in aportes {
            // Aquí simularías la creación de aportes
            print("Simulando aporte: \(nombre) - \(monto)")
        }
        
        await viewModel.cargarDatos()
    }
    #endif
}

// MARK: - Supporting Views

// Las vistas NuevoAhorroView, GraficosPresupuestoView, NuevoAporteView, y NuevaDeudaView
// están implementadas en archivos separados en Components/PresupuestoModerno/

struct DetalleDeudaView: View {
    let deuda: DeudaItem
    let viewModel: PresupuestoViewModel
    
    var body: some View {
        VStack {
            Text("Detalle de Deuda")
                .font(.title2)
                .padding()
            
            // Detalle de la deuda aquí
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

#Preview {
    PresupuestoViewModerna()
        .environmentObject(PresupuestoViewModel())
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}
