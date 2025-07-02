#!/bin/bash

# Script para actualizar las reglas de Firebase con soporte para aportes con tracking
# FASE 1: Implementación de tracking de aportes utilizados

echo "🔄 Actualizando reglas de Firebase para FASE 1: Tracking de Aportes..."

# Verificar si firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI no está instalado. Por favor instálalo con: npm install -g firebase-tools"
    exit 1
fi

# Verificar si estamos loggeados en Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ No estás loggeado en Firebase. Por favor ejecuta: firebase login"
    exit 1
fi

# Hacer backup de las reglas actuales
echo "📋 Creando backup de las reglas actuales..."
firebase database:get /.info/rules > firebase-rules-backup-$(date +%Y%m%d_%H%M%S).json

# Actualizar las reglas
echo "📤 Subiendo nuevas reglas..."
firebase deploy --only database

if [ $? -eq 0 ]; then
    echo "✅ Reglas de Firebase actualizadas exitosamente!"
    echo ""
    echo "📋 Cambios incluidos en FASE 1:"
    echo "   • Soporte para campo 'montoUtilizado' en aportes"
    echo "   • Validación de transacciones con 'aportesUtilizados'"
    echo "   • Índices mejorados para consultas de transacciones"
    echo ""
    echo "🎯 La aplicación ya puede:"
    echo "   • Rastrear cuánto se ha usado de cada aporte"
    echo "   • Calcular saldos disponibles automáticamente"
    echo "   • Registrar qué aportes se usaron en cada pago"
else
    echo "❌ Error al actualizar las reglas de Firebase"
    exit 1
fi
