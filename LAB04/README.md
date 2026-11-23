# Laboratorio 04 – Implementación de un SoC Zynq-7000

**Asignatura:** Electrónica Digital 2  
**Plataforma de Hardware:** Digilent Zybo Z7-10 (Zynq-7000)  
**Herramientas:** AMD Vivado & Vitis IDE  

**Integrantes:**
* *Nombre del Estudiante 1*
* *Nombre del Estudiante 2*

---

## 1. Introducción y Objetivos

Un **System on Chip (SoC)** integra en un mismo circuito integrado un sistema de procesamiento completo junto con lógica digital programable. En el caso del dispositivo **Zynq-7000** presente en la tarjeta **Zybo Z7-10**, la arquitectura se divide en dos dominios principales:

1. **Processing System (PS):** Sistema embebido basado en un procesador **ARM Cortex-A9**, memoria caché, controlador DDR y periféricos estándar donde se ejecuta software en lenguaje C.
2. **Programmable Logic (PL):** Tejido FPGA (Serie 7) compuesto por LUTs, Flip-Flops y bloques de memoria **BRAM**, donde se implementan periféricos y lógica personalizada.

### Objetivos de la práctica
* Implementar un SoC mediante la herramienta *Block Design* de Vivado integrando el PS y la PL.
* Comprender la interconexión entre procesador, memoria BRAM y periféricos GPIO a través del protocolo de buses **AXI**.
* Exportar una plataforma de hardware (`.xsa`) desde Vivado hacia Vitis IDE.
* Compilar y ejecutar una aplicación embebida en C sobre el procesador ARM para controlar periféricos físicos (LEDs y botones).

---

## 2. Arquitectura del Sistema

La comunicación entre el procesador ARM (**PS**) y los periféricos implementados en la FPGA (**PL**) se realiza mediante el estándar **AXI (Advanced eXtensible Interface)**, gestionado por un bloque *AXI Interconnect*.

| Bloque IP / Componente | Dominio | Función en el sistema |
| :--- | :---: | :--- |
| **ZYNQ7 Processing System** | PS | Núcleo ARM Cortex-A9 encargado de ejecutar el código `main.c`, generar el reloj del sistema (`FCLK_CLK0`) y la señal de reset (`FCLK_RESET0_N`). |
| **AXI Interconnect** | PL | Conmutador de buses que permite al puerto maestro del procesador (`M_AXI_GP0`) comunicarse con múltiples esclavos (`M00_AXI` y `M01_AXI`). |
| **AXI BRAM Controller** | PL | Traduce las transacciones del bus AXI hacia la interfaz nativa de memoria interna de la FPGA. |
| **Block Memory Generator** | PL | Bloque de memoria RAM interna (BRAM) accesible desde el procesador mediante direcciones de memoria mapeadas. |
| **AXI GPIO** | PL | Interfaz de entrada/salida de propósito general conectada a los 4 botones y 4 LEDs de la tarjeta Zybo Z7-10. |
| **Processor System Reset** | PL | Sincroniza y distribuye las señales de reinicio (*reset* activo en bajo) para todos los bloques AXI. |

---

## 3. Procedimiento Paso a Paso

### 3.1 Instalación e integración de la Zybo Z7-10 en Vivado
Para que Vivado reconozca automáticamente la distribución de pines y periféricos de la tarjeta de desarrollo, se instalaron los archivos de placa (*Board Files*) proporcionados por Digilent:

1. Se descargó el repositorio oficial de placas de Digilent (`vivado-boards`).
2. Se copió únicamente la carpeta correspondiente a **`zybo-z7-10`** dentro del directorio de instalación de Vivado:
   ```text
   <Ruta_Instalacion_Vivado>/data/boards/board_files/
   ```
3. Se reinició Vivado para cargar la definición de la tarjeta en el catálogo.

> **[ESPACIO PARA IMAGEN 1]**  
> *Insertar captura de la carpeta `zybo-z7-10` ubicada en el directorio `board_files` o de la selección de la tarjeta en Vivado:*  
> `![Instalación Board Files Zybo Z7-10](img/01_instalacion_board.png)`

---

### 3.2 Creación del Proyecto y Diseño del SoC (Block Design)
1. **Creación del proyecto:** Se creó un nuevo proyecto RTL en Vivado seleccionando la pestaña **Boards** en la ventana *Default Part* y eligiendo **Zybo Z7-10**.
2. **Creación del diagrama:** En el panel izquierdo (*IP INTEGRATOR*), se seleccionó **Create Block Design**.
3. **Adición de bloques IP:** Mediante la opción *Add IP* (`+`), se añadieron los siguientes módulos:
   * `ZYNQ7 Processing System`
   * `Processor System Reset`
   * `AXI Interconnect` (configurado con 1 puerto esclavo `S00_AXI` y 2 puertos maestros `M00_AXI`, `M01_AXI`)
   * `AXI BRAM Controller` (configurado con 1 interfaz BRAM)
   * `Block Memory Generator`
4. **Adición de periféricos físicos:** Desde la pestaña **Board**, se agregaron los componentes **4 Buttons** y **4 LEDs**, unificándolos dentro del bloque `axi_gpio_0`.
5. **Interconexión del sistema:**
   * **Reloj (`FCLK_CLK0`):** Conectado a `M_AXI_GP0_ACLK`, `slowest_sync_clk` y a todos los pines `ACLK` de los bloques AXI.
   * **Reset:** `FCLK_RESET0_N` conectado a `ext_reset_in`, y `peripheral_aresetn` distribuido a todos los pines `ARESETN` de los periféricos.
   * **Buses de datos:** `M_AXI_GP0` conectado a `S00_AXI`; `M00_AXI` conectado a `axi_bram_ctrl_0/S_AXI`; `M01_AXI` conectado a `axi_gpio_0/S_AXI`; y `BRAM_PORTA` conectado entre el controlador y el generador de memoria.
