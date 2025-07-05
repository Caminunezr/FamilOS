import Foundation
import SwiftUI
import Combine
import FirebaseDatabase

// MARK: - Estructuras para el cruce de datos
struct CategoriaPresupuestoAnalisis: Identifiable {
    let id = UUID().uuidString
    let nombre: String
    let icon: String
    let presupuestoMensual: Double
    let gastoActual: Double
    let gastoProyectado: Double
    let porcentajeUsado: Double
    let estado: EstadoPresupuesto
    let cuentasPendientes: Int
    let cuentasPagadas: Int
    
    var diferencia: Double {
        presupuestoMensual - gastoActual
    }
    
    var proyeccionFinal: Double {
        gastoActual + gastoProyectado
    }
    
    var excedeProyeccion: Bool {
        proyeccionFinal > presupuestoMensual
    }
}

enum EstadoPresupuesto: CaseIterable {
    case enRango        // < 70% del presupuesto
    case atencion       // 70-90% del presupuesto
    case cerca          // 90-100% del presupuesto
    case excedido       // > 100% del presupuesto
    case sinPresupuesto // No hay límite definido
    
    var color: Color {
        switch self {
        case .enRango: return .green
        case .atencion: return .yellow
        case .cerca: return .orange
        case .excedido: return .red
        case .sinPresupuesto: return .gray
        }
    }
    
    var mensaje: String {
        switch self {
        case .enRango: return "En rango"
        case .atencion: return "Atención"
        case .cerca: return "Cerca del límite"
        case .excedido: return "Excedido"
        case .sinPresupuesto: return "Sin presupuesto"
        }
    }
    
    var icono: String {
        switch self {
        case .enRango: return "checkmark.circle.fill"
        case .atencion: return "exclamationmark.triangle.fill"
        case .cerca: return "exclamationmark.triangle.fill"
        case .excedido: return "xmark.circle.fill"
        case .sinPresupuesto: return "questionmark.circle.fill"
        }
    }
}

struct ResumenFinancieroIntegrado {
    let presupuestoTotal: Double
    let gastoActual: Double
    let gastoProyectado: Double
    let disponible: Double
    let porcentajeUsado: Double
    let categorias: [CategoriaPresupuestoAnalisis]
    let alertas: [AlertaFinanciera]
    
    var excedePresupuesto: Bool {
        gastoActual > presupuestoTotal
    }
    
    var proyeccionExcede: Bool {
        (gastoActual + gastoProyectado) > presupuestoTotal
    }
}

struct AlertaFinanciera: Identifiable {
    let id = UUID().uuidString
    let tipo: TipoAlerta
    let mensaje: String
    let categoria: String?
    let urgencia: NivelUrgencia
}

enum TipoAlerta {
    case presupuestoExcedido
    case cercaDelLimite
    case proyeccionExcede
    case sinPresupuesto
    case vencimientoProximo
}

enum NivelUrgencia {
    case bajo, medio, alto, critico
    
    var color: Color {
        switch self {
        case .bajo: return .blue
        case .medio: return .yellow
        case .alto: return .orange
        case .critico: return .red
        }
    }
}

// MARK: - PresupuestoViewModel
@MainActor
class PresupuestoViewModel: ObservableObject {
    @Published var presupuestos: [PresupuestoMensual] = []
    @Published var aportes: [Aporte] = []
    @Published var deudas: [DeudaItem] = []
    @Published var mesSeleccionado: Date = Date()
    @Published var mostrarMesesAnteriores: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isPerformingAction: Bool = false
    
    // MARK: - Nuevas propiedades para integración con cuentas
    @Published var presupuestosPorCategoria: [String: Double] = [:]
    private var cuentasViewModel: CuentasViewModel?
    private var authViewModel: AuthViewModel?
    let firebaseService = FirebaseService() // Cambiado a público para acceso desde vistas
    var familiaId: String? // Cambiado a público para acceso desde vistas
    
    // MARK: - Propiedades para observadores en tiempo real
    private var observadorAportesHandle: DatabaseHandle?
    private var observadorDeudasHandle: DatabaseHandle?
    private var observadorPresupuestosHandle: DatabaseHandle?
    
    // MARK: - Configuración
    
    func configurarFamilia(_ familiaId: String) {
        self.familiaId = familiaId
        iniciarObservadores()
    }
    
    // MARK: - Configuración de integración con cuentas
    func configurarIntegracionCuentas(_ cuentasVM: CuentasViewModel) {
        self.cuentasViewModel = cuentasVM
        print("🔗 INTEGRACIÓN CONFIGURADA:")
        print("   - PresupuestoViewModel conectado con CuentasViewModel")
        print("   - FamiliaId PresupuestoViewModel: \(familiaId ?? "nil")")
        print("   - FamiliaId CuentasViewModel: \(cuentasVM.familiaIdActual ?? "nil")")
        
        // Verificar que ambos ViewModels tengan la misma familia
        if let presupuestoFamiliaId = familiaId, let cuentasFamiliaId = cuentasVM.familiaIdActual {
            if presupuestoFamiliaId == cuentasFamiliaId {
                print("✅ Ambos ViewModels están configurados para la misma familia")
            } else {
                print("⚠️ Los ViewModels están configurados para familias diferentes")
                print("   - PresupuestoViewModel: \(presupuestoFamiliaId)")
                print("   - CuentasViewModel: \(cuentasFamiliaId)")
            }
        }
    }
    
    func configurarAuth(_ authVM: AuthViewModel) {
        self.authViewModel = authVM
    }
    
    // MARK: - Carga de datos familiares
    
    func cargarDatosFamiliares() {
        // Este método ahora solo inicia los observadores si no están ya iniciados
        guard let familiaId = familiaId else { return }
        
        if observadorAportesHandle == nil {
            iniciarObservadores()
        }
    }

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
    
    var deudasDelMes: [DeudaItem] {
        guard let presupuesto = presupuestoActual else { return [] }
        // DeudaItem no tiene presupuestoId, por lo que filtramos por el mes
        let calendar = Calendar.current
        return deudas.filter { deuda in
            calendar.isDate(deuda.fechaRegistro, equalTo: presupuesto.fechaMes, toGranularity: .month)
        }
    }
    
