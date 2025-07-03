import SwiftUI

struct EstadoMesModerno: View {
    let resumen: ResumenPresupuesto
    let presupuesto: PresupuestoMensual?
    let onCerrarMes: () -> Void
    let accionLoading: Bool
    
    @State private var isAnimating = false
    @State private var showCerrarMesConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("📊 Estado del Mes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Resumen y acciones de cierre")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Estado principal
            estadoPrincipalView
            
            // Acciones disponibles
            if !esMesCerrado {
                accionesView
            } else {
                mesYaCerradoView
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .primary.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.8), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
        .confirmationDialog(
            "¿Cerrar el mes actual?",
            isPresented: $showCerrarMesConfirmation,
            titleVisibility: .visible
        ) {
            Button("Cerrar Mes", role: .destructive) {
                onCerrarMes()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acción transferirá automáticamente los ahorros y creará el presupuesto del siguiente mes.")
        }
    }
    
    // MARK: - Estado Principal
    private var estadoPrincipalView: some View {
        VStack(spacing: 16) {
            // Indicador de estado
            HStack(spacing: 12) {
                Circle()
                    .fill(colorEstado)
                    .frame(width: 12, height: 12)
                    .shadow(color: colorEstado.opacity(0.5), radius: 4, x: 0, y: 2)
                
                Text(textoEstado)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if esMesCerrado {
                    Text("✅")
                        .font(.title3)
                }
            }
            
            // Información financiera clave
            HStack(spacing: 20) {
                InfoCard(
                    titulo: "Sobrante",
                    valor: formatoMoneda(resumen.saldoAportes),
                    color: resumen.saldoAportes >= 0 ? .green : .red,
                    icono: resumen.saldoAportes >= 0 ? "💰" : "⚠️"
                )
                
                if resumen.totalDeuda > 0 {
                    InfoCard(
                        titulo: "Deudas Pendientes",
                        valor: formatoMoneda(resumen.totalDeuda),
                        color: .orange,
                        icono: "💳"
                    )
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: colorEstado.opacity(0.1), radius: 6, x: 0, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorEstado.opacity(0.3), lineWidth: 1)
        }
    }
    
    // MARK: - Acciones
    private var accionesView: some View {
        VStack(spacing: 16) {
            // Información de qué pasará al cerrar
            if haySobrante {
                InformacionCierreView(sobrante: resumen.saldoAportes)
            }
            
            // Botón de cerrar mes
            Button {
                showCerrarMesConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    if accionLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("✅")
                            .font(.title3)
                    }
                    
                    Text(accionLoading ? "Cerrando mes..." : "Cerrar mes y transferir")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.gradient)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(accionLoading)
            .scaleEffect(accionLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: accionLoading)
            
            // Advertencias si no hay sobrante
            if !haySobrante && !hayDeudasPendientes {
                AdvertenciaView(
                    titulo: "Sin sobrante para transferir",
                    mensaje: "Considera agregar más aportes o revisar los gastos registrados antes de cerrar el mes.",
                    icono: "⚠️",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Mes Ya Cerrado
    private var mesYaCerradoView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text("✅")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mes cerrado exitosamente")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Las transferencias se completaron automáticamente")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.green.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.green.opacity(0.3), lineWidth: 1)
                    }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var esMesCerrado: Bool {
        presupuesto?.cerrado ?? false
    }
    
    private var haySobrante: Bool {
        resumen.saldoAportes > 0
    }
    
    private var hayDeudasPendientes: Bool {
        resumen.totalDeuda > 0
    }
    
    private var colorEstado: Color {
        if esMesCerrado { return .green }
        if haySobrante { return .blue }
        return .orange
    }
    
    private var textoEstado: String {
        if esMesCerrado { return "Mes Cerrado" }
        if haySobrante { return "Listo para cerrar" }
        return "Mes en progreso"
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

struct InfoCard: View {
    let titulo: String
    let valor: String
    let color: Color
    let icono: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icono)
                .font(.title2)
            
            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text(valor)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

struct InformacionCierreView: View {
    let sobrante: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("ℹ️")
                    .font(.title3)
                
                Text("Al cerrar el mes se realizarán las siguientes acciones:")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                AccionItem(
                    icono: "🏦",
                    texto: "Se transferirá \(formatoMoneda(sobrante)) al ahorro automáticamente"
                )
                
                AccionItem(
                    icono: "📅",
                    texto: "Se creará automáticamente el presupuesto del siguiente mes"
                )
                
                AccionItem(
                    icono: "💰",
                    texto: "Los ahorros aparecerán disponibles en el siguiente mes"
                )
            }
            .padding(.leading, 8)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                }
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

struct AccionItem: View {
    let icono: String
    let texto: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(icono)
                .font(.subheadline)
            
            Text(texto)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

struct AdvertenciaView: View {
    let titulo: String
    let mensaje: String
    let icono: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icono)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                
                Text(mensaje)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

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
    
    EstadoMesModerno(
        resumen: resumenEjemplo,
        presupuesto: presupuestoEjemplo,
        onCerrarMes: { print("Cerrar mes") },
        accionLoading: false
    )
    .preferredColorScheme(.light)
    .padding()
}
