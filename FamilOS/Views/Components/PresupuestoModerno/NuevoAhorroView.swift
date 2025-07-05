import SwiftUI

struct NuevoAhorroView: View {
    @ObservedObject var viewModel: PresupuestoViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var nombre: String = ""
    @State private var monto: String = ""
    @State private var descripcion: String = ""
    @State private var fechaObjetivo = Date()
    @State private var categoria: CategoriaAhorro = .emergencia
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
            .navigationTitle("Nuevo Ahorro")
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
            Image(systemName: "banknote.fill")
                .font(.system(size: 50))
                .foregroundStyle(.blue)
            
            Text("Meta de Ahorro")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Establece una nueva meta de ahorro familiar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 20)
    }
    
    private var formularioView: some View {
        VStack(spacing: 20) {
            // Nombre del ahorro
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre de la meta")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Ej. Vacaciones familiares, Fondo de emergencia...", text: $nombre)
                    .textFieldStyle(.plain)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    }
            }
            
            // Monto objetivo
            VStack(alignment: .leading, spacing: 8) {
                Text("Monto objetivo")
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
            
            // Categoría
            VStack(alignment: .leading, spacing: 8) {
                Text("Categoría")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Categoría", selection: $categoria) {
                    ForEach(CategoriaAhorro.allCases, id: \.self) { cat in
                        HStack {
                            Image(systemName: cat.icono)
                                .foregroundStyle(cat.color)
                            Text(cat.nombre)
                        }
                        .tag(cat)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                }
            }
            
            // Fecha objetivo
            VStack(alignment: .leading, spacing: 8) {
                Text("Fecha objetivo")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                DatePicker("", selection: $fechaObjetivo, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.ultraThinMaterial)
                            .stroke(.secondary.opacity(0.3), lineWidth: 1)
                    }
            }
            
            // Descripción
            VStack(alignment: .leading, spacing: 8) {
                Text("Descripción (opcional)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Detalles sobre esta meta de ahorro...", text: $descripcion, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.plain)
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
                Image(systemName: "lightbulb")
                    .foregroundStyle(.blue)
                
                Text("Las metas de ahorro te ayudan a planificar gastos futuros")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
            
            if let montoDouble = Double(monto), montoDouble > 0 {
                let diasRestantes = Calendar.current.dateComponents([.day], from: Date(), to: fechaObjetivo).day ?? 0
                let ahorroDiario = diasRestantes > 0 ? montoDouble / Double(diasRestantes) : 0
                
                if diasRestantes > 0 {
                    HStack {
                        Text("Ahorro diario requerido:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(ahorroDiario.formatearComoMoneda())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
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
            Button(action: guardarAhorro) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "target")
                    }
                    
                    Text("Crear Meta de Ahorro")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.gradient)
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
    
    private var formularioValido: Bool {
        !nombre.isEmpty &&
        !monto.isEmpty &&
        (Double(monto) ?? 0) > 0 &&
        fechaObjetivo > Date()
    }
    
    // MARK: - Funciones
    
    private func configurarDatosIniciales() {
        // Configurar fecha objetivo por defecto (3 meses desde hoy)
        fechaObjetivo = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    }
    
    private func guardarAhorro() {
        guard formularioValido else { return }
        
        guard let montoDouble = Double(monto) else {
            mostrarError(mensaje: "El monto debe ser un número válido")
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Simulate creating a savings goal for now
                // In the future, this would call a real method on the ViewModel
                print("Creating savings goal: \(nombre) for \(montoDouble)")
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    mostrarError(mensaje: error.localizedDescription)
                }
            }
        }
    }
    
    private func mostrarError(mensaje: String) {
        mensajeError = mensaje
        mostrarError = true
    }
}

// MARK: - Enums de apoyo

enum CategoriaAhorro: String, CaseIterable {
    case emergencia = "emergencia"
    case vacaciones = "vacaciones"
    case educacion = "educacion"
    case hogar = "hogar"
    case salud = "salud"
    case tecnologia = "tecnologia"
    case vehiculo = "vehiculo"
    case inversion = "inversion"
    case otros = "otros"
    
    var nombre: String {
        switch self {
        case .emergencia: return "Fondo de Emergencia"
        case .vacaciones: return "Vacaciones"
        case .educacion: return "Educación"
        case .hogar: return "Hogar"
        case .salud: return "Salud"
        case .tecnologia: return "Tecnología"
        case .vehiculo: return "Vehículo"
        case .inversion: return "Inversión"
        case .otros: return "Otros"
        }
    }
    
    var color: Color {
        switch self {
        case .emergencia: return .red
        case .vacaciones: return .orange
        case .educacion: return .blue
        case .hogar: return .green
        case .salud: return .pink
        case .tecnologia: return .purple
        case .vehiculo: return .brown
        case .inversion: return .mint
        case .otros: return .gray
        }
    }
    
    var icono: String {
        switch self {
        case .emergencia: return "exclamationmark.shield"
        case .vacaciones: return "airplane"
        case .educacion: return "graduationcap"
        case .hogar: return "house"
        case .salud: return "heart"
        case .tecnologia: return "laptopcomputer"
        case .vehiculo: return "car"
        case .inversion: return "chart.line.uptrend.xyaxis"
        case .otros: return "ellipsis.circle"
        }
    }
}

// MARK: - Preview
#Preview {
    NuevoAhorroView(viewModel: PresupuestoViewModel())
}
