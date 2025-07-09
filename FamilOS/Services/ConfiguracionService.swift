import Foundation
import SwiftUI

@MainActor
class ConfiguracionService: ObservableObject {
    @Published var monedaSeleccionada: TipoMoneda = .chileno
    @AppStorage("moneda_seleccionada") private var monedaGuardada: String = "CLP"
    
    static let shared = ConfiguracionService()
    
    private init() {
        // Cargar la moneda guardada al inicializar
        if let moneda = TipoMoneda.allCases.first(where: { $0.codigo == monedaGuardada }) {
            monedaSeleccionada = moneda
        }
    }
    
    func cambiarMoneda(_ nuevaMoneda: TipoMoneda) {
        monedaSeleccionada = nuevaMoneda
        monedaGuardada = nuevaMoneda.codigo
        
        // Notificar cambio para que todas las vistas se actualicen
        objectWillChange.send()
    }
}

enum TipoMoneda: String, CaseIterable, Identifiable {
    case chileno = "CLP"
    case dolar = "USD"
    case euro = "EUR"
    case peso_mexicano = "MXN"
    case peso_argentino = "ARS"
    case real_brasileno = "BRL"
    case peso_colombiano = "COP"
    case sol_peruano = "PEN"
    case libra = "GBP"
    case yen = "JPY"
    
    var id: String { self.rawValue }
    
    var codigo: String {
        return self.rawValue
    }
    
    var nombre: String {
        switch self {
        case .chileno: return "Peso Chileno"
        case .dolar: return "Dólar Estadounidense"
        case .euro: return "Euro"
        case .peso_mexicano: return "Peso Mexicano"
        case .peso_argentino: return "Peso Argentino"
        case .real_brasileno: return "Real Brasileño"
        case .peso_colombiano: return "Peso Colombiano"
        case .sol_peruano: return "Sol Peruano"
        case .libra: return "Libra Esterlina"
        case .yen: return "Yen Japonés"
        }
    }
    
    var simbolo: String {
        switch self {
        case .chileno: return "$"
        case .dolar: return "$"
        case .euro: return "€"
        case .peso_mexicano: return "$"
        case .peso_argentino: return "$"
        case .real_brasileno: return "R$"
        case .peso_colombiano: return "$"
        case .sol_peruano: return "S/"
        case .libra: return "£"
        case .yen: return "¥"
        }
    }
    
    var bandera: String {
        switch self {
        case .chileno: return "🇨🇱"
        case .dolar: return "🇺🇸"
        case .euro: return "🇪🇺"
        case .peso_mexicano: return "🇲🇽"
        case .peso_argentino: return "🇦🇷"
        case .real_brasileno: return "🇧🇷"
        case .peso_colombiano: return "🇨🇴"
        case .sol_peruano: return "🇵🇪"
        case .libra: return "🇬🇧"
        case .yen: return "🇯🇵"
        }
    }
    
    var localeIdentifier: String {
        switch self {
        case .chileno: return "es_CL"
        case .dolar: return "en_US"
        case .euro: return "es_ES"
        case .peso_mexicano: return "es_MX"
        case .peso_argentino: return "es_AR"
        case .real_brasileno: return "pt_BR"
        case .peso_colombiano: return "es_CO"
        case .sol_peruano: return "es_PE"
        case .libra: return "en_GB"
        case .yen: return "ja_JP"
        }
    }
}
