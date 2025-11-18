#!/bin/bash
export LANG=C.UTF-8

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;0m'

echo "--------------------------------------------------------"
echo "Iniciando validación Lab 4: Bóveda Bancaria (Prioridades & Binary)"
echo "--------------------------------------------------------"

FAILED=0

# --- CONFIGURACIÓN DE RUTA ---
# Ajusta esto según el paquete del estudiante
# Ejemplo: "src/main/java/com/poo/lab4"
BASE_PATH="src/main/java/com/poo/lab4"

echo -e "Buscando código fuente en: $BASE_PATH"

# --- PASO 1: VERIFICAR ESTRUCTURA DE PAQUETES (core, workers, app) ---
echo -e "\n${YELLOW}PASO 1: Verificando estructura de paquetes...${NC}"

REQUIRED_PATHS=(
    "$BASE_PATH/core"
    "$BASE_PATH/workers"
    "$BASE_PATH/app"
    "$BASE_PATH/core/CuentaBancaria.java"
    "$BASE_PATH/workers/CajeroRunnable.java"
    "$BASE_PATH/app/MainBanco.java"
)

STRUCTURE_OK=true
for path in "${REQUIRED_PATHS[@]}"; do
    if [[ "$path" != *.java && ! -d "$path" ]]; then
        echo -e "${RED}[FALTA RUTA] No encontrada: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    elif [[ "$path" == *.java && ! -f "$path" ]]; then
        echo -e "${RED}[FALTA ARCHIVO] No encontrado: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    fi
done

if [ "$STRUCTURE_OK" = true ]; then
    echo -e "${GREEN}Estructura de paquetes correcta (core/workers/app).${NC}"
fi

# --- PASO 2: VERIFICAR REQUISITOS DE CONCURRENCIA (PRIORIDADES) ---
echo -e "\n${YELLOW}PASO 2: Verificando lógica de Hilos y Prioridades...${NC}"

if [ ! -d "$BASE_PATH" ]; then
    echo -e "${RED}Directorio base no encontrado. Abortando.${NC}"
    exit 1
fi

MAIN_FILE="$BASE_PATH/app/MainBanco.java"

# 2.1 Validar Uso Manual de Hilos (No Executors aquí)
if [ -f "$MAIN_FILE" ]; then
    if ! grep -q "new Thread" "$MAIN_FILE"; then
        echo -e "${RED}[ERROR] MainBanco: No se encontró 'new Thread(...)'. En este lab se requiere creación manual de hilos.${NC}"
        FAILED=1
    fi

    # 2.2 Validar Prioridades (El objetivo principal del lab)
    if ! grep -q "setPriority" "$MAIN_FILE"; then
        echo -e "${RED}[ERROR CRÍTICO] MainBanco: No se está usando 'setPriority'.${NC}"
        FAILED=1
    fi

    if ! grep -q "MAX_PRIORITY" "$MAIN_FILE" || ! grep -q "MIN_PRIORITY" "$MAIN_FILE"; then
        echo -e "${RED}[ERROR] MainBanco: Debes usar las constantes Thread.MAX_PRIORITY y Thread.MIN_PRIORITY.${NC}"
        FAILED=1
    fi

    # 2.3 Validar Join (Sincronización de flujo)
    if ! grep -q ".join()" "$MAIN_FILE"; then
        echo -e "${RED}[ERROR] MainBanco: No se encontró '.join()'. El main debe esperar a los hilos antes de guardar el balance.${NC}"
        FAILED=1
    fi
fi

# 2.4 Validar Sincronización de la Cuenta
CUENTA_FILE="$BASE_PATH/core/CuentaBancaria.java"
if [ -f "$CUENTA_FILE" ]; then
    if ! grep -q "synchronized" "$CUENTA_FILE"; then
        echo -e "${RED}[ERROR] CuentaBancaria: Los métodos de transacción deben ser 'synchronized'.${NC}"
        FAILED=1
    fi
fi

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Lógica de Hilos (Manuales, Prioridades, Join, Sync) correcta.${NC}"
fi

# --- PASO 3: VERIFICAR PERSISTENCIA BINARIA (DATA STREAMS) ---
echo -e "\n${YELLOW}PASO 3: Verificando escritura binaria primitiva...${NC}"

# Buscamos el uso de DataOutputStream en Main o donde hayan puesto la lógica
ALL_JAVA_FILES=$(find "$BASE_PATH" -name "*.java")
BINARY_OK=true

if ! grep -q "DataOutputStream" $ALL_JAVA_FILES; then
    echo -e "${RED}[ERROR] Persistencia: No se encontró 'DataOutputStream'. Se requiere escritura binaria primitiva.${NC}"
    FAILED=1
    BINARY_OK=false
fi

if ! grep -q "writeDouble" $ALL_JAVA_FILES; then
    echo -e "${RED}[ERROR] Persistencia: No se encontró 'writeDouble'. El saldo debe guardarse como primitivo.${NC}"
    FAILED=1
    BINARY_OK=false
fi

if [ "$BINARY_OK" = true ]; then
    echo -e "${GREEN}Uso de DataOutputStream y primitivos detectado.${NC}"
fi

# --- PASO 4: COMPILAR ---
echo -e "\n${YELLOW}PASO 4: Compilando...${NC}"

COMPILE_OUTPUT=$(mvn clean package -DskipTests 2>&1)
MVN_EXIT_CODE=$?

if [ $MVN_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}ERROR DE COMPILACIÓN.${NC}"
    echo "$COMPILE_OUTPUT" | grep -E "ERROR|FAILURE" -A 2 | head -n 10
    FAILED=1
else
    echo -e "${GREEN}Compilación exitosa.${NC}"
fi

# --- RESULTADO ---
echo -e "\n--------------------------------------------------------"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✔ LABORATORIO APROBADO${NC}"
    echo "Excelente manejo de prioridades de hilos y archivos binarios."
    exit 0
else
    echo -e "${RED}✘ SE ENCONTRARON ERRORES${NC}"
    echo "Revisa los requisitos de prioridades y DataOutputStream."
    exit 1
fi
