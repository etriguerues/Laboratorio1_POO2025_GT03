#!/bin/bash
export LANG=C.UTF-8

# Colores para la salida en consola
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;0m' # Sin color

echo "--------------------------------------------------------"
echo "Iniciando validacion de Laboratorio de Gestor de Tareas..."
echo "--------------------------------------------------------"

# Variable de control de errores
FAILED=0
# BASE_PATH para Laboratorio 2
BASE_PATH="src/main/java/org/laboratorio2"

# --- PASO 1: VERIFICAR NOMBRES DE PAQUETES Y CLASES REQUERIDAS ---
echo -e "\n${YELLOW}PASO 1: Verificando la estructura completa de paquetes y clases...${NC}"

# Define aqui todos los paquetes (directorios) y clases (archivos) que son obligatorios.
REQUIRED_PATHS=(
    "$BASE_PATH/model"
    "$BASE_PATH/service"
    "$BASE_PATH/controller"
    "$BASE_PATH/model/Tarea.java"
    "$BASE_PATH/model/TareaSimple.java"
    "$BASE_PATH/model/TareaConFechaLimite.java"
    "$BASE_PATH/service/IAccionAlCompletar.java"
    "$BASE_PATH/service/NotificarEmail.java"
    "$BASE_PATH/service/ArchivarTarea.java"
    "$BASE_PATH/service/GestorTareas.java"
    "$BASE_PATH/controller/Main.java"
)

STRUCTURE_OK=true
for path in "${REQUIRED_PATHS[@]}"; do
    if [[ "$path" != *.java && ! -d "$path" ]]; then
        echo -e "${RED}Paquete Requerido NO ENCONTRADO: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    elif [[ "$path" == *.java && ! -f "$path" ]]; then
        echo -e "${RED}Clase Requerida NO ENCONTRADA: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    fi
done

if [ "$STRUCTURE_OK" = true ]; then
    echo -e "${GREEN}La estructura de paquetes y clases es correcta.${NC}"
fi

# --- PASO 2: VERIFICAR USO DE CONCEPTOS Y METODOS OOP ---
echo -e "\n${YELLOW}PASO 2: Verificando el diseno de clases y metodos de OOP...${NC}"
if [ ! -d "$BASE_PATH" ]; then
    echo -e "${RED}No se puede continuar porque el directorio base '$BASE_PATH' no existe.${NC}"
    exit 1
fi
ALL_FILES=$(find "$BASE_PATH" -name "*.java")

# 2.1 Verificacion de Relaciones Especificas (Herencia e Implementacion)
REQUIRED_RELATIONSHIPS=(
    "TareaSimple.*extends.*Tarea"
    "TareaConFechaLimite.*extends.*Tarea"
    "NotificarEmail.*implements.*IAccionAlCompletar"
    "ArchivarTarea.*implements.*IAccionAlCompletar"
)

RELATIONSHIPS_OK=true
for pattern in "${REQUIRED_RELATIONSHIPS[@]}"; do
    # Usamos una expresion regular para ser flexibles con espacios y palabras como 'public'
    if ! grep -q -E "$pattern" $ALL_FILES; then
        # Mostramos un mensaje de error mas legible para el estudiante
        readable_pattern=$(echo "$pattern" | sed 's/\.\*/ /g')
        echo -e "${RED}REQUISITO FALLIDO: No se encontro la relacion esperada: '$readable_pattern'.${NC}"
        FAILED=1
        RELATIONSHIPS_OK=false
    fi
done

if [ "$RELATIONSHIPS_OK" = true ]; then
    echo -e "${GREEN}Todas las relaciones de herencia e implementacion son correctas.${NC}"
fi

# 2.2 Verificacion de palabras clave y metodos
echo "" # Linea en blanco para separar visualmente
if ! grep -q "abstract" $ALL_FILES; then
    echo -e "${RED}REQUISITO FALLIDO: No se encontro uso de 'abstract'.${NC}"; FAILED=1; else echo -e "${GREEN}Uso de 'abstract' detectado.${NC}"; fi
if ! grep -q "@Override" $ALL_FILES; then
    echo -e "${RED}REQUISITO FALLIDO: No se encontro uso de '@Override'.${NC}"; FAILED=1; else echo -e "${GREEN}Uso de '@Override' detectado.${NC}"; fi

REQUIRED_METHODS=(
    "mostrarDetalles"
    "ejecutar"
    "marcarTareaComoCompletada"
)

METHODS_OK=true
for method in "${REQUIRED_METHODS[@]}"; do
    if ! grep -q "$method(" $ALL_FILES; then
        echo -e "${RED}REQUISITO FALLIDO: No se encontro el metodo requerido: '$method()'.${NC}"
        FAILED=1
        METHODS_OK=false
    fi
done

if [ "$METHODS_OK" = true ]; then
    echo -e "${GREEN}Todos los metodos requeridos fueron encontrados.${NC}"
fi

# --- PASO 3: COMPILAR TODO EL PROYECTO ---
echo -e "\n${YELLOW}PASO 3: Compilando todo el codigo fuente...${NC}"
mkdir -p bin
COMPILE_OUTPUT=$(javac -encoding UTF-8 -cp src/main/java -d bin $(find src/main/java -name "*.java") 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR DE COMPILACION. Revisa tu codigo:${NC}"
    echo "$COMPILE_OUTPUT"
    FAILED=1
else
    echo -e "${GREEN}Compilacion exitosa.${NC}"
fi

# --- PASO 4: MOSTRAR RESULTADO FINAL ---
echo -e "\n--------------------------------------------------------"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Verificacion completada exitosamente.${NC}"
    echo "El codigo cumple con todos los requisitos de estructura, OOP y compilacion."
    exit 0
else
    echo -e "${RED}Se encontraron errores durante la validacion.${NC}"
    echo "Revisa los mensajes anteriores para corregir tu entrega."
    exit 1
fi