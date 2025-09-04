#!/bin/bash

# Colores para la salida en consola
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;0m' # Sin color

echo "-------------------------------------------"
echo "🚀 Iniciando validación de HelloWorld..."
echo "-------------------------------------------"

# --- PASO 1: ENCONTRAR EL ARCHIVO HelloWorld.java DINÁMICAMENTE ---
echo "✅ PASO 1: Buscando el archivo 'HelloWorld.java' en el proyecto..."

# Busca el archivo en cualquier subdirectorio
FILE_PATH=$(find . -name "HelloWorld.java")

if [ -z "$FILE_PATH" ]; then
    echo -e "${RED}❌ ERROR: No se encontró el archivo HelloWorld.java en el repositorio.${NC}"
    exit 1
fi
echo -e "${GREEN}Archivo encontrado en: '$FILE_PATH'${NC}"


# --- PASO 2: COMPILAR EL ARCHIVO JAVA ---
echo "✅ PASO 2: Compilando el código..."
COMPILE_OUTPUT=$(javac "$FILE_PATH" 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR DE COMPILACIÓN.${NC}"
    echo "Tu código tiene errores de sintaxis. Revisa los detalles:"
    echo "-------------------------------------------"
    echo "$COMPILE_OUTPUT"
    echo "-------------------------------------------"
    exit 1
fi
echo -e "${GREEN}Compilación exitosa.${NC}"


# --- PASO 3: DETERMINAR CLASSPATH Y NOMBRE DE CLASE ---
echo "✅ PASO 3: Preparando ejecución..."
# Asumimos una estructura estándar tipo Maven/Gradle (src/main/java)
# Si no la encuentra, usa el directorio actual.
if [[ "$FILE_PATH" == *"src/main/java/"* ]]; then
  CLASSPATH_ROOT="src/main/java"
else
  # Si no es una estructura estándar, buscaremos la raíz de otra forma
  # Para este caso simple, asumiremos que no hay una raíz de sources explícita
  # y que el paquete empieza desde la primera carpeta que contiene el .java
  CLASSPATH_ROOT="."
fi

# Extrae el nombre completo de la clase con su paquete (ej: org.laboratorio1.controller.HelloWorld)
# 1. Quita el CLASSPATH_ROOT del inicio
# 2. Quita la extensión .java del final
# 3. Reemplaza las barras '/' con puntos '.'
CLASS_NAME=$(echo "$FILE_PATH" | sed "s|^./$CLASSPATH_ROOT/||" | sed 's/\.java$//' | sed 's/\//\./g')

echo "Classpath detectado: '$CLASSPATH_ROOT'"
echo "Nombre de clase detectado: '$CLASS_NAME'"


# --- PASO 4: EJECUTAR Y VERIFICAR LA SALIDA ---
echo "✅ PASO 4: Ejecutando y verificando la salida..."
EXPECTED_OUTPUT="Hello world!"

# Ejecutamos java indicando el classpath (-cp) y el nombre completo de la clase
ACTUAL_OUTPUT=$(java -cp "$CLASSPATH_ROOT" "$CLASS_NAME")

if [ "$ACTUAL_OUTPUT" == "$EXPECTED_OUTPUT" ]; then
    echo -e "${GREEN}La salida en consola es correcta.${NC}"
    echo ""
    echo "-------------------------------------------"
    echo -e "${GREEN}🎉 ¡Felicidades! Tu programa funciona como se esperaba.${NC}"
    echo "-------------------------------------------"
    exit 0
else
    echo -e "${RED}❌ ERROR: La salida en consola no es la esperada.${NC}"
    echo -e "   - Salida esperada: ${YELLOW}'$EXPECTED_OUTPUT'${NC}"
    echo -e "   - Tu programa imprimió: ${YELLOW}'$ACTUAL_OUTPUT'${NC}"
    echo "Asegúrate de que la impresión sea exacta, incluyendo mayúsculas, minúsculas y espacios."
    exit 1
fi