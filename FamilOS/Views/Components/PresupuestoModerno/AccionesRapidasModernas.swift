import SwiftUI

struct AccionesRapidasModernas: View {
    let onAgregarAporte: () -> Void
    let onRegistrarDeuda: () -> Void
    let onRegistrarAhorro: () -> Void
    let onCerrarMes: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header de la sección
            VStack(spacing: 8) {
                Text("🚀 Acciones Rápidas")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Gestiona tus finanzas de manera rápida y sencilla")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Grid de acciones
            LazyVGrid(columns: columnas, spacing: 16) {
                ForEach(accionesData.indices, id: \.self) { index in
                    let accion = accionesData[index]
                    BotonAccionRapida(
                        titulo: accion.titulo,
                        subtitulo: accion.subtitulo,
                        icono: accion.icono,
                        color: accion.color,
                        gradiente: accion.gradiente,
                        accion: accion.accion,
                        animationDelay: Double(index) * 0.1
                    )
                }
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
    }
    
    private var columnas: [GridItem] {
        [
            GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
        ]
    }
    
    private var accionesData: [AccionData] {
        [
            AccionData(
                titulo: "Agregar Aporte",
                subtitulo: "Registra ingresos familiares",
                icono: "💰",
                color: .green,
                gradiente: LinearGradient(
                    colors: [.green.opacity(0.1), .green.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accion: onAgregarAporte
            ),
            AccionData(
                titulo: "Registrar Deuda",
                subtitulo: "Controla tus compromisos",
                icono: "💳",
                color: .orange,
                gradiente: LinearGradient(
                    colors: [.orange.opacity(0.1), .orange.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accion: onRegistrarDeuda
            ),
            AccionData(
                titulo: "Registrar Ahorro",
                subtitulo: "Planifica tu futuro",
                icono: "🏦",
                color: .blue,
                gradiente: LinearGradient(
                    colors: [.blue.opacity(0.1), .blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accion: onRegistrarAhorro
            ),
            AccionData(
                titulo: "Cerrar Mes",
                subtitulo: "Transferir y finalizar",
                icono: "✅",
                color: .purple,
                gradiente: LinearGradient(
                    colors: [.purple.opacity(0.1), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                accion: onCerrarMes
            )
        ]
    }
}

struct BotonAccionRapida: View {
    let titulo: String
    let subtitulo: String
    let icono: String
    let color: Color
    let gradiente: LinearGradient
    let accion: () -> Void
    let animationDelay: Double
    
    @State private var isPressed = false
    @State private var isVisible = false
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            // Animación de feedback táctil
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                accion()
            }
        }) {
            VStack(spacing: 12) {
                // Icono con efecto de hover
                Text(icono)
                    .font(.largeTitle)
                    .scaleEffect(isHovering ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovering)
                
                // Contenido de texto
                VStack(spacing: 4) {
                    Text(titulo)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitulo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(20)
            .frame(minHeight: 120)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradiente)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    }
                    .shadow(
                        color: color.opacity(isHovering ? 0.3 : 0.15),
                        radius: isHovering ? 12 : 6,
                        x: 0,
                        y: isHovering ? 6 : 3
                    )
            }
            .scaleEffect(isPressed ? 0.95 : (isHovering ? 1.02 : 1.0))
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(animationDelay), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Supporting Types

fileprivate struct AccionData {
    let titulo: String
    let subtitulo: String
    let icono: String
    let color: Color
    let gradiente: LinearGradient
    let accion: () -> Void
}

#Preview {
    AccionesRapidasModernas(
        onAgregarAporte: { print("Agregar aporte") },
        onRegistrarDeuda: { print("Registrar deuda") },
        onRegistrarAhorro: { print("Registrar ahorro") },
        onCerrarMes: { print("Cerrar mes") }
    )
    .preferredColorScheme(.light)
    .padding()
}
