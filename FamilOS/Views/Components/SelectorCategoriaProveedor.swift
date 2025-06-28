import SwiftUI

// MARK: - Selector de Categoría con Proveedores Dinámicos
struct SelectorCategoriaProveedor: View {
    @Binding var categoriaSeleccionada: CategoriaFinanciera
    @Binding var proveedorSeleccionado: String
    @StateObject private var manager = CategoriaProveedorManager.shared
    @State private var usarProveedorPersonalizado: Bool = false
    @State private var proveedorPersonalizado: String = ""
    @State private var mostrarSugerencias: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var fieldBackground: Color {
        colorScheme == .dark ? Color(.windowBackgroundColor) : Color(.controlBackgroundColor)
    }
    
    private var proveedoresDisponibles: [String] {
        manager.obtenerProveedores(para: categoriaSeleccionada)
    }
    
    private var sugerenciasProveedores: [String] {
        if proveedorPersonalizado.isEmpty {
            return manager.obtenerSugerenciasProveedores(para: categoriaSeleccionada, limite: 5)
        } else {
            return manager.buscarProveedores(texto: proveedorPersonalizado, en: categoriaSeleccionada)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Selector de Categoría
            categoriaPicker
            
            // Selector de Proveedor
            proveedorPicker
        }
    }
    
    // MARK: - Selector de Categoría
    private var categoriaPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Categoría")
                .foregroundColor(primaryTextColor.opacity(0.8))
                .font(.subheadline)
                .fontWeight(.medium)
            
            Menu {
                ForEach(CategoriaFinanciera.allCases, id: \.self) { categoria in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            categoriaSeleccionada = categoria
                            // Auto-seleccionar el primer proveedor cuando cambia la categoría
                            let proveedores = manager.obtenerProveedores(para: categoria)
                            if !proveedores.isEmpty {
                                proveedorSeleccionado = proveedores[0]
                                usarProveedorPersonalizado = false
                                proveedorPersonalizado = ""
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: categoria.icono)
                                .foregroundColor(categoria.colorPrimario)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(categoria.rawValue)
                                    .fontWeight(.medium)
                                Text(categoria.descripcion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if categoriaSeleccionada == categoria {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: categoriaSeleccionada.icono)
                        .foregroundColor(categoriaSeleccionada.colorPrimario)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(categoriaSeleccionada.rawValue)
                            .foregroundColor(primaryTextColor)
                            .fontWeight(.medium)
                        
                        Text(categoriaSeleccionada.descripcion)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(primaryTextColor.opacity(0.6))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(fieldBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(categoriaSeleccionada.colorPrimario.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Selector de Proveedor
    private var proveedorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proveedor")
                .foregroundColor(primaryTextColor.opacity(0.8))
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Proveedores disponibles en grid
            if !proveedoresDisponibles.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(proveedoresDisponibles, id: \.self) { proveedor in
                        ProveedorButton(
                            proveedor: proveedor,
                            isSelected: proveedorSeleccionado == proveedor && !usarProveedorPersonalizado,
                            colorCategoria: categoriaSeleccionada.colorPrimario,
                            esPersonalizado: !categoriaSeleccionada.proveedoresComunes.contains(proveedor),
                            action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    proveedorSeleccionado = proveedor
                                    usarProveedorPersonalizado = false
                                    proveedorPersonalizado = ""
                                    mostrarSugerencias = false
                                }
                            }
                        )
                    }
                }
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            // Opción para proveedor personalizado
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        usarProveedorPersonalizado.toggle()
                        if usarProveedorPersonalizado {
                            proveedorSeleccionado = proveedorPersonalizado
                            mostrarSugerencias = true
                        } else if !proveedoresDisponibles.isEmpty {
                            proveedorSeleccionado = proveedoresDisponibles[0]
                            mostrarSugerencias = false
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: usarProveedorPersonalizado ? "checkmark.square.fill" : "square")
                            .foregroundColor(usarProveedorPersonalizado ? categoriaSeleccionada.colorPrimario : primaryTextColor.opacity(0.6))
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Otro proveedor")
                            .foregroundColor(primaryTextColor)
                            .font(.subheadline)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            
            // Campo de texto para proveedor personalizado con sugerencias
            if usarProveedorPersonalizado {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Nombre del proveedor", text: Binding(
                        get: { proveedorPersonalizado },
                        set: { newValue in
                            proveedorPersonalizado = newValue
                            proveedorSeleccionado = newValue
                            mostrarSugerencias = !newValue.isEmpty
                        }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        // Agregar proveedor personalizado al manager si no existe
                        if !proveedorPersonalizado.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            manager.agregarProveedor(proveedorPersonalizado, a: categoriaSeleccionada)
                        }
                        mostrarSugerencias = false
                    }
                    
                    // Sugerencias dinámicas
                    if mostrarSugerencias && !sugerenciasProveedores.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sugerencias:")
                                .font(.caption)
                                .foregroundColor(primaryTextColor.opacity(0.6))
                            
                            ForEach(sugerenciasProveedores.prefix(3), id: \.self) { sugerencia in
                                Button(action: {
                                    proveedorPersonalizado = sugerencia
                                    proveedorSeleccionado = sugerencia
                                    mostrarSugerencias = false
                                }) {
                                    HStack {
                                        Text(sugerencia)
                                            .foregroundColor(primaryTextColor)
                                            .font(.caption)
                                        Spacer()
                                        Image(systemName: "arrow.up.left")
                                            .font(.caption2)
                                            .foregroundColor(primaryTextColor.opacity(0.5))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(fieldBackground.opacity(0.7))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .transition(.slide.combined(with: .opacity))
                    }
                }
                .transition(.slide.combined(with: .opacity))
            }
        }
    }
}

// MARK: - Botón de Proveedor Individual
struct ProveedorButton: View {
    let proveedor: String
    let isSelected: Bool
    let colorCategoria: Color
    let esPersonalizado: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var fieldBackground: Color {
        colorScheme == .dark ? Color(.windowBackgroundColor) : Color(.controlBackgroundColor)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: proveedor.iconoProveedor)
                    .foregroundColor(isSelected ? .white : colorCategoria)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(proveedor)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : primaryTextColor)
                    
                    if esPersonalizado {
                        Text("Personalizado")
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .orange)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? colorCategoria : fieldBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(colorCategoria.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Preview
struct SelectorCategoriaProveedor_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SelectorCategoriaProveedor(
                categoriaSeleccionada: .constant(.luz),
                proveedorSeleccionado: .constant("Enel")
            )
            .padding()
        }
        .frame(width: 400, height: 500)
        .preferredColorScheme(.light)
        
        VStack {
            SelectorCategoriaProveedor(
                categoriaSeleccionada: .constant(.internet),
                proveedorSeleccionado: .constant("Mundo")
            )
            .padding()
        }
        .frame(width: 400, height: 500)
        .preferredColorScheme(.dark)
    }
}
