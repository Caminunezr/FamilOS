#!/bin/bash

echo "🔄 Actualizando reglas de Firebase Realtime Database para aportes..."

# Verificar si firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI no está instalado. Instalando..."
    npm install -g firebase-tools
fi

# Verificar si el archivo de reglas existe
if [ ! -f "firebase-rules-aportes-updated.json" ]; then
    echo "❌ Archivo firebase-rules-aportes-updated.json no encontrado"
    exit 1
fi

echo "📋 Contenido de las nuevas reglas:"
cat firebase-rules-aportes-updated.json

echo ""
echo "🚀 Aplicando reglas a Firebase..."

# Aplicar las reglas usando Firebase CLI
firebase database:set / firebase-rules-aportes-updated.json --confirm

if [ $? -eq 0 ]; then
    echo "✅ Reglas de Firebase actualizadas exitosamente"
    echo "📊 Las actualizaciones de aportes en tiempo real ahora deberían funcionar correctamente"
else
    echo "❌ Error al actualizar las reglas de Firebase"
    echo "💡 Intenta aplicar las reglas manualmente desde la consola de Firebase:"
    echo "   1. Ve a https://console.firebase.google.com"
    echo "   2. Selecciona tu proyecto"
    echo "   3. Ve a Realtime Database > Reglas"
    echo "   4. Copia el contenido de firebase-rules-aportes-updated.json"
fi