6. Finalmente, se ejecutó **Regenerate Layout** para organizar visualmente la arquitectura.

<img width="1627" height="1101" alt="image" src="https://github.com/user-attachments/assets/cdf8fda5-2176-4b3a-b1e2-22e69098adb8" />

---

### 3.3 Configuración del Mapa de Memoria (Address Editor)
Para que el procesador ARM pueda leer y escribir en los periféricos de la PL, cada interfaz esclava AXI debe tener asignado un rango único de direcciones físicas:

1. Se abrió la pestaña **Address Editor** dentro de la ventana del diagrama.
2. Haciendo clic derecho sobre un espacio vacío, se seleccionó **Assign** para asignar automáticamente las direcciones base.
3. Para optimizar el espacio de direccionamiento de los periféricos de entrada/salida, se modificó el rango (**Range**) de `/axi_gpio_0/S_AXI` de **`64K`** a **`4K`**.

<img width="1115" height="221" alt="image" src="https://github.com/user-attachments/assets/4cc646ef-72bf-446c-a35e-84bbd6098215" />


---

### 3.4 Generación del Wrapper, Block Automation y Bitstream
1. **HDL Wrapper:** En la ventana *Sources*, se hizo clic derecho sobre el diseño de bloques y se seleccionó **Create HDL Wrapper** con la opción *Let Vivado manage wrapper and auto-update*.
2. **Block Automation:** En la barra superior del diagrama se ejecutó **Run Block Automation** para configurar automáticamente los puertos externos `DDR` y `FIXED_IO` hacia los pines físicos de la Zybo Z7-10.
3. **Síntesis, Implementación y Bitstream:** Se ejecutó **Generate Bitstream** hasta obtener el archivo de configuración de la FPGA sin errores.
4. **Exportación de Hardware:** Mediante **File $\rightarrow$ Export $\rightarrow$ Export Hardware** (marcando la casilla **Include bitstream**), se generó el archivo `.xsa` necesario para Vitis.

> **[ESPACIO PARA IMAGEN 4]**  
> *Insertar captura de la generación exitosa del Bitstream o de la ventana Export Hardware Platform:*  
> `![Exportación de Hardware XSA](img/04_export_hardware.png)`

---

### 3.5 Desarrollo y Ejecución de Software en Vitis IDE
1. **Apertura y Workspace:** Se inició Vitis desde Vivado (**Tools $\rightarrow$ Launch Vitis IDE**) y se definió una carpeta limpia como *Workspace*.
2. **Creación de la Plataforma (*Platform Component*):**
   * Se seleccionó el flujo **Hardware Design** cargando el archivo `.xsa` exportado.
   * En la configuración del sistema se eligió el sistema operativo **`standalone`** (*bare-metal*) y el procesador **`ps7_cortexa9_0`**.
3. **Creación de la Aplicación (*Application Component*):**
   * Se creó una aplicación vacía (*Empty Application*) asociada a la plataforma y al dominio `standalone_ps7_cortexa9_0`.
   * Se importó el archivo fuente `main.c` ubicado en la carpeta `src/` de este laboratorio.
4. **Compilación y Despliegue:**
   * Se conectó la tarjeta **Zybo Z7-10** mediante USB con el jumper **JP5** en modo **JTAG**.
   * En el panel **FLOW**, se ejecutó **Build** para compilar el proyecto y posteriormente **Run** para programar la FPGA y cargar el ejecutable en el procesador ARM.

> **[ESPACIO PARA IMAGEN 5]**  
> *Insertar captura de Vitis IDE mostrando la compilación exitosa (Build) sin errores:*  
> `![Compilación en Vitis IDE](img/05_vitis_build.png)`

---

## 4. Resultados y Funcionamiento Físico

Al ejecutar el programa en la **Zybo Z7-10**, se verificó la correcta integración entre el procesador ARM (**PS**) y los periféricos en la FPGA (**PL**):

* **Operación de salida (LEDs):** El programa ejecutado en el Cortex-A9 escribe periódicamente sobre los registros del controlador `AXI GPIO`, haciendo que los 4 LEDs de la tarjeta parpadeen de forma continua.
* **Operación de entrada (Botones):** Al presionar cualquiera de los 4 pulsadores (`BTN0` a `BTN3`), el procesador lee el estado del canal de entrada del GPIO y mantiene encendido de forma fija el LED correspondiente mientras el botón permanezca pulsado.
* **Acceso a memoria:** Se validó la comunicación a través del bus AXI hacia la memoria `BRAM` configurada en el mapa de direcciones.

> **[ESPACIO PARA IMAGEN 6]**  
> *Insertar fotografía de la tarjeta Zybo Z7-10 funcionando (mostrando los LEDs encendidos al presionar los botones):*  
> `![Montaje físico Zybo Z7-10 funcionando](img/06_funcionamiento_zybo.jpg)`

### Conclusiones
* *(Agrega aquí 2 o 3 conclusiones breves sobre lo aprendido en la integración PS-PL, el uso de buses AXI y la diferencia entre diseñar en Vivado frente a programar en Vitis).*

---

## 5. Referencias
* AMD / Xilinx. *Zynq-7000 SoC Technical Reference Manual (UG585)*.
* Digilent Inc. *Zybo Z7 Reference Manual & Vivado Board Files*.
* FPGAs for Beginners. (2023). *Zynq Part 1: Vivado block diagram (no Verilog/VHDL necessary!)*. YouTube.
