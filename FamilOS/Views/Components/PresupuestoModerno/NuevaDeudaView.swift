import SwiftUI

struct NuevaDeudaView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var descripcion: String = ""
    @State private var monto: String = ""
    @State private var responsable: String = ""
    @State private var categoria: String = ""
    @State private var fechaVencimiento = Date()
    @State private var prioridad: PrioridadDeuda = .media
    @State private var isLoading = false
    @State private var mostrarError = false
    @State private var mensajeError = ""
    
    private let categorias = [
        "Alimentación", "Transporte", "Servicios", "Entretenimiento",
        "Salud", "Educación", "Ropa", "Hogar", "Otros"
    ]
    
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
            .navigationTitle("Nuevo Gasto")
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
            Image(systemName: "minus.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("Registrar Gasto")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Agrega un nuevo gasto al presupuesto familiar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    private var formularioView: some View {
        VStack(spacing: 20) {
            // Descripción
            VStack(alignment: .leading, spacing: 8) {
                Text("Descripción")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("¿En qué se gastó el dinero?", text: $descripcion, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.plain)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    }
            }
            
            // Monto
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
            
            // Responsable y Categoría en fila
            HStack(spacing: 16) {
                // Responsable
                VStack(alignment: .leading, spacing: 8) {
                    Text("Responsable")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Menu {
                        ForEach(usuariosDisponibles, id: \.self) { usuario in
                            Button(usuario) {
                                responsable = usuario
                            }
                        }
                    } label: {
                        HStack {
                            Text(responsable.isEmpty ? "Seleccionar" : responsable)
                                .foregroundStyle(responsable.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                            
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
                
                // Categoría
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categoría")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Menu {
                        ForEach(categorias, id: \.self) { cat in
                            Button(cat) {
                                categoria = cat
                            }
                        }
                    } label: {
                        HStack {
                            Text(categoria.isEmpty ? "Seleccionar" : categoria)
                                .foregroundStyle(categoria.isEmpty ? .secondary : .primary)
                                .lineLimit(1)
                            
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
            }
            
            // Fecha de vencimiento
            VStack(alignment: .leading, spacing: 8) {
                Text("Fecha de vencimiento")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                DatePicker("", selection: $fechaVencimiento, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    }
            }
            
            // Prioridad
            VStack(alignment: .leading, spacing: 8) {
                Text("Prioridad")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Prioridad", selection: $prioridad) {
                    ForEach(PrioridadDeuda.allCases, id: \.self) { p in
                        HStack {
                            Image(systemName: p.icono)
                                .foregroundStyle(p.color)
                            Text(p.nombre)
                        }
                        .tag(p)
                    }
                }
                .pickerStyle(.segmented)
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
                    .foregroundStyle(.orange)
                
                Text("El gasto se restará del presupuesto disponible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            if viewModel.presupuestoActual != nil {
                HStack {
                    Text("Saldo disponible:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.saldoDisponible.formatearComoMoneda())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(viewModel.saldoDisponible >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.orange.opacity(0.1))
        }
    }
    
    private var botonesAccion: some View {
        VStack(spacing: 16) {
            Button(action: guardarDeuda) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "minus.circle.fill")
                    }
                    
                    Text("Registrar Gasto")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.orange.gradient)
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
        // For now, return a default user until familiaActual is properly accessed
        return ["Usuario"]
    }
    
    private var formularioValido: Bool {
        !descripcion.isEmpty &&
        !monto.isEmpty &&
        !responsable.isEmpty &&
        !categoria.isEmpty &&
        (Double(monto) ?? 0) > 0
    }
    
    // MARK: - Funciones
    
    private func configurarDatosIniciales() {
        if usuariosDisponibles.count == 1 {
            responsable = usuariosDisponibles.first ?? ""
        }
        
        // Configurar fecha de vencimiento por defecto (7 días desde hoy)
        fechaVencimiento = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
    
    private func guardarDeuda() {
        guard formularioValido else { return }
        
        guard let montoDouble = Double(monto) else {
            mostrarError(mensaje: "El monto debe ser un número válido")
            return
        }
        
        isLoading = true
        
        Task {
            // Create a DeudaItem instance
            let nuevaDeuda = DeudaItem(
                descripcion: descripcion,
                monto: montoDouble,
                categoria: categoria,
                fechaRegistro: Date(),
                esPagado: false,
                responsable: responsable
            )
            
            viewModel.agregarDeuda(nuevaDeuda)
            
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

// MARK: - Enums de apoyo

enum PrioridadDeuda: String, CaseIterable {
    case alta = "alta"
    case media = "media"
    case baja = "baja"
    
    var nombre: String {
        switch self {
        case .alta: return "Alta"
        case .media: return "Media"
        case .baja: return "Baja"
        }
    }
    
    var color: Color {
        switch self {
        case .alta: return .red
        case .media: return .orange
        case .baja: return .green
        }
    }
    
    var icono: String {
        switch self {
        case .alta: return "exclamationmark.triangle.fill"
        case .media: return "exclamationmark.circle.fill"
        case .baja: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    NuevaDeudaView(viewModel: PresupuestoViewModel())
}