    var totalAportes: Double {
        return aportesDelMes.reduce(into: 0.0) { result, aporte in
            result += aporte.monto
        }
    }
    
    var totalDeudasMensuales: Double {
        return deudasDelMes.reduce(into: 0.0) { result, deuda in
            result += deuda.monto
        }
    }
    
    var saldoDisponible: Double {
        return totalAportes - totalDeudasMensuales + (presupuestoActual?.sobranteTransferido ?? 0)
    }
    
    // MARK: - Métodos de verificación y logging mejorados
    
    /// Verificar la integración con CuentasViewModel
    func verificarIntegracionCuentas() {
        print("🔍 Verificando integración con CuentasViewModel:")
        
        if let cuentasVM = cuentasViewModel {
            print("   ✅ CuentasViewModel configurado")
            print("   📊 Familia en PresupuestoVM: \(familiaId ?? "nil")")
            print("   📊 Familia en CuentasVM: \(cuentasVM.familiaIdActual ?? "nil")")
            
            if let familiaIdPresupuesto = familiaId,
               let familiaIdCuentas = cuentasVM.familiaIdActual {
                if familiaIdPresupuesto == familiaIdCuentas {
                    print("   ✅ IDs de familia coinciden")
                } else {
                    print("   ❌ IDs de familia NO coinciden")
                }
            } else {
                print("   ⚠️ Una o ambas familias no están configuradas")
            }
            
            print("   📱 Cuentas cargadas: \(cuentasVM.cuentas.count)")
        } else {
            print("   ❌ CuentasViewModel NO configurado")
        }
        
        print("   💰 Aportes cargados: \(aportes.count)")
        print("   💰 Saldo total disponible: \(saldoTotalDisponible)")
    }
    
    /// Logging detallado del proceso de pago con aportes
    func logProcesoPago(cuenta: Cuenta, distribucion: [(aporteId: String, montoAUsar: Double)]) {
        print("\n💳 === INICIO PROCESO DE PAGO ===")
        print("📄 Cuenta: \(cuenta.nombre)")
        print("💰 Monto: \(cuenta.monto)")
        print("📂 Categoría: \(cuenta.categoria)")
        print("🗓 Fecha vencimiento: \(cuenta.fechaVencimiento)")
        
        print("\n🔍 Estado de aportes ANTES del pago:")
        for aporte in aportes {
            print("   - \(aporte.usuario): \(aporte.saldoDisponible) disponible (\(aporte.montoUtilizado) usado de \(aporte.monto))")
        }
        
        print("\n📋 Distribución solicitada:")
        for (aporteId, montoAUsar) in distribucion {
            if let aporte = aportes.first(where: { $0.id == aporteId }) {
                print("   - \(aporte.usuario): usar \(montoAUsar) de \(aporte.saldoDisponible) disponible")
            } else {
                print("   - Aporte \(aporteId): NO ENCONTRADO")
            }
        }
        
        let totalDistribucion = distribucion.reduce(0) { $0 + $1.montoAUsar }
        print("📊 Total distribución: \(totalDistribucion)")
        print("📊 Diferencia con cuenta: \(totalDistribucion - cuenta.monto)")
        print("💳 === FIN LOGGING INICIAL ===\n")
    }
    
    /// Logging después del pago
    func logResultadoPago(exito: Bool, error: Error?) {
        print("\n💳 === RESULTADO DEL PAGO ===")
        if exito {
            print("✅ Pago procesado exitosamente")
            print("\n🔍 Estado de aportes DESPUÉS del pago:")
            for aporte in aportes {
                print("   - \(aporte.usuario): \(aporte.saldoDisponible) disponible (\(aporte.montoUtilizado) usado de \(aporte.monto))")
            }
            print("📊 Saldo total disponible: \(saldoTotalDisponible)")
        } else {
            print("❌ Error procesando pago: \(error?.localizedDescription ?? "Error desconocido")")
        }
        print("💳 === FIN RESULTADO PAGO ===\n")
    }
    
    /// Verificar consistencia de datos después de operaciones
    func verificarConsistenciaDatos() async {
        print("🔍 Verificando consistencia de datos...")
        
        // Comparar con Firebase
        await compararAportesConFirebase()
        
        // Verificar cálculos
        print("📊 Verificación de cálculos:")
        print("   - Total aportes: \(totalAportes)")
        print("   - Saldo disponible: \(saldoTotalDisponible)")
        print("   - Diferencia: \(totalAportes - saldoDisponible)")
        
        // Verificar cada aporte individualmente
        for aporte in aportes {
            let calculoSaldo = aporte.monto - aporte.montoUtilizado
            if abs(calculoSaldo - aporte.saldoDisponible) > 0.01 {
                print("   ⚠️ Inconsistencia en aporte de \(aporte.usuario):")
                print("      Saldo reportado: \(aporte.saldoDisponible)")
                print("      Saldo calculado: \(calculoSaldo)")
            }
        }
    }
    
    // MARK: - Métodos de gestión de presupuestos
    
