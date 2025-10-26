#!/bin/bash
export LANG=C.UTF-8

# Colores para la salida en consola
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0;0m' # Sin color

echo "--------------------------------------------------------"
echo "Iniciando validacion de Laboratorio - G3 (Gestor Tareas API)..."
echo "--------------------------------------------------------"

# Variable de control de errores
FAILED=0
# RUTA BASE (Ajusta 'com/poo/lab3' si tu paquete es diferente)
BASE_PATH="src/main/java/com/poo/lab3"

# --- PASO 1: VERIFICAR ESTRUCTURA DE PAQUETES Y ARCHIVOS REQUERIDOS ---
echo -e "\n${YELLOW}PASO 1: Verificando la estructura de archivos de la API...${NC}"

# Se valida la existencia de las clases clave
REQUIRED_PATHS=(
    "$BASE_PATH/model"
    "$BASE_PATH/service"
    "$BASE_PATH/controller"
    "$BASE_PATH/dto"
    "$BASE_PATH/model/TipoTarea.java"
    "$BASE_PATH/model/Tarea.java"
    "$BASE_PATH/dto/TareaRequest.java"
    "$BASE_PATH/dto/TareaResponse.java"
    "$BASE_PATH/dto/CompletarTareaResponse.java"
    "$BASE_PATH/service/IAccionAlCompletar.java"
    "$BASE_PATH/service/NotificarEmail.java"
    "$BASE_PATH/service/ArchivarTarea.java"
    "$BASE_PATH/service/TareaService.java"
    "$BASE_PATH/controller/TareaController.java"
)

STRUCTURE_OK=true
for path in "${REQUIRED_PATHS[@]}"; do
    # Validacion para directorios
    if [[ "$path" != *.java && ! -d "$path" ]]; then
        echo -e "${RED}Paquete Requerido NO ENCONTRADO: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    # Validacion para archivos
    elif [[ "$path" == *.java && ! -f "$path" ]]; then
        echo -e "${RED}Clase o Interfaz Requerida NO ENCONTRADA: $path${NC}"
        FAILED=1
        STRUCTURE_OK=false
    fi
done

if [ "$STRUCTURE_OK" = true ]; then
    echo -e "${GREEN}La estructura de paquetes y clases es correcta.${NC}"
fi


# --- PASO 2: VERIFICAR USO DE ANOTACIONES Y MÉTODOS REQUERIDOS ---
echo -e "\n${YELLOW}PASO 2: Verificando el diseno de clases y metodos (Spring & Lombok)...${NC}"
if [ ! -d "$BASE_PATH" ]; then
    echo -e "${RED}No se puede continuar porque el directorio base '$BASE_PATH' no existe.${NC}"
    exit 1
fi
ALL_FILES=$(find "$BASE_PATH" -name "*.java")

# 2.1 Verificacion de anotaciones clave de Spring y Lombok
REQUIRED_ANNOTATIONS=(
    "@Data"
    "@NoArgsConstructor"
    "@AllArgsConstructor"
    "@Service"
    "@RestController"
    "@RequestMapping"
    "@PostMapping"
    "@RequestBody"
    "@ResponseStatus"
    "@GetMapping"
    "@PathVariable"
    "@RequestParam"
    "@PatchMapping"
)

ANNOTATIONS_OK=true
for annotation in "${REQUIRED_ANNOTATIONS[@]}"; do
    if ! grep -q -R "$annotation" "$BASE_PATH"; then
        echo -e "${RED}REQUISITO FALLIDO: No se encontro uso de la anotacion: '$annotation'.${NC}"
        FAILED=1
        ANNOTATIONS_OK=false
    fi
done

if [ "$ANNOTATIONS_OK" = true ]; then
    echo -e "${GREEN}Uso de anotaciones clave (@RestController, @Service, @Data...) detectado.${NC}"
fi

# 2.2 Verificacion de metodos clave
echo "" # Linea en blanco
REQUIRED_METHODS=(
    "crearTarea"
    "getTareasPendientes"
    "marcarTareaComoCompletada"
    "ejecutar"
    "getTipoAccion"
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

# --- PASO 3: VERIFICAR ENDPOINTS EN EL CONTROLADOR ---
echo -e "\n${YELLOW}PASO 3: Verificando los Endpoints REST en el Controlador...${NC}"
CONTROLLER_FILE="$BASE_PATH/controller/TareaController.java"

if [ ! -f "$CONTROLLER_FILE" ]; then
    echo -e "${RED}No se puede verificar endpoints, el controlador no existe en: $CONTROLLER_FILE${NC}"
    FAILED=1
else
    ENDPOINTS_OK=true
    # Endpoint 1: POST /api/tareas (Rubrica dice @PostMapping sin path)
    if ! grep -q -E '@PostMapping' "$CONTROLLER_FILE"; then
        echo -e "${RED}ENDPOINT FALLIDO: No se encontro el @PostMapping en $CONTROLLER_FILE.${NC}"
        FAILED=1
        ENDPOINTS_OK=false
    fi

    # Endpoint 2: GET /api/tareas/pendientes
    if ! grep -q -E '@GetMapping.*"/pendientes"' "$CONTROLLER_FILE"; then
        echo -e "${RED}ENDPOINT FALLIDO: No se encontro el GET a '/pendientes' en $CONTROLLER_FILE.${NC}"
        FAILED=1
        ENDPOINTS_OK=false
    fi

    # Endpoint 3: PATCH /api/tareas/{id}/completar
    if ! grep -q -E '@PatchMapping.*"/{id}/completar"' "$CONTROLLER_FILE"; then
        echo -e "${RED}ENDPOINT FALLIDO: No se encontro el PATCH a '/{id}/completar' en $CONTROLLER_FILE.${NC}"
        FAILED=1
        ENDPOINTS_OK=false
    fi

    if [ "$ENDPOINTS_OK" = true ]; then
        echo -e "${GREEN}Todos los Endpoints y parametros requeridos fueron encontrados.${NC}"
    fi
fi

# --- PASO 4: COMPILAR TODO EL PROYECTO (MAVEN) ---
echo -e "\n${YELLOW}PASO 4: Compilando el proyecto con Maven...${NC}"

# Redirigimos la salida normal a /dev/null para solo mostrar errores
COMPILE_OUTPUT=$(mvn clean package -DskipTests 2>&1)

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR DE COMPILACION (MAVEN). Revisa tu codigo o pom.xml:${NC}"
    # Mostramos solo las ultimas 15 lineas del error para no saturar
    echo "$COMPILE_OUTPUT" | tail -n 15
    FAILED=1
else
    echo -e "${GREEN}Compilacion con Maven exitosa.${NC}"
fi

# --- PASO 5: MOSTRAR RESULTADO FINAL ---
echo -e "\n--------------------------------------------------------"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Verificacion completada exitosamente.${NC}"
    echo "El codigo cumple con todos los requisitos de estructura, diseno API y compilacion."
    exit 0
else
    echo -e "${RED}Se encontraron errores durante la validacion.${NC}"
    echo "Revisa los mensajes anteriores para corregir tu entrega."
    exit 1
fi