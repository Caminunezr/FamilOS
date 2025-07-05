import SwiftUI
import Combine

@MainActor
class CalendarioPresupuestoViewModel: ObservableObject {
    @Published var mesesInfo: [MesPresupuestoInfo] = []
    @Published var isLoading = false
    @Published var añoActual: Int = Calendar.current.component(.year, from: Date())
    @Published var errorMessage: String?
    
    var presupuestoViewModel: PresupuestoViewModel?
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties para resumen anual
    var totalAportadoAño: Double {
        mesesInfo.reduce(0) { $0 + $1.totalAportes }
    }
    
    var totalGastadoAño: Double {
        mesesInfo.reduce(0) { $0 + $1.totalGastos }
    }
    
    var balanceAño: Double {
        totalAportadoAño - totalGastadoAño
    }
    
    var mesesConPresupuesto: Int {
        mesesInfo.filter { $0.tienePresupuesto }.count
    }
    
    var mesesCerrados: Int {
        mesesInfo.filter { $0.estaCerrado }.count
    }
    
    func configurar(presupuestoViewModel: PresupuestoViewModel) {
        self.presupuestoViewModel = presupuestoViewModel
        
        // Observar cambios en el PresupuestoViewModel
        presupuestoViewModel.$presupuestos
            .combineLatest(
                presupuestoViewModel.$aportes,
                presupuestoViewModel.$deudas
            )
            .sink { [weak self] _, _, _ in
                Task { @MainActor in
                    self?.actualizarDatos()
                }
            }
            .store(in: &cancellables)
        
        // Cargar datos iniciales
        cargarDatosAño(añoActual)
    }
    
    func cargarDatosAño(_ año: Int) {
        añoActual = año
        actualizarDatos()
    }
    
    func recargarDatos() async {
        isLoading = true
        await presupuestoViewModel?.cargarDatos()
        actualizarDatos()
    }
    
    private func actualizarDatos() {
        guard let presupuestoViewModel = presupuestoViewModel else {
            print("⚠️ PresupuestoViewModel no está configurado")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var mesesTemp: [MesPresupuestoInfo] = []
                
                for mes in 1...12 {
                    let fechaMes = crearFechaMes(año: añoActual, mes: mes)
                    let mesInfo = await crearMesInfo(
                        fecha: fechaMes,
                        mes: mes,
                        año: añoActual,
                        presupuestos: presupuestoViewModel.presupuestos,
                        aportes: presupuestoViewModel.aportes,
                        deudas: presupuestoViewModel.deudas
                    )
                    mesesTemp.append(mesInfo)
                }
                
                await MainActor.run {
                    self.mesesInfo = mesesTemp
                    self.isLoading = false
                }
                
                print("✅ Datos del calendario actualizados para el año \(añoActual)")
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Error al cargar datos: \(error.localizedDescription)"
                    self.isLoading = false
                }
                print("❌ Error actualizando datos del calendario: \(error)")
            }
        }
    }
    
    private func crearFechaMes(año: Int, mes: Int) -> Date {
        let calendar = Calendar.current
        let components = DateComponents(year: año, month: mes, day: 1)
        return calendar.date(from: components) ?? Date()
    }
    
    private func crearMesInfo(
        fecha: Date,
        mes: Int,
        año: Int,
        presupuestos: [PresupuestoMensual],
        aportes: [Aporte],
        deudas: [DeudaItem]
    ) async -> MesPresupuestoInfo {
        let calendar = Calendar.current
        
        // Encontrar presupuesto del mes
        let presupuesto = presupuestos.first { p in
            calendar.isDate(p.fechaMes, equalTo: fecha, toGranularity: .month)
        }
        
        // Aportes del mes
        let aportesDelMes = aportes.filter { a in
            guard let presupuesto = presupuesto else { return false }
            return a.presupuestoId == presupuesto.id
        }
        
        // Deudas del mes - usar fecha de deuda en lugar de presupuesto
        let deudasDelMes = deudas.filter { d in
            calendar.isDate(d.fechaRegistro, equalTo: fecha, toGranularity: .month)
        }
        
        // Calcular totales
        let totalAportes = aportesDelMes.reduce(0) { $0 + $1.monto }
        let totalGastos = deudasDelMes.reduce(0) { $0 + $1.monto }
        let saldoDisponible = aportesDelMes.reduce(0) { $0 + $1.saldoDisponible }
        
        // Generar alertas
        let alertas = generarAlertasDelMes(
            presupuesto: presupuesto,
            aportes: aportesDelMes,
            deudas: deudasDelMes,
            totalAportes: totalAportes,
            totalGastos: totalGastos,
            saldoDisponible: saldoDisponible
        )
        
        return MesPresupuestoInfo(
            mes: mes,
            año: año,
            fecha: fecha,
            nombre: mes.nombreMes(),
            presupuesto: presupuesto,
            totalAportes: totalAportes,
            totalGastos: totalGastos,
            saldoDisponible: saldoDisponible,
            cantidadTransacciones: deudasDelMes.count,
            estaCerrado: presupuesto?.cerrado ?? false,
            alertas: alertas
        )
    }
    
    private func generarAlertasDelMes(
        presupuesto: PresupuestoMensual?,
        aportes: [Aporte],
        deudas: [DeudaItem],
        totalAportes: Double,
        totalGastos: Double,
        saldoDisponible: Double
    ) -> [AlertaFinancieraCalendario] {
        var alertas: [AlertaFinancieraCalendario] = []
        
        // Alerta de saldo bajo
        if saldoDisponible < 10000 && saldoDisponible > 0 {
            alertas.append(AlertaFinancieraCalendario(
                tipo: .saldoBajo,
                mensaje: "Saldo bajo disponible",
                color: .orange,
                icono: "exclamationmark.triangle.fill"
            ))
        }
        
        // Alerta sin aportes
        if aportes.isEmpty && presupuesto != nil && !presupuesto!.cerrado {
            alertas.append(AlertaFinancieraCalendario(
                tipo: .sinAportes,
                mensaje: "No hay aportes registrados",
                color: .red,
                icono: "minus.circle.fill"
            ))
        }
        
        // Alerta presupuesto excedido
        if totalGastos > totalAportes && totalAportes > 0 {
            alertas.append(AlertaFinancieraCalendario(
                tipo: .excedido,
                mensaje: "Presupuesto excedido",
                color: .red,
                icono: "arrow.up.circle.fill"
            ))
        }
        
        // Alerta sin gastos (solo para meses con presupuesto activo)
        if deudas.isEmpty && presupuesto != nil && !presupuesto!.cerrado && !aportes.isEmpty {
            alertas.append(AlertaFinancieraCalendario(
                tipo: .sinGastos,
                mensaje: "No hay gastos registrados",
                color: .blue,
                icono: "info.circle.fill"
            ))
        }
        
        return alertas
    }
    
    func exportarDatosAño(_ año: Int) {
        // TODO: Implementar exportación de datos
        print("📤 Exportando datos del año \(año)")
        // Aquí se podría implementar la exportación a CSV, PDF, etc.
    }
    
    func obtenerMesInfo(para fecha: Date) -> MesPresupuestoInfo? {
        return mesesInfo.first { mesInfo in
            Calendar.current.isDate(mesInfo.fecha, equalTo: fecha, toGranularity: .month)
        }
    }
    
    func navegarAMes(_ mesInfo: MesPresupuestoInfo) {
        // Actualizar el mes seleccionado en el PresupuestoViewModel
        presupuestoViewModel?.mesSeleccionado = mesInfo.fecha
    }
}
