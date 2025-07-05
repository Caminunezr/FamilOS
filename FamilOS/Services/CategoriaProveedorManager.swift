//
//  CategoriaProveedorManager.swift
//  FamilOS
//
//  Created on 27/06/2025.
//

import Foundation
import SwiftUI

/// Gestor para la persistencia y manipulación de categorías y proveedores personalizados
class CategoriaProveedorManager: ObservableObject {
    static let shared = CategoriaProveedorManager()
    
    private let userDefaults = UserDefaults.standard
    private let categoriasCustomKey = "categorias_personalizadas"
    private let proveedoresCustomKey = "proveedores_personalizados"
    
    @Published var categoriasPersonalizadas: [CategoriaPersonalizada] = []
    @Published var proveedoresPersonalizados: [String: [String]] = [:]
    
    private init() {
        cargarDatos()
    }
    
    // MARK: - Categorías Personalizadas
    
    /// Estructura para categorías personalizadas creadas por el usuario
    struct CategoriaPersonalizada: Codable, Identifiable {
        var id: String
        var nombre: String
        var descripcion: String
        var icono: String
        var colorHex: String
        var proveedoresComunes: [String]
        var fechaCreacion: Date
        var fechaModificacion: Date
        
        init(nombre: String, descripcion: String, icono: String, colorHex: String, proveedoresComunes: [String] = [], fechaCreacion: Date = Date(), fechaModificacion: Date = Date()) {
            self.id = UUID().uuidString
            self.nombre = nombre
            self.descripcion = descripcion
            self.icono = icono
            self.colorHex = colorHex
            self.proveedoresComunes = proveedoresComunes
            self.fechaCreacion = fechaCreacion
            self.fechaModificacion = fechaModificacion
        }
        
        var color: Color {
            Color(hex: colorHex) ?? .blue
        }
    }
    
    /// Agrega una nueva categoría personalizada
    func agregarCategoriaPersonalizada(
        nombre: String,
        descripcion: String,
        icono: String,
        color: Color,
        proveedores: [String] = []
    ) {
        let categoria = CategoriaPersonalizada(
            nombre: nombre,
            descripcion: descripcion,
            icono: icono,
            colorHex: color.toHex(),
            proveedoresComunes: proveedores
        )
        
        categoriasPersonalizadas.append(categoria)
        guardarCategorias()
    }
    
    /// Actualiza una categoría personalizada existente
    func actualizarCategoriaPersonalizada(_ categoria: CategoriaPersonalizada) {
        if let index = categoriasPersonalizadas.firstIndex(where: { $0.id == categoria.id }) {
            var categoriaActualizada = categoria
            categoriaActualizada.fechaModificacion = Date()
            categoriasPersonalizadas[index] = categoriaActualizada
            guardarCategorias()
        }
    }
    
    /// Elimina una categoría personalizada
    func eliminarCategoriaPersonalizada(_ categoria: CategoriaPersonalizada) {
        categoriasPersonalizadas.removeAll { $0.id == categoria.id }
        guardarCategorias()
    }
    
    // MARK: - Proveedores Personalizados
    
    /// Obtiene todos los proveedores para una categoría (predeterminados + personalizados)
    func obtenerProveedores(para categoria: CategoriaFinanciera) -> [String] {
        let proveedoresPredeterminados = categoria.proveedoresComunes
        let proveedoresCustom = proveedoresPersonalizados[categoria.rawValue] ?? []
        return proveedoresPredeterminados + proveedoresCustom
    }
    
    /// Obtiene solo los proveedores personalizados para una categoría
    func obtenerProveedoresPersonalizados(para categoria: CategoriaFinanciera) -> [String] {
        return proveedoresPersonalizados[categoria.rawValue] ?? []
    }
    
    /// Agrega un proveedor personalizado a una categoría
    func agregarProveedor(_ proveedor: String, a categoria: CategoriaFinanciera) {
        let categoriaKey = categoria.rawValue
        var proveedores = proveedoresPersonalizados[categoriaKey] ?? []
        
        // Verificar que no existe ya (case insensitive)
        let proveedorLimpio = proveedor.trimmingCharacters(in: .whitespacesAndNewlines)
        let todosProveedores = obtenerProveedores(para: categoria)
        
        if !todosProveedores.contains(where: { $0.lowercased() == proveedorLimpio.lowercased() }) {
            proveedores.append(proveedorLimpio)
            proveedoresPersonalizados[categoriaKey] = proveedores
            guardarProveedores()
        }
    }
    
