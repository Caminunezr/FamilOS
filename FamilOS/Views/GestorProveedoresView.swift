//
//  GestorProveedoresView.swift
//  FamilOS
//
//  Created on 27/06/2025.
//

import SwiftUI

struct GestorProveedoresView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = CategoriaProveedorManager.shared
    let categoria: CategoriaFinanciera
    
    @State private var nuevoProveedor: String = ""
    @State private var mostrandoConfirmacion = false
    @State private var proveedorParaEliminar: String? = nil
    @State private var searchText: String = ""
    
    private var proveedoresFiltrados: [String] {
        let todosProveedores = manager.obtenerProveedores(para: categoria)
        if searchText.isEmpty {
            return todosProveedores
        } else {
            return todosProveedores.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var proveedoresPersonalizados: [String] {
        manager.obtenerProveedoresPersonalizados(para: categoria)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                VStack(spacing: 0) {
                    // Header personalizado
                    headerSection
                    
                    // Contenido principal
                    ScrollView {
                        VStack(spacing: 24) {
                            // Búsqueda
                            busquedaSection
                            
                            // Agregar proveedor
                            agregarProveedorSection
                            
                            // Lista de proveedores
                            proveedoresSection
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button("Atrás") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Los datos se cargan automáticamente desde el manager
        }
        .alert("Eliminar Proveedor", isPresented: $mostrandoConfirmacion) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let proveedor = proveedorParaEliminar {
                    eliminarProveedor(proveedor)
                }
            }
        } message: {
            if let proveedor = proveedorParaEliminar {
                Text("¿Estás seguro de que deseas eliminar '\(proveedor)'?")
            }
        }
    }
    
    // MARK: - Fondo
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                categoria.colorPrimario.opacity(0.8),
                categoria.colorPrimario.opacity(0.4),
                Color.black.opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Barra superior con botón cerrar
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Información de la categoría
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: categoria.icono)
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("Proveedores de \(categoria.rawValue)")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Gestiona los proveedores disponibles para esta categoría")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Búsqueda
    private var busquedaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("Buscar proveedores...", text: $searchText)
                    .foregroundColor(.white)
                    .placeholder(when: searchText.isEmpty) {
                        Text("Buscar proveedores...")
                            .foregroundColor(.white.opacity(0.5))
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Agregar proveedor
    private var agregarProveedorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundColor(.white.opacity(0.9))
                Text("Agregar Proveedor")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    TextField("Nombre del proveedor...", text: $nuevoProveedor)
                        .foregroundColor(.white)
                        .placeholder(when: nuevoProveedor.isEmpty) {
                            Text("Nombre del proveedor...")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    
                    Button(action: {
                        agregarProveedor()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.3))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.green, lineWidth: 1)
                                    )
                            )
                    }
                    .disabled(nuevoProveedor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(nuevoProveedor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
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
    
    // MARK: - Lista de proveedores
    private var proveedoresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.white.opacity(0.9))
                Text("Proveedores (\(proveedoresFiltrados.count))")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            
            VStack(spacing: 12) {
                if proveedoresFiltrados.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(proveedoresFiltrados.enumerated()), id: \.offset) { index, proveedor in
                        tarjetaProveedor(proveedor, esPersonalizado: proveedoresPersonalizados.contains(proveedor))
                    }
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
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.4))
            
            Text(searchText.isEmpty ? "No hay proveedores disponibles" : "No se encontraron proveedores")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(searchText.isEmpty ? "Agrega un nuevo proveedor para comenzar" : "Intenta con una búsqueda diferente")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    private func tarjetaProveedor(_ proveedor: String, esPersonalizado: Bool) -> some View {
        HStack(spacing: 16) {
            // Icono
            Circle()
                .fill(esPersonalizado ? Color.orange.opacity(0.2) : categoria.colorPrimario.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: esPersonalizado ? "person.badge.plus" : "building.2")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(esPersonalizado ? .orange : categoria.colorPrimario)
                )
            
            // Información
            VStack(alignment: .leading, spacing: 4) {
                Text(proveedor)
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white)
                
                Text(esPersonalizado ? "Proveedor personalizado" : "Proveedor predeterminado")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Botón eliminar (solo para personalizados)
            if esPersonalizado {
                Button(action: {
                    proveedorParaEliminar = proveedor
                    mostrandoConfirmacion = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    Circle()
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Indicador de predeterminado
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Funciones
    private func agregarProveedor() {
        let proveedor = nuevoProveedor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !proveedor.isEmpty else { return }
        
        manager.agregarProveedor(proveedor, a: categoria)
        nuevoProveedor = ""
    }
    
    private func eliminarProveedor(_ proveedor: String) {
        manager.eliminarProveedor(proveedor, de: categoria)
        proveedorParaEliminar = nil
    }
}

// MARK: - Extension para placeholder en TextField
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    GestorProveedoresView(categoria: .luz)
}
