#!/bin/bash

# Colores para la salida en consola
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0;0m' # Sin color

echo "-------------------------------------------"
echo "🚀 Iniciando validación de Laboratorio Gestor de Tareas..."
echo "-------------------------------------------"

# --- PASO 1: VERIFICAR LA ESTRUCTURA DE ARCHIVOS REQUERIDA ---
echo "✅ PASO 1: Verificando estructura de archivos..."
BASE_PATH="src/main/java/org/laboratorio1"
TAREA_FILE="$BASE_PATH/model/Tarea.java"
SERVICIO_FILE="$BASE_PATH/service/GestorTareas.java"
MAIN_FILE="$BASE_PATH/controller/Main.java"

if [ ! -f "$TAREA_FILE" ] || [ ! -f "$SERVICIO_FILE" ] || [ ! -f "$MAIN_FILE" ]; then
    echo -e "${RED}❌ ERROR: Estructura de archivos incorrecta.${NC}"
    echo "Asegúrate de que existan los siguientes archivos en sus paquetes correctos:"
    [ ! -f "$TAREA_FILE" ] && echo "  - Falta: $TAREA_FILE"
    [ ! -f "$SERVICIO_FILE" ] && echo "  - Falta: $SERVICIO_FILE"
    [ ! -f "$MAIN_FILE" ] && echo "  - Falta: $MAIN_FILE"
    exit 1
fi
echo -e "${GREEN}Estructura de archivos correcta.${NC}"


# --- PASO 2: CREAR EL TEST RUNNER PARA VALIDAR LA LÓGICA ---
echo "✅ PASO 2: Creando el entorno de pruebas..."
cat <<EOF > TestRunner.java
import org.laboratorio1.model.Tarea;
import org.laboratorio1.service.GestorTareas;
import java.util.List;

public class TestRunner {
    public static void main(String[] args) {
        boolean allTestsPassed = true;

        // Prueba 1: Verificar la clase Tarea (constructor, getters, estado inicial)
        try {
            Tarea tarea = new Tarea(1, "Comprar pan");
            if (tarea.getId() != 1 || !tarea.getDescripcion().equals("Comprar pan") || tarea.isCompletada()) {
                System.out.println("❌ TEST 1 FALLIDO: La clase Tarea no se inicializa correctamente (constructor, getters o estado 'completada').");
                allTestsPassed = false;
            } else {
                System.out.println("✔️ TEST 1 APROBADO: La clase Tarea se instancia correctamente.");
            }
        } catch (Exception e) {
            System.out.println("❌ TEST 1 FALLIDO: Error crítico al usar la clase Tarea. " + e.getMessage());
            allTestsPassed = false;
        }

        // Prueba 2: Verificar GestorTareas.agregarTarea()
        try {
            GestorTareas gestor = new GestorTareas();
            gestor.agregarTarea("Lavar ropa");
            gestor.agregarTarea("Pasear al perro");
            List<Tarea> pendientes = gestor.obtenerTareasPendientes();
            if (pendientes.size() != 2 || !pendientes.get(0).getDescripcion().equals("Lavar ropa")) {
                 System.out.println("❌ TEST 2 FALLIDO: El método agregarTarea() o el ID automático no funcionan como se esperaba.");
                allTestsPassed = false;
            } else {
                System.out.println("✔️ TEST 2 APROBADO: El método agregarTarea() funciona.");
            }
        } catch (Exception e) {
            System.out.println("❌ TEST 2 FALLIDO: Error en agregarTarea() u obtenerTareasPendientes(). " + e.getMessage());
            allTestsPassed = false;
        }

        // Prueba 3: Verificar marcarTareaComoCompletada() y obtenerTareasPendientes()
        try {
            GestorTareas gestor = new GestorTareas();
            gestor.agregarTarea("Tarea A"); // id=1
            gestor.agregarTarea("Tarea B"); // id=2
            gestor.agregarTarea("Tarea C"); // id=3

            gestor.marcarTareaComoCompletada(2); // Completar Tarea B

            List<Tarea> pendientes = gestor.obtenerTareasPendientes();

            if (pendientes.size() != 2 || pendientes.get(0).getId() != 1 || pendientes.get(1).getId() != 3) {
                System.out.println("❌ TEST 3 FALLIDO: marcarTareaComoCompletada() u obtenerTareasPendientes() no filtran correctamente.");
                allTestsPassed = false;
            } else {
                System.out.println("✔️ TEST 3 APROBADO: Marcar como completada y obtener pendientes funciona.");
            }
        } catch (Exception e) {
            System.out.println("❌ TEST 3 FALLIDO: Error al marcar una tarea o filtrar pendientes. " + e.getMessage());
            allTestsPassed = false;
        }

        if (!allTestsPassed) {
            System.exit(1);
        }
    }
}
EOF
echo -e "${GREEN}Entorno de pruebas creado.${NC}"

# --- PASO 3: COMPILAR TODO EL PROYECTO ---
echo "✅ PASO 3: Compilando todo el código fuente..."
mkdir -p bin
COMPILE_OUTPUT=$(javac -encoding UTF-8 -d bin $(find . -name "*.java") 2>&1)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ERROR DE COMPILACIÓN. Revisa tu código.${NC}"
    echo "$COMPILE_OUTPUT"
    exit 1
fi
echo -e "${GREEN}Compilación exitosa.${NC}"

# --- PASO 4: EJECUTAR LAS PRUEBAS ---
echo "✅ PASO 4: Ejecutando pruebas de lógica..."
java -cp bin TestRunner
TEST_RESULT=$?

# --- PASO 5: MOSTRAR RESULTADO FINAL ---
echo "-------------------------------------------"
if [ $TEST_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Verificación completada. Todos los tests pasaron exitosamente.${NC}"
    echo "Tu entrega ha sido recibida y procesada."
    exit 0
else
    echo -e "${RED}❌ Se encontraron errores durante la validación.${NC}"
    echo "Revisa los detalles de los tests en la salida anterior para identificar las inconsistencias."
    exit 1
fi