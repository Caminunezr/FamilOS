//
//  ConfiguracionCategoriasView.swift
//  FamilOS
//
//  Created on 27/06/2025.
//

import SwiftUI

struct ConfiguracionCategoriasView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mostrarEditor = false
    @State private var categoriaParaEditar: CategoriaFinanciera? = nil
    @State private var mostrarGestorProveedores = false
    @State private var categoriaParaProveedores: CategoriaFinanciera? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente
                backgroundView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Lista de categorías
                        categoriasSection
                        
                        // Botón para agregar nueva categoría
                        botonAgregarCategoria
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $mostrarEditor) {
            EditorCategoriaView(categoria: categoriaParaEditar)
        }
        .sheet(isPresented: $mostrarGestorProveedores) {
            if let categoria = categoriaParaProveedores {
                GestorProveedoresView(categoria: categoria)
            }
        }
    }
    
    // MARK: - Fondo
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.indigo.opacity(0.8),
                Color.purple.opacity(0.6),
                Color.black.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "gear")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text("Configuración de Categorías")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                
                Text("Gestiona las categorías financieras y sus proveedores")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Sección de categorías
    private var categoriasSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.white.opacity(0.9))
                Text("Categorías Disponibles")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(CategoriaFinanciera.allCases, id: \.self) { categoria in
                    tarjetaCategoria(categoria)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func tarjetaCategoria(_ categoria: CategoriaFinanciera) -> some View {
        VStack(spacing: 12) {
            // Icono y nombre
            VStack(spacing: 8) {
                Circle()
                    .fill(categoria.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: categoria.icono)
                            .font(.title2)
                            .foregroundColor(categoria.color)
                    )
                
                Text(categoria.nombre)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Número de proveedores
            Text("\(categoria.proveedoresComunes.count) proveedores")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            // Botones de acción
            HStack(spacing: 8) {
                Button(action: {
                    categoriaParaEditar = categoria
                    mostrarEditor = true
                }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                        )
                }
                
                Button(action: {
                    categoriaParaProveedores = categoria
                    mostrarGestorProveedores = true
                }) {
                    Image(systemName: "person.2")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.3))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(categoria.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Botón agregar categoría
    private var botonAgregarCategoria: some View {
        Button(action: {
            categoriaParaEditar = nil
            mostrarEditor = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Agregar Nueva Categoría")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0.8),
                                Color.blue.opacity(0.6)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Vista del Editor de Categoría
struct EditorCategoriaView: View {
    @Environment(\.dismiss) private var dismiss
    let categoria: CategoriaFinanciera?
    
    @State private var nombre: String = ""
    @State private var descripcion: String = ""
    @State private var iconoSeleccionado: String = "folder"
    @State private var colorSeleccionado: Color = .blue
    @State private var proveedoresPersonalizados: [String] = []
    @State private var nuevoProveedor: String = ""
    
    private let iconosDisponibles = [
        "lightbulb", "drop", "wifi", "phone", "car", "house",
        "cart", "heart", "gamecontroller2", "book", "pill",
        "leaf", "pawprint", "graduationcap", "folder"
    ]
    
    private let coloresDisponibles: [Color] = [
        .blue, .green, .red, .orange, .purple, .pink,
        .yellow, .indigo, .mint, .teal, .cyan, .brown
    ]
    
    var esNuevaCategoria: Bool {
        categoria == nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Formulario
                        formularioSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(esNuevaCategoria ? "Crear" : "Guardar") {
                        guardarCategoria()
                    }
                    .disabled(nombre.isEmpty)
                    .foregroundColor(nombre.isEmpty ? .gray : .white)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            cargarDatos()
        }
    }
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.purple.opacity(0.8),
                Color.blue.opacity(0.6),
                Color.black.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(colorSeleccionado.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: iconoSeleccionado)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(colorSeleccionado)
                )
                .shadow(color: colorSeleccionado.opacity(0.5), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text(esNuevaCategoria ? "Nueva Categoría" : "Editar Categoría")
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
                
                Text(esNuevaCategoria ? "Crea una nueva categoría financiera" : "Modifica los detalles de la categoría")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var formularioSection: some View {
        VStack(spacing: 20) {
            // Información básica
            seccionFormulario("Información Básica", icono: "info.circle") {
                VStack(spacing: 16) {
                    campoTexto("Nombre", texto: $nombre, placeholder: "Ej: Servicios Básicos")
                    campoTexto("Descripción", texto: $descripcion, placeholder: "Descripción opcional")
                }
            }
            
            // Apariencia
            seccionFormulario("Apariencia", icono: "paintbrush") {
                VStack(spacing: 16) {
                    selectorIcono
                    selectorColor
                }
            }
            
            // Proveedores personalizados
            seccionFormulario("Proveedores Personalizados", icono: "person.2") {
                VStack(spacing: 16) {
                    agregadorProveedor
                    listaProveedores
                }
            }
        }
    }
    
    private func seccionFormulario<Content: View>(_ titulo: String, icono: String, @ViewBuilder contenido: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icono)
                    .foregroundColor(.white.opacity(0.9))
                Text(titulo)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            VStack(spacing: 16) {
                contenido()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    private func campoTexto(_ titulo: String, texto: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            TextField(placeholder, text: texto)
                .textFieldStyle(EstiloCampoGlass())
        }
    }
    
    private var selectorIcono: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icono")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(iconosDisponibles, id: \.self) { icono in
                    Button(action: {
                        iconoSeleccionado = icono
                    }) {
                        Image(systemName: icono)
                            .font(.title2)
                            .foregroundColor(iconoSeleccionado == icono ? colorSeleccionado : .white.opacity(0.6))
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(iconoSeleccionado == icono ? colorSeleccionado.opacity(0.2) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(iconoSeleccionado == icono ? colorSeleccionado : Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var selectorColor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(Array(coloresDisponibles.enumerated()), id: \.offset) { index, color in
                    Button(action: {
                        colorSeleccionado = color
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: colorSeleccionado == color ? 3 : 0)
                            )
                            .scaleEffect(colorSeleccionado == color ? 1.2 : 1.0)
                            .animation(.spring(), value: colorSeleccionado)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var agregadorProveedor: some View {
        HStack(spacing: 12) {
            TextField("Nuevo proveedor...", text: $nuevoProveedor)
                .textFieldStyle(EstiloCampoGlass())
            
            Button(action: {
                agregarProveedor()
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .disabled(nuevoProveedor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private var listaProveedores: some View {
        VStack(spacing: 8) {
            if proveedoresPersonalizados.isEmpty {
                Text("No hay proveedores personalizados")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(proveedoresPersonalizados.enumerated()), id: \.offset) { index, proveedor in
                    HStack {
                        Text(proveedor)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            proveedoresPersonalizados.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private func cargarDatos() {
        if let categoria = categoria {
            nombre = categoria.nombre
            descripcion = categoria.descripcion
            iconoSeleccionado = categoria.icono
            colorSeleccionado = categoria.color
            // Aquí cargaríamos los proveedores personalizados desde UserDefaults o Core Data
        }
    }
    
    private func agregarProveedor() {
        let proveedor = nuevoProveedor.trimmingCharacters(in: .whitespacesAndNewlines)
        if !proveedor.isEmpty && !proveedoresPersonalizados.contains(proveedor) {
            proveedoresPersonalizados.append(proveedor)
            nuevoProveedor = ""
        }
    }
    
    private func guardarCategoria() {
        // Aquí implementaremos la lógica para guardar en UserDefaults o Core Data
        // Por ahora solo cerramos el modal
        dismiss()
    }
}

#Preview {
    ConfiguracionCategoriasView()
}
