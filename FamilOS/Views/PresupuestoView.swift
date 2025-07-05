import SwiftUI

struct PresupuestoView: View {
    @EnvironmentObject var viewModel: PresupuestoViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        CalendarioPresupuestoView()
            .environmentObject(viewModel)
            .environmentObject(authViewModel)
    }
}

// MARK: - Preview
#Preview {
    PresupuestoView()
        .environmentObject(PresupuestoViewModel())
        .environmentObject(AuthViewModel())
}
