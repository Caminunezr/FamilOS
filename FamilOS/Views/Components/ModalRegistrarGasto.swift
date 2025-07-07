import SwiftUI

struct ModalRegistrarGasto: View {
    @EnvironmentObject var presupuestoViewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var descripcion = ""
    @State private var montoTexto = ""
    @State private var categoriaSeleccionada = "General"
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    let mesInfo: MesPresupuestoInfo
    
    private let categorias = ["General", "Comida", "Transporte", "Servicios", "Entretenimiento", "Salud", "Educación", "Otros"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Registrar Gasto")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Mes de \(mesInfo.nombre) \(mesInfo.año)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Formulario
                VStack(spacing: 16) {
                    // Descripción
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Descripción")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Ej: Compra de supermercado", text: $descripcion)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Monto
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monto")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("0", text: $montoTexto)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Categoría
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Categoría")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Menu {
                            ForEach(categorias, id: \.self) { categoria in
                                Button(categoria) {
                                    categoriaSeleccionada = categoria
                                }
                            }
                        } label: {
                            HStack {
                                Text(categoriaSeleccionada)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.gray.opacity(0.1))
                            )
                        }
                    }
                    
                    // Información de saldo disponible
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saldo Disponible")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("$\(mesInfo.saldoDisponible, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            if let monto = Double(montoTexto), monto > 0 {
                                VStack(alignment: .trailing) {
                                    Text("Después del gasto:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("$\(mesInfo.saldoDisponible - monto, specifier: "%.0f")")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(mesInfo.saldoDisponible >= monto ? .green : .red)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray.opacity(0.15))
                        )
                    }
                }
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                }
                
                Spacer()
                
                // Botones
                HStack(spacing: 16) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                    
                    Button(isLoading ? "Registrando..." : "Registrar Gasto") {
                        registrarGasto()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading || descripcion.isEmpty || montoTexto.isEmpty || Double(montoTexto) == nil || Double(montoTexto) ?? 0 <= 0)
                }
            }
            .padding(24)
        }
    }
    
    private func registrarGasto() {
        guard let monto = Double(montoTexto), monto > 0 else {
            errorMessage = "Por favor ingresa un monto válido"
            return
        }
        
        guard !descripcion.isEmpty else {
            errorMessage = "Por favor ingresa una descripción"
            return
        }
        
        guard monto <= mesInfo.saldoDisponible else {
            errorMessage = "El monto excede el saldo disponible"
            return
        }
        
        let responsable = authViewModel.usuarioActual?.nombre ?? "Usuario"
        
        Task {
            do {
                await MainActor.run {
                    isLoading = true
                    errorMessage = ""
                }
                
                try await presupuestoViewModel.registrarGasto(
                    descripcion: descripcion,
                    monto: monto,
                    categoria: categoriaSeleccionada,
                    responsable: responsable
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ModalRegistrarGasto(mesInfo: MesPresupuestoInfo.ejemplo)
        .environmentObject(PresupuestoViewModel())
        .environmentObject(AuthViewModel())
}
