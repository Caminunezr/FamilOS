import SwiftUI

struct ConfiguracionMonedaPreview: View {
    @StateObject private var configuracionService = ConfiguracionService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ejemplo de Configuración de Moneda")
                .font(.title)
                .fontWeight(.bold)
            
            // Selector de moneda
            VStack(alignment: .leading, spacing: 12) {
                Text("Selecciona tu moneda:")
                    .font(.headline)
                
                Picker("Moneda", selection: $configuracionService.monedaSeleccionada) {
                    ForEach(TipoMoneda.allCases) { moneda in
                        HStack {
                            Text(moneda.bandera)
                            Text(moneda.nombre)
                            Text("(\(moneda.simbolo))")
                        }
                        .tag(moneda)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Divider()
            
            // Ejemplos de montos formateados
            VStack(alignment: .leading, spacing: 16) {
                Text("Ejemplos de formato:")
                    .font(.headline)
                
                HStack {
                    Text("Aporte:")
                    Spacer()
                    Text(50000.0.formatearComoMoneda())
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Gasto:")
                    Spacer()
                    Text(25000.0.formatearComoMoneda())
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Balance:")
                    Spacer()
                    Text(25000.0.formatearComoMoneda())
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: 400)
    }
}

#Preview {
    ConfiguracionMonedaPreview()
}
