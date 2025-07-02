import SwiftUI

// Vista de prueba para verificar el funcionamiento del modal
struct TestModalView: View {
    @State private var mostrarModal = false
    
    // Mock de datos de prueba
    @State private var cuentaPrueba = Cuenta(
        monto: 1000.0,
        proveedor: "Proveedor Test",
        fechaVencimiento: Date(),
        categoria: "Test",
        creador: "Usuario Test"
    )
    
    // ViewModels simulados
    @State private var cuentasViewModel = CuentasViewModel()
    @State private var presupuestoViewModel = PresupuestoViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Prueba del Modal de Pago Avanzado")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Cuenta de prueba: \(cuentaPrueba.proveedor)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Mostrar Modal de Pago Avanzado") {
                mostrarModal = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $mostrarModal) {
            ModalRegistrarPagoAvanzado(
                cuenta: cuentaPrueba,
                cuentasViewModel: cuentasViewModel,
                presupuestoViewModel: presupuestoViewModel
            )
        }
    }
}

struct TestModalView_Previews: PreviewProvider {
    static var previews: some View {
        TestModalView()
    }
}