    /// Elimina un proveedor personalizado de una categoría
    func eliminarProveedor(_ proveedor: String, de categoria: CategoriaFinanciera) {
        let categoriaKey = categoria.rawValue
        var proveedores = proveedoresPersonalizados[categoriaKey] ?? []
        proveedores.removeAll { $0 == proveedor }
        proveedoresPersonalizados[categoriaKey] = proveedores
        guardarProveedores()
    }
    
    /// Actualiza un proveedor personalizado
    func actualizarProveedor(antiguo: String, nuevo: String, en categoria: CategoriaFinanciera) {
        let categoriaKey = categoria.rawValue
        var proveedores = proveedoresPersonalizados[categoriaKey] ?? []
        
        if let index = proveedores.firstIndex(of: antiguo) {
            proveedores[index] = nuevo.trimmingCharacters(in: .whitespacesAndNewlines)
            proveedoresPersonalizados[categoriaKey] = proveedores
            guardarProveedores()
        }
    }
    
    // MARK: - Sugerencias y Autocompletado
    
    /// Busca proveedores que coincidan con un texto de búsqueda
    func buscarProveedores(texto: String, en categoria: CategoriaFinanciera? = nil) -> [String] {
        let textoBusqueda = texto.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textoBusqueda.isEmpty else { return [] }
        
        var resultados: [String] = []
        
        if let categoria = categoria {
            // Buscar solo en una categoría específica
            let proveedores = obtenerProveedores(para: categoria)
            resultados = proveedores.filter { $0.lowercased().contains(textoBusqueda) }
        } else {
            // Buscar en todas las categorías
            for categoria in CategoriaFinanciera.allCases {
                let proveedores = obtenerProveedores(para: categoria)
                let coincidencias = proveedores.filter { $0.lowercased().contains(textoBusqueda) }
                resultados.append(contentsOf: coincidencias)
            }
        }
        
        // Eliminar duplicados y ordenar
        return Array(Set(resultados)).sorted()
    }
    
    /// Obtiene sugerencias basadas en uso frecuente
    func obtenerSugerenciasProveedores(para categoria: CategoriaFinanciera, limite: Int = 5) -> [String] {
        // Por ahora devolvemos los más comunes, pero en el futuro podríamos
        // trackear el uso y devolver los más utilizados
        let proveedores = obtenerProveedores(para: categoria)
        return Array(proveedores.prefix(limite))
    }
    
    // MARK: - Persistencia
    
    private func cargarDatos() {
        cargarCategorias()
        cargarProveedores()
    }
    
    private func cargarCategorias() {
        if let data = userDefaults.data(forKey: categoriasCustomKey),
           let categorias = try? JSONDecoder().decode([CategoriaPersonalizada].self, from: data) {
            self.categoriasPersonalizadas = categorias
        }
    }
    
    private func guardarCategorias() {
        if let data = try? JSONEncoder().encode(categoriasPersonalizadas) {
            userDefaults.set(data, forKey: categoriasCustomKey)
        }
    }
    
    private func cargarProveedores() {
        if let data = userDefaults.data(forKey: proveedoresCustomKey),
           let proveedores = try? JSONDecoder().decode([String: [String]].self, from: data) {
            self.proveedoresPersonalizados = proveedores
        }
    }
    
    private func guardarProveedores() {
        if let data = try? JSONEncoder().encode(proveedoresPersonalizados) {
            userDefaults.set(data, forKey: proveedoresCustomKey)
        }
    }
    
    // MARK: - Utilidades
    
    /// Limpia todos los datos persistidos (útil para testing o reset)
    func limpiarTodosDatos() {
        categoriasPersonalizadas.removeAll()
        proveedoresPersonalizados.removeAll()
        userDefaults.removeObject(forKey: categoriasCustomKey)
        userDefaults.removeObject(forKey: proveedoresCustomKey)
    }
    
    /// Exporta la configuración a un diccionario
    func exportarConfiguracion() -> [String: Any] {
        return [
            "categorias_personalizadas": categoriasPersonalizadas.compactMap { try? JSONEncoder().encode($0) }.map { String(data: $0, encoding: .utf8) ?? "" },
            "proveedores_personalizados": proveedoresPersonalizados,
            "fecha_exportacion": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    /// Importa configuración desde un diccionario
    func importarConfiguracion(_ configuracion: [String: Any]) {
        // Implementación de importación
        // Por ahora solo como placeholder para futuras funcionalidades
    }
}

// MARK: - Extensions de utilidad

extension Color {
    /// Convierte un Color a representación hexadecimal
    func toHex() -> String {
        let nsColor = NSColor(self)
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    /// Inicializa un Color desde representación hexadecimal
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}
