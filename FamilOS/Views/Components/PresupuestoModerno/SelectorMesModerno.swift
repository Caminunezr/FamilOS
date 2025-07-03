import SwiftUI

struct SelectorMesModerno: View {
    @Binding var mesSeleccionado: Date
    let cambiarMes: (Bool) -> Void
    let crearPresupuesto: () -> Void
    
    @State private var mostrarCrearPresupuesto = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header con título
            VStack(spacing: 8) {
                Text("📅 Gestión Presupuestaria")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Selecciona el mes a gestionar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Selector de mes principal
            HStack(spacing: 20) {
                // Botón mes anterior
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cambiarMes(false)
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Efecto hover sutil
                    }
                }
                
                Spacer()
                
                // Mes actual con estilo moderno
                VStack(spacing: 4) {
                    Text(mesFormateado.uppercased())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text("Presupuesto Familiar")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.0)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .primary.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                }
                
                Spacer()
                
                // Botón mes siguiente
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        cambiarMes(true)
                    }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Acciones rápidas
            HStack(spacing: 12) {
                // Botón crear presupuesto
                Button {
                    mostrarCrearPresupuesto = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.callout)
                        Text("Crear Mes")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Indicador de estado
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Presupuesto Activo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .primary.opacity(0.08), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal)
        .sheet(isPresented: $mostrarCrearPresupuesto) {
            CrearPresupuestoView(onCrear: crearPresupuesto)
                .frame(width: 400, height: 300)
        }
    }
    
    private var mesFormateado: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: mesSeleccionado).capitalized
    }
}

// MARK: - Vista para crear presupuesto
struct CrearPresupuestoView: View {
    let onCrear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var fechaSeleccionada = Date()
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Text("📊 Crear Presupuesto")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Establece un nuevo período presupuestario")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Selector de fecha
            DatePicker(
                "Mes y Año",
                selection: $fechaSeleccionada,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            
            Spacer()
            
            // Botones de acción
            HStack(spacing: 12) {
                Button("Cancelar") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Crear Presupuesto") {
                    onCrear()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

#Preview {
    SelectorMesModerno(
        mesSeleccionado: .constant(Date()),
        cambiarMes: { _ in },
        crearPresupuesto: { }
    )
    .preferredColorScheme(.light)
}
