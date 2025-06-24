import Foundation
import SwiftUI
import Combine

class PresupuestoViewModel: ObservableObject {
    @Published var presupuestos: [PresupuestoMensual] = []
    @Published var aportes: [Aporte] = []
    @Published var deudas: [DeudaPresupuesto] = []
    @Published var mesSeleccionado: Date = Date()
    @Published var mostrarMesesAnteriores: Bool = false
    
    // Propiedades calculadas
    var presupuestoActual: PresupuestoMensual? {
        let calendar = Calendar.current
        return presupuestos.first(where: { presupuesto in
            return calendar.isDate(presupuesto.fechaMes, equalTo: mesSeleccionado, toGranularity: .month)
        })
    }
    
    var aportesDelMes: [Aporte] {
        guard let presupuesto = presupuestoActual else { return [] }
        return aportes.filter { $0.presupuestoId == presupuesto.id }
    }
    
    var deudasDelMes: [DeudaPresupuesto] {
        guard let presupuesto = presupuestoActual else { return [] }
        return deudas.filter { $0.presupuestoId == presupuesto.id }
    }
    
    var totalAportes: Double {
        return aportesDelMes.reduce(0) { $0 + $1.monto }
    }
    
    var totalDeudasMensuales: Double {
        return deudasDelMes.reduce(0) { $0 + $1.montoCuotaMensual }
    }
    
    var saldoDisponible: Double {
        return totalAportes - totalDeudasMensuales + (presupuestoActual?.sobranteTransferido ?? 0)
    }
    
    // MARK: - Métodos de carga de datos
    
    func cargarDatosEjemplo() {
        let calendar = Calendar.current
        let hoy = Date()
        
        // Crear presupuestos para los últimos 3 meses
        for i in 0...2 {
            if let fecha = calendar.date(byAdding: .month, value: -i, to: hoy) {
                let presupuesto = PresupuestoMensual(
                    fechaMes: fecha,
                    creador: "Usuario",
                    cerrado: i > 0,  // Solo el mes actual está abierto
                    sobranteTransferido: i == 0 ? 1500.0 : 0.0  // El mes actual tiene un sobrante transferido
                )
                presupuestos.append(presupuesto)
                
                // Agregar aportes para este presupuesto
                let aporte1 = Aporte(
                    presupuestoId: presupuesto.id,
                    usuario: "Usuario Principal",
                    monto: 15000.0,
                    comentario: "Sueldo mensual"
                )
                
                let aporte2 = Aporte(
                    presupuestoId: presupuesto.id,
                    usuario: "Usuario Secundario",
                    monto: 8000.0,
                    comentario: "Aporte familiar"
                )
                
                aportes.append(contentsOf: [aporte1, aporte2])
                
                // Agregar deudas para el presupuesto actual
                if i == 0 {
                    let deuda1 = DeudaPresupuesto(
                        presupuestoId: presupuesto.id,
                        categoria: "Préstamo Hipotecario",
                        montoTotal: 120000.0,
                        cuotasTotales: 12,
                        tasaInteres: 5.5,
                        fechaInicio: fecha,
                        descripcion: "Préstamo para renovación de cocina"
                    )
                    
                    let deuda2 = DeudaPresupuesto(
                        presupuestoId: presupuesto.id,
                        categoria: "Servicios",
                        montoTotal: 5000.0,
                        cuotasTotales: 1,
                        tasaInteres: 0.0,
                        fechaInicio: fecha,
                        descripcion: "Gastos fijos mensuales"
                    )
                    
                    deudas.append(contentsOf: [deuda1, deuda2])
                }
            }
        }
    }
    
    // MARK: - Métodos de gestión
    
    func agregarAporte(_ aporte: Aporte) {
        aportes.append(aporte)
        objectWillChange.send()
    }
    
    func agregarDeuda(_ deuda: DeudaPresupuesto) {
        deudas.append(deuda)
        objectWillChange.send()
    }
    
    func eliminarAporte(id: UUID) {
        aportes.removeAll(where: { $0.id == id })
        objectWillChange.send()
    }
    
    func eliminarDeuda(id: UUID) {
        deudas.removeAll(where: { $0.id == id })
        objectWillChange.send()
    }
    
    func transferirSobrante() {
        guard let presupuestoActual = presupuestoActual,
              let siguienteIndex = presupuestos.firstIndex(where: { $0.id == presupuestoActual.id })?.advanced(by: 1),
              siguienteIndex < presupuestos.count else {
            // Crear nuevo presupuesto para el próximo mes
            let calendar = Calendar.current
            if let siguienteMes = calendar.date(byAdding: .month, value: 1, to: mesSeleccionado) {
                var nuevoPresupuesto = PresupuestoMensual(
                    fechaMes: siguienteMes,
                    creador: "Usuario",
                    cerrado: false,
                    sobranteTransferido: saldoDisponible > 0 ? saldoDisponible : 0
                )
                presupuestos.append(nuevoPresupuesto)
            }
            return
        }
        
        // Actualizar el sobrante transferido al siguiente mes
        presupuestos[siguienteIndex].sobranteTransferido += saldoDisponible > 0 ? saldoDisponible : 0
        
        // Cerrar el presupuesto actual
        if let index = presupuestos.firstIndex(where: { $0.id == presupuestoActual.id }) {
            presupuestos[index].cerrado = true
        }
        
        objectWillChange.send()
    }
    
    func cambiarMes(avanzar: Bool) {
        let calendar = Calendar.current
        if let nuevaFecha = calendar.date(byAdding: .month, value: avanzar ? 1 : -1, to: mesSeleccionado) {
            mesSeleccionado = nuevaFecha
        }
    }
    
    // MARK: - Datos para gráficos
    
    func datosGraficoAportes() -> [(String, Double)] {
        var datos: [(String, Double)] = []
        let aportesAgrupados = Dictionary(grouping: aportesDelMes, by: { $0.usuario })
        
        for (usuario, aportes) in aportesAgrupados {
            let total = aportes.reduce(0) { $0 + $1.monto }
            datos.append((usuario, total))
        }
        
        return datos
    }
    
    func datosGraficoGastos() -> [(String, Double)] {
        var datos: [(String, Double)] = []
        let deudasAgrupadas = Dictionary(grouping: deudasDelMes, by: { $0.categoria })
        
        for (categoria, deudas) in deudasAgrupadas {
            let total = deudas.reduce(0) { $0 + $1.montoCuotaMensual }
            datos.append((categoria, total))
        }
        
        return datos
    }
}