    func crearPresupuestoMensual(_ presupuesto: PresupuestoMensual) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.crearPresupuesto(presupuesto, familiaId: familiaId)
                await MainActor.run {
                    self.isLoading = false
                    // Los observadores actualizarán automáticamente los datos
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al crear presupuesto: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Métodos para creación de presupuestos

    func crearPresupuestoMes() async {
        guard let usuario = authViewModel?.usuarioActual?.nombre else { return }
        
        let calendar = Calendar.current
        let nuevoPresupuesto = PresupuestoMensual(
            fechaMes: mesSeleccionado,
            creador: usuario,
            cerrado: false,
            sobranteTransferido: 0
        )
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            guard let familiaId = familiaId else { 
                throw NSError(domain: "PresupuestoViewModel", code: 100, 
                             userInfo: [NSLocalizedDescriptionKey: "No hay una familia configurada"])
            }
            
            try await firebaseService.crearPresupuesto(nuevoPresupuesto, familiaId: familiaId)
            print("✅ Presupuesto creado para \(nuevoPresupuesto.nombreMes)")
            
            // El observador actualizará los datos automáticamente
        } catch {
            await MainActor.run {
                self.error = "Error al crear presupuesto: \(error.localizedDescription)"
                print("❌ Error creando presupuesto: \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func agregarAporte(_ aporte: Aporte) {
        guard let familiaId = familiaId else { 
            print("❌ Error: familiaId es nil en agregarAporte")
            return 
        }
        
        print("📊 Iniciando agregarAporte:")
        print("   - FamiliaId: \(familiaId)")
        print("   - Aporte: \(aporte)")
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.crearAporte(aporte, familiaId: familiaId)
                await MainActor.run {
                    self.isLoading = false
                    print("✅ Aporte agregado exitosamente")
                    // Los observadores actualizarán automáticamente los datos
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al agregar aporte: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Firebase Error en agregarAporte:")
                    print("   - Descripción: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("   - Código: \(nsError.code)")
                        print("   - Dominio: \(nsError.domain)")
                        print("   - UserInfo: \(nsError.userInfo)")
                    }
                }
            }
        }
    }
    
    func agregarDeuda(_ deuda: DeudaItem) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.crearDeuda(deuda, familiaId: familiaId)
                await MainActor.run {
                    self.isLoading = false
                    // Los observadores actualizarán automáticamente los datos
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al agregar deuda: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func actualizarDeuda(_ deuda: DeudaItem) {
        guard let familiaId = familiaId else { return }
        
        Task {
            do {
                try await firebaseService.actualizarDeuda(deuda, familiaId: familiaId)
                // Los observadores actualizarán automáticamente los datos
            } catch {
                await MainActor.run {
                    self.error = "Error al actualizar deuda: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func eliminarDeuda(_ deudaId: String) {
        guard let familiaId = familiaId else { return }
        
        Task {
            do {
                try await firebaseService.eliminarDeuda(deudaId: deudaId, familiaId: familiaId)
                // Los observadores actualizarán automáticamente los datos
            } catch {
                self.error = "Error al eliminar deuda: \(error.localizedDescription)"
            }
        }
    }
    
    private func cargarAportes(presupuestoId: String) async {
        guard let familiaId = familiaId else { return }
        
        do {
            let aportesObtenidos = try await firebaseService.obtenerAportesFamilia(familiaId: familiaId)
            self.aportes = aportesObtenidos
        } catch {
            self.error = "Error al cargar aportes: \(error.localizedDescription)"
        }
    }
    
    func eliminarAporte(id: String) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.eliminarAporte(aporteId: id, familiaId: familiaId)
                await MainActor.run {
                    self.isLoading = false
                    // Los observadores actualizarán automáticamente los datos
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al eliminar aporte: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func eliminarDeuda(id: String) {
        guard let familiaId = familiaId else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                try await firebaseService.eliminarDeuda(deudaId: id, familiaId: familiaId)
                await MainActor.run {
                    self.isLoading = false
                    // Los observadores actualizarán automáticamente los datos
                }
            } catch {
                await MainActor.run {
                    self.error = "Error al eliminar deuda: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func transferirSobrante() {
        guard let presupuestoActual = presupuestoActual,
              let siguienteIndex = presupuestos.firstIndex(where: { $0.id == presupuestoActual.id })?.advanced(by: 1),
              siguienteIndex < presupuestos.count else {
            // Crear nuevo presupuesto para el próximo mes
            let calendar = Calendar.current
            if let siguienteMes = calendar.date(byAdding: .month, value: 1, to: mesSeleccionado) {
                let nuevoPresupuesto = PresupuestoMensual(
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
            let total = deudas.reduce(0) { $0 + $1.monto }
            datos.append((categoria, total))
        }
        
        return datos
    }
    
    // MARK: - Análisis integrado de presupuesto vs cuentas
    func analisisPresupuestoVsCuentas() -> [CategoriaPresupuestoAnalisis] {
        guard let cuentasVM = cuentasViewModel else { return [] }
        
        let calendario = Calendar.current
        let cuentasDelMes = cuentasVM.cuentas.filter { cuenta in
            calendario.isDate(cuenta.fechaVencimiento, equalTo: mesSeleccionado, toGranularity: .month)
        }
        
        return presupuestosPorCategoria.map { (categoria, presupuesto) in
            let cuentasCategoria = cuentasDelMes.filter { $0.categoria == categoria }
            
            // Calcular gastos reales (cuentas pagadas)
            let gastoActual = cuentasCategoria
                .filter { $0.estado == .pagada }
                .reduce(into: 0.0) { result, cuenta in
                    result += cuenta.monto
                }
            
            // Calcular gastos proyectados (pendientes + vencidas)
            let gastoProyectado = cuentasCategoria
                .filter { $0.estado != .pagada }
                .reduce(into: 0.0) { result, cuenta in
                    result += cuenta.monto
                }
            
            let porcentajeUsado = presupuesto > 0 ? gastoActual / presupuesto : 0
            let estado = calcularEstadoPresupuesto(porcentajeUsado, gastoProyectado: gastoProyectado, presupuesto: presupuesto)
            
            let cuentasPendientes = cuentasCategoria.filter { $0.estado != .pagada }.count
            let cuentasPagadas = cuentasCategoria.filter { $0.estado == .pagada }.count
            
            // Obtener icono de la categoría
            let icono = obtenerIconoCategoria(categoria)
            
            return CategoriaPresupuestoAnalisis(
                nombre: categoria,
                icon: icono,
                presupuestoMensual: presupuesto,
                gastoActual: gastoActual,
                gastoProyectado: gastoProyectado,
                porcentajeUsado: porcentajeUsado,
                estado: estado,
                cuentasPendientes: cuentasPendientes,
                cuentasPagadas: cuentasPagadas
            )
        }.sorted { $0.porcentajeUsado > $1.porcentajeUsado }
    }
    
    func resumenFinancieroIntegrado() -> ResumenFinancieroIntegrado {
        let categorias = analisisPresupuestoVsCuentas()
        
        let presupuestoTotal = presupuestosPorCategoria.values.reduce(0, +)
        let gastoActual = categorias.reduce(0) { $0 + $1.gastoActual }
        let gastoProyectado = categorias.reduce(0) { $0 + $1.gastoProyectado }
        let disponible = presupuestoTotal - gastoActual
        let porcentajeUsado = presupuestoTotal > 0 ? gastoActual / presupuestoTotal : 0
        
        let alertas = generarAlertas(categorias: categorias)
        
        return ResumenFinancieroIntegrado(
            presupuestoTotal: presupuestoTotal,
            gastoActual: gastoActual,
            gastoProyectado: gastoProyectado,
            disponible: disponible,
            porcentajeUsado: porcentajeUsado,
            categorias: categorias,
            alertas: alertas
        )
    }
    
    private func calcularEstadoPresupuesto(_ porcentajeUsado: Double, gastoProyectado: Double, presupuesto: Double) -> EstadoPresupuesto {
        if presupuesto == 0 {
            return .sinPresupuesto
        }
        
        let proyeccionTotal = porcentajeUsado + (gastoProyectado / presupuesto)
        
        if porcentajeUsado > 1.0 {
            return .excedido
        } else if proyeccionTotal > 1.0 || porcentajeUsado > 0.9 {
            return .cerca
        } else if porcentajeUsado > 0.7 {
            return .atencion
        } else {
            return .enRango
        }
    }
    
    private func obtenerIconoCategoria(_ categoria: String) -> String {
        // Usar el nuevo enum de categorías
        if let categoriaEnum = CategoriaFinanciera.allCases.first(where: { $0.rawValue == categoria }) {
            return categoriaEnum.icono
        }
        
        // Fallback para categorías que no estén en el nuevo enum
        switch categoria {
        case "Arriendo": return "house.fill"
        case "Alimentación": return "fork.knife"
        case "Transporte": return "car.fill"
        case "Salud": return "cross.case.fill"
        case "Entretenimiento": return "tv.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func generarAlertas(categorias: [CategoriaPresupuestoAnalisis]) -> [AlertaFinanciera] {
        var alertas: [AlertaFinanciera] = []
        
        for categoria in categorias {
            switch categoria.estado {
            case .excedido:
                alertas.append(AlertaFinanciera(
                    tipo: .presupuestoExcedido,
                    mensaje: "\(categoria.nombre): Presupuesto excedido en $\(String(format: "%.0f", -categoria.diferencia))",
                    categoria: categoria.nombre,
                    urgencia: .critico
                ))
                
            case .cerca:
                if categoria.excedeProyeccion {
                    alertas.append(AlertaFinanciera(
                        tipo: .proyeccionExcede,
                        mensaje: "\(categoria.nombre): Proyección excederá presupuesto en $\(String(format: "%.0f", categoria.proyeccionFinal - categoria.presupuestoMensual))",
                        categoria: categoria.nombre,
                        urgencia: .alto
                    ))
                } else {
                    alertas.append(AlertaFinanciera(
                        tipo: .cercaDelLimite,
                        mensaje: "\(categoria.nombre): Cerca del límite (\(String(format: "%.0f", categoria.porcentajeUsado * 100))%)",
                        categoria: categoria.nombre,
                        urgencia: .medio
                    ))
                }
                
            case .atencion:
                alertas.append(AlertaFinanciera(
                    tipo: .cercaDelLimite,
                    mensaje: "\(categoria.nombre): Atención - \(String(format: "%.0f", categoria.porcentajeUsado * 100))% usado",
                    categoria: categoria.nombre,
                    urgencia: .medio
                ))
                
            case .sinPresupuesto:
                if categoria.gastoActual > 0 {
                    alertas.append(AlertaFinanciera(
                        tipo: .sinPresupuesto,
                        mensaje: "\(categoria.nombre): Sin presupuesto definido ($\(String(format: "%.0f", categoria.gastoActual)) gastado)",
                        categoria: categoria.nombre,
                        urgencia: .bajo
                    ))
                }
                
            case .enRango:
                break // No genera alertas
            }
        }
        
        // Agregar alertas de vencimientos próximos si hay acceso a cuentasViewModel
        if let cuentasVM = cuentasViewModel {
            let cuentasProximasVencer = cuentasVM.cuentasProximasVencer
            if !cuentasProximasVencer.isEmpty {
                alertas.append(AlertaFinanciera(
                    tipo: .vencimientoProximo,
                    mensaje: "\(cuentasProximasVencer.count) cuenta(s) vencen pronto",
                    categoria: nil,
                    urgencia: .alto
                ))
            }
        }
        
        return alertas.sorted { $0.urgencia.hashValue > $1.urgencia.hashValue }
    }
    
    // MARK: - Métodos de gestión de presupuestos por categoría
    func actualizarPresupuestoCategoria(_ categoria: String, monto: Double) {
        presupuestosPorCategoria[categoria] = monto
        objectWillChange.send()
    }
    
    func obtenerPresupuestoCategoria(_ categoria: String) -> Double {
        return presupuestosPorCategoria[categoria] ?? 0.0
    }
    
    func categoriasConGastosSinPresupuesto() -> [String] {
        guard let cuentasVM = cuentasViewModel else { return [] }
        
        let calendario = Calendar.current
        let cuentasDelMes = cuentasVM.cuentas.filter { cuenta in
            calendario.isDate(cuenta.fechaVencimiento, equalTo: mesSeleccionado, toGranularity: .month)
        }
        
        let categoriasConGastos = Set(cuentasDelMes.map { $0.categoria })
        let categoriasConPresupuesto = Set(presupuestosPorCategoria.keys)
        
        return Array(categoriasConGastos.subtracting(categoriasConPresupuesto))
    }
    
    func sugerirPresupuestoParaCategoria(_ categoria: String) -> Double {
        guard let cuentasVM = cuentasViewModel else { return 0 }
        
        // Calcular promedio de gastos de los últimos 3 meses para esta categoría
        let calendario = Calendar.current
        var totalGastos: Double = 0
        var mesesConGastos = 0
        
        for i in 0..<3 {
            if let fecha = calendario.date(byAdding: .month, value: -i, to: Date()) {
                let gastosDelMes = cuentasVM.cuentas
                    .filter { cuenta in
                        cuenta.categoria == categoria &&
                        calendario.isDate(cuenta.fechaVencimiento, equalTo: fecha, toGranularity: .month)
                    }
                    .reduce(0) { $0 + $1.monto }
                
                if gastosDelMes > 0 {
                    totalGastos += gastosDelMes
                    mesesConGastos += 1
                }
            }
        }
        
        if mesesConGastos > 0 {
            let promedio = totalGastos / Double(mesesConGastos)
            // Agregar un 10% de margen
            return promedio * 1.1
        }
        
        return 0
    }
    
    // MARK: - FASE 1: Gestión de saldos de aportes
    
    /// Obtener aportes disponibles (con saldo > 0) del mes actual
    var aportesDisponibles: [Aporte] {
        return aportesDelMes.filter { $0.tieneDisponible }
    }
    
    /// Calcular saldo total disponible de todos los aportes
    var saldoTotalDisponible: Double {
        return aportesDelMes.reduce(0) { $0 + $1.saldoDisponible }
    }
    
    /// Verificar si hay suficiente saldo para cubrir un monto
    func tieneSaldoSuficiente(para monto: Double) -> Bool {
        return saldoTotalDisponible >= monto
    }
    
    /// Obtener aportes que pueden cubrir un monto específico
    func aportesQuePuedenCubrir(monto: Double) -> [Aporte] {
        return aportesDisponibles.filter { $0.saldoDisponible >= monto }
    }
    
    /// Calcular distribución automática de un monto entre aportes disponibles
    func calcularDistribucionAutomatica(monto: Double) -> [(aporte: Aporte, montoAUsar: Double)] {
        guard tieneSaldoSuficiente(para: monto) else { return [] }
        
        var distribucion: [(aporte: Aporte, montoAUsar: Double)] = []
        var montoRestante = monto
        
        // Ordenar aportes por saldo disponible (de mayor a menor)
        let aportesOrdenados = aportesDisponibles.sorted { $0.saldoDisponible > $1.saldoDisponible }
        
        for aporte in aportesOrdenados {
            if montoRestante <= 0 { break }
            
            let montoAUsar = min(aporte.saldoDisponible, montoRestante)
            distribucion.append((aporte: aporte, montoAUsar: montoAUsar))
            montoRestante -= montoAUsar
        }
        
        return distribucion
    }
    
    /// Usar monto de aportes específicos y actualizar en Firebase
    func usarAportes(_ distribucion: [(aporteId: String, montoAUsar: Double)]) async throws {
        guard let familiaId = familiaId else { 
            throw NSError(domain: "PresupuestoViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "FamiliaId no disponible"])
        }
        
        print("💳 INICIO: usarAportes")
        print("   - FamiliaId: \(familiaId)")
        print("   - Distribución: \(distribucion)")
        print("   - Aportes actuales: \(aportes.count)")
        print("   - Aportes antes de modificar:")
        for aporte in aportes {
            print("     * \(aporte.usuario): monto=\(aporte.monto), utilizado=\(aporte.montoUtilizado), disponible=\(aporte.saldoDisponible)")
        }
        
        // Actualizar los aportes localmente primero
        var aportesActualizados: [Aporte] = []
        
        for (aporteId, montoAUsar) in distribucion {
            guard let index = aportes.firstIndex(where: { $0.id == aporteId }) else { 
                print("❌ Aporte con ID \(aporteId) no encontrado")
                continue 
            }
            
            var aporte = aportes[index]
            let saldoAnterior = aporte.saldoDisponible
            
            guard aporte.usarMonto(montoAUsar) else {
                throw NSError(domain: "PresupuestoViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Saldo insuficiente en aporte de \(aporte.usuario)"])
            }
            
            print("💰 Aporte \(aporte.usuario):")
            print("   - Saldo anterior: \(saldoAnterior)")
            print("   - Monto usado: \(montoAUsar)")
            print("   - Saldo nuevo: \(aporte.saldoDisponible)")
            print("   - Monto utilizado total: \(aporte.montoUtilizado)")
            
            aportes[index] = aporte
            aportesActualizados.append(aporte)
        }
        
        print("🔄 Actualizando \(aportesActualizados.count) aportes en Firebase...")
        
        // Verificar estado antes de enviar a Firebase
        print("📊 Estado de aportes antes de Firebase:")
        for aporte in aportesActualizados {
            print("   - \(aporte.usuario): utilizado=\(aporte.montoUtilizado), disponible=\(aporte.saldoDisponible)")
        }
        
        // Actualizar en Firebase
        for aporte in aportesActualizados {
            do {
                print("🚀 Enviando aporte de \(aporte.usuario) a Firebase...")
                try await firebaseService.actualizarAporte(familiaId: familiaId, aporte: aporte)
                print("✅ Aporte de \(aporte.usuario) actualizado en Firebase")
            } catch {
                print("❌ Error actualizando aporte de \(aporte.usuario): \(error)")
                print("   - Error details: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("   - Domain: \(nsError.domain), Code: \(nsError.code)")
                    print("   - UserInfo: \(nsError.userInfo)")
                }
                throw error
            }
        }
        
        print("✅ FINALIZADO: Todos los aportes actualizados exitosamente")
        
        // Forzar recarga para verificar que los cambios llegaron
        print("🔄 Forzando recarga para verificar cambios...")
        await forzarRecargaAportes()
    }
    
    /// FASE 1: Procesar pago completo usando aportes y actualizar cuenta
    func procesarPagoConAportes(cuenta: Cuenta, distribucion: [(aporteId: String, montoAUsar: Double)], usuario: String) async throws {
        guard let familiaId = familiaId else {
            throw NSError(domain: "PresupuestoViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "FamiliaId no disponible"])
        }
        
        print("💳 INICIO: procesarPagoConAportes")
        print("   - Cuenta: \(cuenta.nombre) - $\(cuenta.monto)")
        print("   - Usuario pagador: \(usuario)")
        print("   - Distribución de aportes: \(distribucion)")
        
        let montoTotal = distribucion.reduce(0) { $0 + $1.montoAUsar }
        guard montoTotal >= cuenta.monto else {
            throw NSError(domain: "PresupuestoViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "El monto de los aportes (\(montoTotal)) no cubre el total de la cuenta (\(cuenta.monto))"])
        }
        
        print("✅ Validación de montos correcta: \(montoTotal) >= \(cuenta.monto)")
        
        // 1. Usar los aportes (esto actualiza localmente y en Firebase)
        print("🔄 Paso 1: Actualizando aportes...")
        try await usarAportes(distribucion)
        print("✅ Paso 1 completado: Aportes actualizados")
        
        // 2. Crear transacción con referencia a aportes utilizados
        print("🔄 Paso 2: Creando transacción de pago...")
        let aportesUtilizados: [AporteUtilizado] = distribucion.compactMap { (aporteId, montoAUsar) -> AporteUtilizado? in
            guard let aporte = aportes.first(where: { $0.id == aporteId }) else { 
                print("⚠️ No se encontró aporte con ID: \(aporteId)")
                return nil 
            }
            return AporteUtilizado(aporteId: aporteId, usuarioAporte: aporte.usuario, montoUtilizado: montoAUsar)
        }
        
        let transaccion = TransaccionPago(
            cuentaId: cuenta.id,
            monto: cuenta.monto,
            usuario: usuario,
            descripcion: "Pago de \(cuenta.nombre) usando \(aportesUtilizados.count) aporte(s)"
        )
        var transaccionConAportes = transaccion
        transaccionConAportes.aportesUtilizados = aportesUtilizados
        
        try await firebaseService.crearTransaccionPago(familiaId: familiaId, transaccion: transaccionConAportes)
        print("✅ Paso 2 completado: Transacción creada")
        
        // 3. Actualizar cuenta como pagada
        print("🔄 Paso 3: Marcando cuenta como pagada...")
        var cuentaPagada = cuenta
        cuentaPagada.estado = .pagada
        cuentaPagada.fechaPago = Date()
        cuentaPagada.montoPagado = cuenta.monto
        
        try await firebaseService.actualizarCuenta(cuentaPagada, familiaId: familiaId)
        print("✅ Paso 3 completado: Cuenta marcada como pagada")
        
        print("🎉 PROCESO COMPLETADO: Pago procesado exitosamente")
        print("   - Los observadores actualizarán automáticamente los datos")
        
        // Verificar estado final
        await verificarEstadoFinalPago(cuentaId: cuenta.id, distribucion: distribucion)
    }
    
    /// FASE 3: Procesar pago con múltiples aportes
    func procesarPagoConMultiplesAportes(cuenta: Cuenta, aportesSeleccionados: [AporteSeleccionado], usuario: String) async throws {
        guard self.familiaId != nil else {
            throw NSError(domain: "PresupuestoViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "FamiliaId no disponible"])
        }
        
        let montoTotal = aportesSeleccionados.reduce(0) { $0 + $1.montoAUsar }
        guard abs(montoTotal - cuenta.monto) < 0.01 else {
            throw NSError(domain: "PresupuestoViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "La suma de los aportes no coincide con el monto de la cuenta"])
        }
        
        // Validar que todos los aportes tengan saldo suficiente
        for seleccion in aportesSeleccionados {
            guard seleccion.aporte.saldoDisponible >= seleccion.montoAUsar else {
                throw NSError(domain: "PresupuestoViewModel", code: 4, userInfo: [NSLocalizedDescriptionKey: "Saldo insuficiente en aporte de \(seleccion.aporte.usuario)"])
            }
        }
        
        // Preparar distribución para el método existente
        let distribucion = aportesSeleccionados.map { (aporteId: $0.aporte.id, montoAUsar: $0.montoAUsar) }
        
        // Usar el método existente que ya maneja la transacción completa
        try await procesarPagoConAportes(cuenta: cuenta, distribucion: distribucion, usuario: usuario)
    }
    
    /// FASE 3: Validar distribución de múltiples aportes
    func validarDistribucionMultiple(_ aportesSeleccionados: [AporteSeleccionado], montoRequerido: Double) -> (esValida: Bool, error: String?) {
        guard !aportesSeleccionados.isEmpty else {
            return (false, "Debe seleccionar al menos un aporte")
        }
        
        let montoTotal = aportesSeleccionados.reduce(0) { $0 + $1.montoAUsar }
        
        // Verificar que el monto total coincida
        guard abs(montoTotal - montoRequerido) < 0.01 else {
            let diferencia = montoRequerido - montoTotal
            if diferencia > 0 {
                return (false, "Faltan $\(String(format: "%.0f", diferencia)) por cubrir")
            } else {
                return (false, "Excede en $\(String(format: "%.0f", -diferencia)) el monto requerido")
            }
        }
        
        // Verificar saldos individuales
        for seleccion in aportesSeleccionados {
            guard seleccion.montoAUsar <= seleccion.aporte.saldoDisponible else {
                return (false, "El aporte de \(seleccion.aporte.usuario) no tiene saldo suficiente")
            }
        }
        
        return (true, nil)
    }
    
    /// FASE 3: Obtener resumen de distribución
    func resumenDistribucion(_ aportesSeleccionados: [AporteSeleccionado]) -> String {
        guard !aportesSeleccionados.isEmpty else { return "Sin aportes seleccionados" }
        
        let montoTotal = aportesSeleccionados.reduce(0) { $0 + $1.montoAUsar }
        let usuarios = aportesSeleccionados.map { $0.aporte.usuario }
        
        if aportesSeleccionados.count == 1 {
            return "Pago de $\(String(format: "%.0f", montoTotal)) usando aporte de \(usuarios.first!)"
        } else {
            return "Pago de $\(String(format: "%.0f", montoTotal)) usando \(aportesSeleccionados.count) aportes: \(usuarios.joined(separator: ", "))"
        }
    }
    
    // MARK: - Métodos de debugging y recarga forzada
    
    /// Forzar recarga de aportes desde Firebase (para debugging)
    func forzarRecargaAportes() async {
        guard let familiaId = familiaId else { 
            print("❌ No se puede recargar aportes: familiaId es nil")
            return 
        }
        
        print("🔄 Forzando recarga de aportes desde Firebase...")
        
        do {
            let aportesActualizados = try await firebaseService.obtenerAportesFamilia(familiaId: familiaId)
            
            await MainActor.run {
                print("📊 Aportes obtenidos directamente:")
                for aporte in aportesActualizados {
                    print("   - \(aporte.usuario): \(aporte.saldoDisponible) disponible")
                }
                
                self.aportes = aportesActualizados
                self.objectWillChange.send()
            }
        } catch {
            print("❌ Error al forzar recarga de aportes: \(error)")
        }
    }
    
    /// Debug: Comparar aportes locales vs Firebase
    func compararAportesConFirebase() async {
        guard let familiaId = familiaId else { return }
        
        do {
            let aportesFirebase = try await firebaseService.obtenerAportesFamilia(familiaId: familiaId)
            
            print("🔍 Comparación aportes locales vs Firebase:")
            print("   Locales: \(aportes.count), Firebase: \(aportesFirebase.count)")
            
            for aporteLocal in aportes {
                if let aporteFirebase = aportesFirebase.first(where: { $0.id == aporteLocal.id }) {
                    if aporteLocal.montoUtilizado != aporteFirebase.montoUtilizado {
                        print("   ⚠️ Diferencia en \(aporteLocal.usuario):")
                        print("      Local: utilizado=\(aporteLocal.montoUtilizado), disponible=\(aporteLocal.saldoDisponible)")
                        print("      Firebase: utilizado=\(aporteFirebase.montoUtilizado), disponible=\(aporteFirebase.saldoDisponible)")
                    }
                }
            }
        } catch {
            print("❌ Error comparando aportes: \(error)")
        }
    }
    
    // MARK: - Gestión de observadores en tiempo real
    
    private func iniciarObservadores() {
        guard let familiaId = familiaId else { return }
        
        // Detener observadores anteriores si existen
        detenerObservadores()
        
        isLoading = true
        
        // Observador para aportes
        observadorAportesHandle = firebaseService.observarAportes(familiaId: familiaId) { [weak self] aportes in
            Task { @MainActor in
                guard let self = self else { return }
                
                print("🔄 OBSERVADOR DE APORTES DISPARADO:")
                print("   - Aportes recibidos: \(aportes.count)")
                print("   - Aportes actuales: \(self.aportes.count)")
                
                // Logging detallado de cambios
                for aporteNuevo in aportes {
                    if let aporteActual = self.aportes.first(where: { $0.id == aporteNuevo.id }) {
                        if aporteActual.montoUtilizado != aporteNuevo.montoUtilizado {
                            print("   📊 CAMBIO DETECTADO en aporte de \(aporteNuevo.usuario):")
                            print("      - Monto utilizado anterior: \(aporteActual.montoUtilizado)")
                            print("      - Monto utilizado nuevo: \(aporteNuevo.montoUtilizado)")
                            print("      - Saldo disponible anterior: \(aporteActual.saldoDisponible)")
                            print("      - Saldo disponible nuevo: \(aporteNuevo.saldoDisponible)")
                        }
                    } else {
                        print("   ➕ NUEVO APORTE: \(aporteNuevo.usuario) - \(aporteNuevo.saldoDisponible) disponible")
                    }
                }
                
                // Detectar aportes eliminados
                for aporteActual in self.aportes {
                    if !aportes.contains(where: { $0.id == aporteActual.id }) {
                        print("   ➖ APORTE ELIMINADO: \(aporteActual.usuario)")
                    }
                }
                
                self.aportes = aportes
                print("✅ Aportes actualizados localmente: \(aportes.count) aportes")
                
                // Logging final del estado
                print("📊 Estado final de aportes:")
                for aporte in self.aportes {
                    print("   - \(aporte.usuario): utilizado=\(aporte.montoUtilizado), disponible=\(aporte.saldoDisponible)")
                }
                
                self.actualizarCargaCompleta()
            }
        }
        
        // Observador para presupuestos
        observadorPresupuestosHandle = firebaseService.observarPresupuestos(familiaId: familiaId) { [weak self] presupuestos in
            Task { @MainActor in
                guard let self = self else { return }
                self.presupuestos = presupuestos
                print("🔄 Presupuestos actualizados: \(presupuestos.count) presupuestos")
                self.actualizarCargaCompleta()
            }
        }
        
        // Observador para deudas
        observadorDeudasHandle = firebaseService.observarDeudas(familiaId: familiaId) { [weak self] deudas in
            Task { @MainActor in
                guard let self = self else { return }
                self.deudas = deudas
                print("🔄 Deudas actualizadas: \(deudas.count) deudas")
                self.actualizarCargaCompleta()
            }
        }
    }
    
    private func detenerObservadores() {
        guard let familiaId = familiaId else { return }
        
        if let handle = observadorAportesHandle {
            firebaseService.detenerObservadorAportes(familiaId: familiaId, handle: handle)
            observadorAportesHandle = nil
        }
        
        if let handle = observadorPresupuestosHandle {
            firebaseService.detenerObservadorPresupuestos(familiaId: familiaId, handle: handle)
            observadorPresupuestosHandle = nil
        }
        
        if let handle = observadorDeudasHandle {
            firebaseService.detenerObservadorDeudas(familiaId: familiaId, handle: handle)
            observadorDeudasHandle = nil
        }
    }
    
    private func actualizarCargaCompleta() {
        // Solo marcar como cargado cuando tengamos datos iniciales
        if !aportes.isEmpty || !presupuestos.isEmpty || !deudas.isEmpty {
            isLoading = false
        }
    }
    
    deinit {
        // Detener observadores de forma síncrona en deinit
        if let familiaId = familiaId {
            if let handle = observadorAportesHandle {
                firebaseService.detenerObservadorAportes(familiaId: familiaId, handle: handle)
            }
            if let handle = observadorPresupuestosHandle {
                firebaseService.detenerObservadorPresupuestos(familiaId: familiaId, handle: handle)
            }
            if let handle = observadorDeudasHandle {
                firebaseService.detenerObservadorDeudas(familiaId: familiaId, handle: handle)
            }
        }
    }
    
    // MARK: - Propiedades adicionales para el resumen financiero
    
    var gastosDelMes: [GastoItem] {
        // Por ahora retornamos una lista vacía hasta implementar gastos
        return []
    }
    
    var ahorrosDelMes: [AhorroItem] {
        // Por ahora retornamos una lista vacía hasta implementar ahorros
        return []
    }
    
    var totalGastos: Double {
        // TODO: Implementar cálculo de gastos reales
        return totalDeudasMensuales // Por ahora usamos las deudas como gastos
    }

    var totalAhorros: Double {
        // TODO: Implementar cálculo de ahorros
        return 0.0
    }

    var saldoAportes: Double {
        return totalAportes - totalGastos - totalAhorros
    }

    var porcentajeGastado: Double {
        return totalAportes > 0 ? (totalGastos / totalAportes) * 100 : 0
    }

    var porcentajeAhorrado: Double {
        return totalAportes > 0 ? (totalAhorros / totalAportes) * 100 : 0
    }
    
    // MARK: - Método de carga de datos simplificado
    
    func cargarDatos() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            // Simplemente asegurarnos que los datos estén cargados (observadores)
            if let familiaId = familiaId {
                if observadorAportesHandle == nil {
                    iniciarObservadores()
                }
            }
        } catch {
            await MainActor.run {
                self.error = "Error cargando datos: \(error.localizedDescription)"
            }
        }
        
        // La carga se marcará como completada en el método actualizarCargaCompleta
    }
    
    // MARK: - Métodos pendientes de implementar
    
    func eliminarGasto(_ id: String) async {
        print("⚠️ Método eliminarGasto no implementado aún")
        // TODO: Implementar cuando se añada el soporte para gastos
    }

    func eliminarAhorro(_ id: String) async {
        print("⚠️ Método eliminarAhorro no implementado aún")
        // TODO: Implementar cuando se añada el soporte para ahorros
    }
    
    // MARK: - Método para cerrar mes
    
    func cerrarMes() async {
        guard let presupuestoActual = presupuestoActual else { return }
        
        await MainActor.run {
            isPerformingAction = true
        }
        
        // Transferir sobrantes y cerrar mes
        transferirSobrante()
        
        await MainActor.run {
            isPerformingAction = false
        }
    }
    
    // MARK: - Método de verificación del estado final del pago
    private func verificarEstadoFinalPago(cuentaId: String, distribucion: [(aporteId: String, montoAUsar: Double)]) async {
        print("\n🔍 VERIFICACIÓN ESTADO FINAL:")
        
        // Esperar un momento para que los observadores se actualicen
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 segundo
        
        print("📊 Estado de aportes después del pago:")
        for (aporteId, montoUsado) in distribucion {
            if let aporte = aportes.first(where: { $0.id == aporteId }) {
                print("   - \(aporte.usuario):")
                print("     • Monto total: \(aporte.monto)")
                print("     • Monto utilizado: \(aporte.montoUtilizado)")
                print("     • Saldo disponible: \(aporte.saldoDisponible)")
                print("     • Monto usado en esta transacción: \(montoUsado)")
            } else {
                print("   ❌ Aporte \(aporteId) no encontrado en datos locales")
            }
        }
        
        print("💰 Saldo total disponible: \(saldoTotalDisponible)")
        print("📱 Total aportes del mes: \(aportesDelMes.count)")
        print("🔍 FIN VERIFICACIÓN ESTADO FINAL\n")
        
        // Programar verificación de consistencia con Firebase
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 segundos adicionales
            await compararAportesConFirebase()
        }
    }
    
    // MARK: - Métodos de testing y diagnóstico
    
    /// Método de prueba para verificar el flujo completo de pago
    func probarFlujoPago() async {
        print("\n🧪 === PRUEBA DE FLUJO DE PAGO ===")
        
        // Verificar estado inicial
        print("📊 Estado inicial:")
        verificarIntegracionCuentas()
        
        guard let cuentasVM = cuentasViewModel else {
            print("❌ No se puede probar: CuentasViewModel no configurado")
            return
        }
        
        // Buscar una cuenta pendiente para probar
        let cuentasPendientes = cuentasVM.cuentas.filter { $0.estado == .pendiente }
        guard let cuentaPrueba = cuentasPendientes.first else {
            print("❌ No hay cuentas pendientes para probar")
            return
        }
        
        print("🎯 Cuenta seleccionada para prueba: \(cuentaPrueba.nombre) - $\(cuentaPrueba.monto)")
        
        // Verificar si hay aportes suficientes
        guard tieneSaldoSuficiente(para: cuentaPrueba.monto) else {
            print("❌ No hay saldo suficiente para la prueba")
            print("   Saldo disponible: \(saldoTotalDisponible)")
            print("   Monto requerido: \(cuentaPrueba.monto)")
            return
        }
        
        // Calcular distribución automática
        let distribucion = calcularDistribucionAutomatica(monto: cuentaPrueba.monto)
        print("🔄 Distribución automática calculada: \(distribucion.count) aportes")
        
        // Simular el pago (sin ejecutar realmente)
        print("🧪 SIMULACIÓN - No se ejecutará el pago real")
        logProcesoPago(cuenta: cuentaPrueba, distribucion: distribucion.map { (aporteId: $0.aporte.id, montoAUsar: $0.montoAUsar) })
        
        print("🧪 === FIN PRUEBA DE FLUJO ===\n")
    }
    
    /// Diagnóstico completo del estado del sistema
    func diagnosticoCompleto() async {
        print("\n🩺 === DIAGNÓSTICO COMPLETO ===")
        
        // 1. Verificar configuración
        print("1️⃣ Verificación de configuración:")
        verificarIntegracionCuentas()
        
        // 2. Estado de datos
        print("\n2️⃣ Estado de datos:")
        print("   📊 Presupuestos: \(presupuestos.count)")
        print("   💰 Aportes: \(aportes.count)")
        print("   📋 Deudas: \(deudas.count)")
        print("   🏦 Cuentas: \(cuentasViewModel?.cuentas.count ?? 0)")
        
        // 3. Análisis de saldos
        print("\n3️⃣ Análisis de saldos:")
        print("   💵 Total aportes: \(totalAportes)")
        print("   💳 Saldo disponible: \(saldoTotalDisponible)")
        print("   📈 Aportes disponibles: \(aportesDisponibles.count)")
        
        // 4. Verificar consistencia
        print("\n4️⃣ Verificación de consistencia:")
        await verificarConsistenciaDatos()
        
        // 5. Estado de observadores
        print("\n5️⃣ Estado de observadores:")
        print("   🔍 Observador aportes: \(observadorAportesHandle != nil ? "Activo" : "Inactivo")")
        print("   🔍 Observador presupuestos: \(observadorPresupuestosHandle != nil ? "Activo" : "Inactivo")")
        print("   🔍 Observador deudas: \(observadorDeudasHandle != nil ? "Activo" : "Inactivo")")
        
        print("🩺 === FIN DIAGNÓSTICO ===\n")
    }
}
