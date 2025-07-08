import SwiftUI

struct NuevoAporteView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var monto: String = ""
    @State private var comentario: String = ""
    @State private var usuarioSeleccionado: String = ""
    @State private var isLoading = false
    @State private var mostrarError = false
    @State private var mensajeError = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Formulario
                    formularioView
                    
                    // Botones de acción
                    botonesAccion
                }
                .padding(24)
            }
            .navigationTitle("Nuevo Aporte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            configurarDatosIniciales()
        }
        .alert("Error", isPresented: $mostrarError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mensajeError)
        }
    }
    
    // MARK: - Subvistas
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)
            
            Text("Registrar Aporte")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Agrega un nuevo aporte al presupuesto familiar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    private var formularioView: some View {
        VStack(spacing: 20) {
            // Selector de usuario
            VStack(alignment: .leading, spacing: 8) {
                Text("Usuario")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Menu {
                    ForEach(usuariosDisponibles, id: \.self) { usuario in
                        Button(usuario) {
                            usuarioSeleccionado = usuario
                        }
                    }
                } label: {
                    HStack {
                        Text(usuarioSeleccionado.isEmpty ? "Seleccionar usuario" : usuarioSeleccionado)
                            .foregroundStyle(usuarioSeleccionado.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    }
                }
            }
            
            // Campo de monto
            VStack(alignment: .leading, spacing: 8) {
                Text("Monto")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    TextField("0.00", text: $monto)
                        .font(.title2)
                        .fontWeight(.medium)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                }
            }
            
            // Campo de comentario
            VStack(alignment: .leading, spacing: 8) {
                Text("Comentario (opcional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Describe el motivo del aporte...", text: $comentario, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    }
            }
            
            // Información adicional
            infoAdicional
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        }
    }
    
    private var infoAdicional: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.blue)
                
                Text("El aporte se agregará al presupuesto del mes actual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            if viewModel.presupuestoActual != nil {
                HStack {
                    Text("Presupuesto actual:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.totalAportes.formatearComoMoneda())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.blue.opacity(0.1))
        }
    }
    
    private var botonesAccion: some View {
        VStack(spacing: 16) {
            Button(action: guardarAporte) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                    
                    Text("Registrar Aporte")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.gradient)
                }
                .foregroundStyle(.white)
            }
            .disabled(!formularioValido || isLoading)
            .opacity(formularioValido ? 1.0 : 0.6)
            
            Button("Cancelar") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var usuariosDisponibles: [String] {
        // Temporal: devolver usuario actual ya que familiaActual no está disponible
        return [authViewModel.usuarioActual?.nombre ?? "Usuario"]
    }
    
    private var formularioValido: Bool {
        !usuarioSeleccionado.isEmpty &&
        !monto.isEmpty &&
        (Double(monto) ?? 0) > 0
    }
    
    // MARK: - Funciones
    
    private func configurarDatosIniciales() {
        if usuariosDisponibles.count == 1 {
            usuarioSeleccionado = usuariosDisponibles.first ?? ""
        } else if let usuarioActual = authViewModel.usuarioActual?.nombre,
                  usuariosDisponibles.contains(usuarioActual) {
            usuarioSeleccionado = usuarioActual
        }
    }
    
    private func guardarAporte() {
        guard formularioValido else { return }
        
        guard let montoDouble = Double(monto) else {
            mostrarError(mensaje: "El monto debe ser un número válido")
            return
        }
        
        isLoading = true
        
        Task {
            // Crear el objeto Aporte
            let nuevoAporte = Aporte(
                presupuestoId: viewModel.presupuestoActual?.id ?? "",
                usuario: usuarioSeleccionado,
                monto: montoDouble,
                comentario: comentario.isEmpty ? "" : comentario
            )
            
            viewModel.agregarAporte(nuevoAporte)
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
    
    private func mostrarError(mensaje: String) {
        mensajeError = mensaje
        mostrarError = true
    }
}

// MARK: - Preview
#Preview {
    NuevoAporteView(viewModel: PresupuestoViewModel())
        .environmentObject(AuthViewModel())
}
