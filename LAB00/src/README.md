# Lab ab00 — Introducción a Verilog, Simulación y Máquinas de Estados Finitos (FSM)

**Curso:** [Electrónica Digital II]

**Autores:** [Juan Carlos Salcedo Cabra, Jordy Andrey Samudio Garcia, Andrés Felipe Vega Bermeo]

**Universidad Nacional de Colombia — Sede Bogotá**

---

## 1. Objetivos

- Instalar y verificar el correcto funcionamiento de **Icarus Verilog** y **GTKWave**.
- Comprender la diferencia entre lógica combinacional y lógica secuencial.
- Diseñar e implementar **Máquinas de Estados Finitos (FSM)** sencillas en Verilog.
- Implementar sistemas que operan a lo largo de varios ciclos de reloj.
- Validar el comportamiento de los diseños mediante testbench y visualización de señales en GTKWave.

## 2. Entorno de trabajo

| Herramienta | Uso |
|---|---|
| Icarus Verilog (`iverilog`, `vvp`) | Compilación y simulación de los módulos HDL |
| GTKWave | Visualización de formas de onda (`.vcd`) |
| Visual Studio Code | Edición del código fuente |

**Smoke test:** antes de iniciar los ejercicios se compiló y simuló un módulo combinacional simple (`smoke_andor.v`), generando su `.vcd` y verificando las señales en GTKWave, con el fin de confirmar que el entorno de trabajo (Icarus Verilog + GTKWave) estaba correctamente instalado.

Comandos generales usados para compilar y simular cada ejercicio:

```bash
# Compilar
iverilog -o <nombre_tb>.vvp <testbench>.v <modulo>.v

# Simular (genera el .vcd)
vvp <nombre_tb>.vvp

# Visualizar ondas
gtkwave <archivo>.vcd
```

## 3. Estructura del repositorio

```
├── README.md
└── src/
    ├── semaforo.v
    ├── tb_semaforo.v
    ├── accumulator.v
    ├── tb_accumulator.v
    ├── serial_tx.v
    ├── tb_serial_tx.v
    └── waves/            # capturas de GTKWave
```

---

## 4. Ejercicio 1 — FSM de control: Semáforo simple

### Descripción

Semáforo vehicular controlado por una FSM síncrona de 4 estados (verde, amarillo previo al rojo, rojo y un segundo amarillo previo a volver a verde), donde cada estado permanece activo un número fijo de ciclos de reloj contados con un registro interno `count`.

### Entradas / Salidas

| Señal | Dirección | Descripción |
|---|---|---|
| `clk` | entrada | Reloj del sistema |
| `rst` | entrada | Reset síncrono/asíncrono, fuerza el estado `GREEN` |
| `green` | salida | Luz verde activa |
| `yellow1` | salida | Luz amarilla (transición verde → rojo) |
| `red` | salida | Luz roja activa |
| `yellow2` | salida | Luz amarilla (transición rojo → verde) |

### Diagrama de estados (ASM)

![Diagrama de estados del semáforo](DiagramaEstadosSemáforo.png)

| Estado | Salida activa | Condición de permanencia | Duración |
|---|---|---|---|
| S0 (`GREEN`) | `green = 1` | `count < 4` | 5 ciclos |
| S1 (`YELLOW1`) | `yellow1 = 1` | `count < 1` | 2 ciclos |
| S2 (`RED`) | `red = 1` | `count < 3` | 4 ciclos |
| S3 (`YELLOW2`) | `yellow2 = 1` | `count < 1` | 2 ciclos |

La FSM usa tres bloques `always`: registro de estado (secuencial), lógica de siguiente estado y del contador `count`/`next_count` (combinacional), y decodificación de salidas por estado (combinacional, una única salida activa a la vez).

### Resultado en GTKWave

![Simulación del semáforo en GTKWave](SimSemaforo.png)

**Observaciones:**
- Tras `rst`, el sistema arranca en `green = 1`, como exige la especificación.
- El contador `count` recorre correctamente los ciclos indicados en cada estado (000→100 en verde, 000→001 en cada amarillo, 000→011 en rojo) antes de reiniciarse en la siguiente transición.
- En todo momento solo una de las señales `green`, `yellow1`, `red` está en alto, cumpliendo la regla de exclusividad.
- Las duraciones medidas en la forma de onda coinciden con las especificadas: verde 5 ciclos, amarillo 2 ciclos, rojo 4 ciclos.

---



## Punto 3.2: Acumulador con FSM y Datapath (`accumulator.v`)

### 1. Descripción Técnica y Arquitectura HDL
Este sistema implementa un acumulador secuencial controlado por una Máquina de Estados Finitas (FSM) acoplada a una ruta de datos (Datapath). El sistema recibe un vector de entrada de datos `x[7:0]` y acumula su valor en el registro `acc[7:0]` seleccionando el flujo de operación según el vector de control `w[1:0]`.

#### Componentes Principales del Módulo:
* **Registro de Estado y Reset**: Bloque secuencial sincronizado con el flanco de subida de `clk`. Permite restablecer el sistema al estado inactivo `S0_IDLE` al activarse la señal de reset.
* **Lógica de Siguiente Estado**: Circuito combinacional que determina la transición entre estados evaluando el estado actual (`state`), el vector de selección `w[1:0]`, el contador interno (`cont`) y la condición de umbral ($acc \ge 20$).
* **Ruta de Datos (Datapath) y Contador**:
  * **Registro Acumulador (`acc[7:0]`)**: Almacena el resultado temporal y ejecuta la operación $acc \Leftarrow acc + x$.
  * **Contador de Iteraciones (`cont`)**: Incrementa en cada ciclo de acumulación para llevar el control de iteraciones fijas en las rutas correspondientes.
* **Lógica de Salidas**: Activa la bandera `done = 1` exclusivamente cuando la FSM alcanza el estado `S5_DONE`, manteniéndola en alto por exactamente un ciclo de reloj.

#### Tabla de Estados y Modos de Operación
| Estado | Código | Nombre | Descripción / Condición | Estado Siguiente |
| :--- | :---: | :--- | :--- | :--- |
| `S0` | `3'b000` | `S0_IDLE` | Reposo. Mantiene `done = 0`. Espera `start == 1`. | `S1_INIT` si `start == 1` |
| `S1` | `3'b001` | `S1_INIT` | Inicializa `acc <= 0` y `cont <= 0`. Evalúa `w[1:0]`. | `S2` ($w=00$), `S4` ($w=01$), `S3` ($w=10$) |
| `S2` | `3'b010` | `S2_ACC_COUNT4` | Acumula `acc <= acc + x` e incrementa `cont` hasta $cont = 4$. | `S5_DONE` si `cont == 4` |
| `S3` | `3'b011` | `S3_ACC_THRESHOLD` | Acumula `acc <= acc + x` continuamente mientras $acc < 20$. | `S5_DONE` si $acc \ge 20$ |
| `S4` | `3'b100` | `S4_ACC_COUNT3` | Acumula `acc <= acc + x` e incrementa `cont` hasta $cont = 3$. | `S5_DONE` si `cont == 3` |
| `S5` | `3'b101` | `S5_DONE` | Genera el pulso de finalización `done = 1` durante 1 ciclo. | `S0_IDLE` (incondicional) |

---

### 2. Diagrama de Estados y Datapath
<img width="1063" height="688" alt="image" src="https://github.com/user-attachments/assets/82ef7666-81c1-4998-8011-2f7db05c1125" />

---

### 3. Arquitectura del Testbench (`tb_accumulator.v`)
El banco de pruebas verifica todas las rutas de control ejecutando tres casos de prueba secuenciales:
1. **Generación de Reloj y Reset**: Provee una señal de reloj periódica y aplica un pulso de reset inicial para asegurar el arranque en `S0_IDLE`.
2. **Prueba 1 ($w = 2\text{'b}00$, $x = 5$)**: Evalúa la acumulación de 4 iteraciones fijas.
3. **Prueba 2 ($w = 2\text{'b}01$, $x = 7$)**: Evalúa la acumulación de 3 iteraciones fijas.
4. **Prueba 3 ($w = 2\text{'b}10$, $x = 6$)**: Evalúa la acumulación por condición de umbral ($acc \ge 20$).
5. **Generación del Archivo `.vcd`**: Emplea las directivas `$dumpfile("accumulator.vcd")` y `$dumpvars(0, tb_accumulator)` para volcar la simulación gráfica.

---

### 4. Evidencias de Simulación (GTKWave)
<img width="1600" height="247" alt="image" src="https://github.com/user-attachments/assets/396ff214-f7af-49f8-a870-eecbb8c6d873" />

#### Explicación del Funcionamiento Observado en las Formas de Onda:

1. **Ruta $w = 2\text{'b}00$ (Prueba 1: $x = 5$)**:
   * Al recibir la señal `start`, la FSM transita por **S1** (`3'b001`) para limpiar los registros e inmediatamente pasa a **S2** (`3'b010`).
   * Acumula el valor $5$ en 4 iteraciones sucesivas: $05 \rightarrow 0\text{A} \rightarrow 0\text{F} \rightarrow 14 \rightarrow 19$.
   * Al alcanzar `cont == 4`, conmuta al estado **S5** (`3'b101`), emite el pulso `done = 1` durante 1 ciclo de reloj y retorna a **S0**.

2. **Ruta $w = 2\text{'b}01$ (Prueba 2: $x = 7$)**:
   * Tras activar el pulso `start`, la FSM pasa por **S1** y salta directamente a **S4** (`3'b100`).
   * Acumula el valor $7$ durante 3 ciclos de reloj: $07 \rightarrow 0\text{E} \rightarrow 15 \rightarrow 1\text{C}$.
   * Al llegar a `cont == 3`, salta a **S5** (`3'b101`) y genera el pulso de término.

3. **Ruta $w = 2\text{'b}10$ (Prueba 3: $x = 6$)**:
   * Transita hacia el estado **S3** (`3'b011`).
   * Acumula iterativamente: $06 \rightarrow 0\text{C} \rightarrow 12 \rightarrow 18$.
   * Dado que $18_{hex} = 24_{dec} \ge 20$, la condición de umbral se satisface, conmutando inmediatamente a **S5** (`3'b101`) con su correspondiente pulso `done = 1`.

---

### 5. Comandos de Compilación y Ejecución

```bash
# Entrar al directorio de código fuente
cd src/

# Compilar el código RTL y el testbench
iverilog -o sim_accumulator.out tb_accumulator.v accumulator.v

# Ejecutar la simulación para generar el archivo de ondas VCD
vvp sim_accumulator.out

# Visualizar las señales en GTKWave
gtkwave accumulator.vcd
```




## Punto 3.1: Transmisor Serial Síncrono de 8 bits (`serial_tx.v`)

### 1. Descripción Técnica y Arquitectura HDL
Este módulo implementa un transmisor serial síncrono basado en una Carta Algorítmica de Máquina de Estados (ASM). El sistema toma un dato de entrada paralelo de 8 bits (`data_in[7:0]`) y lo transmite de manera secuencial bit a bit por la línea serial `tx`, enviando primero el bit menos significativo (LSB-first). La temporización de cada bit está parametrizada mediante la constante `CLKS_PER_BIT`.

#### Componentes Principales del Módulo:
* **Registro de Estado y Reset**: Registra el estado actual de la FSM mediante sincronización con el flanco de subida de `clk`. Restablece el sistema al estado inicial `IDLE` al activarse la señal de reset.
* **Registro de Desplazamiento (`shift_reg[7:0]`)**: Almacena el dato de entrada y realiza corrimientos a la derecha (`shift_reg >> 1`) para exponer el LSB (`shift_reg[0]`) hacia la salida `tx`.
* **Contador de Ticks (`tick_cnt`)**: Registra la cantidad de ciclos de reloj transcurridos por cada bit enviado para garantizar la estabilidad temporal durante `CLKS_PER_BIT` ciclos.
* **Contador de Bits (`bit_count[2:0]`)**: Mantiene el control del número de bits transmitidos (0 a 7) para determinar la finalización de la trama.
* **Lógica de Salidas**: 
  * `tx`: Transmite el bit actual `shift_reg[0]` durante la transmisión, y se mantiene en nivel alto (`1`) en reposo y finalización.
  * `busy`: Permanece activa en nivel alto (`1`) desde el estado `LOAD` hasta la transmisión del octavo bit.
  * `done`: Emite un pulso limpio de alto (`1`) durante un único ciclo de reloj al completar la transferencia.

#### Tabla de Estados y Transiciones (Carta ASM)
| Estado | Código | Nombre | Lógica de Salida / Operación | Condición de Salida | Estado Siguiente |
| :--- | :---: | :--- | :--- | :--- | :--- |
| `S0` | `3'b000` | `IDLE` | `tx = 1`, `busy = 0`, `done = 0` | `start == 1` | `LOAD` |
| `S1` | `3'b001` | `LOAD` | `shift_reg <= data_in`, `bit_count <= 0`, `tick_cnt <= 0`, `busy = 1` | Incondicional | `BIT_HOLD` |
| `S2` | `3'b010` | `BIT_HOLD` | `tx = shift_reg[0]`, `tick_cnt <= tick_cnt + 1` | `tick_cnt == CLKS_PER_BIT - 1` | `SHIFT_NEXT` |
| `S3` | `3'b011` | `SHIFT_NEXT` | `shift_reg <= shift_reg >> 1`, `bit_count <= bit_count + 1`, `tick_cnt <= 0` | `bit_count == 7` / else | `DONE` / `BIT_HOLD` |
| `S4` | `3'b100` | `DONE` | `done = 1`, `busy = 0`, `tx = 1` | Incondicional | `IDLE` |

---

### 2. Carta ASM 
<img width="1000" height="1600" alt="image" src="https://github.com/user-attachments/assets/b7ec8176-a592-4d32-9c3c-34135f709cf7" />

---

### 3. Arquitectura del Testbench (`tb_serial_tx.v`)
El banco de pruebas valida la transmisión serial verificando la temporalidad y el orden de los bits mediante dos tramas de prueba:
1. **Generación de Reloj y Reset**: Configura una señal de reloj con periodo de 10 ns y aplica un pulso de reset inicial (`rst = 1`).
2. **Parámetro de Pruebas**: Configura `CLKS_PER_BIT = 8` para verificar un tiempo de sostenimiento de 8 ciclos por bit.
3. **Trama 1 (`data_in = 8'hA5` / `8'b10100101`)**: Activa el pulso `start` y verifica la salida LSB-first.
4. **Trama 2 (`data_in = 8'h3C` / `8'b00111100`)**: Carga una segunda trama consecutiva para evaluar el reuso del módulo tras la bandera `done`.
5. **Generación del Archivo `.vcd`**: Emplea las directivas `$dumpfile("serial_tx.vcd")` y `$dumpvars(0, tb_serial_tx)` para registrar el comportamiento temporal en GTKWave.

---

### 4. Evidencias de Simulación (GTKWave)
<img width="1600" height="278" alt="image" src="https://github.com/user-attachments/assets/bde8b2db-6255-410a-9720-5239cc1f9a10" />

#### Explicación del Funcionamiento Observado en las Formas de Onda:

1. **Primera Trama: `data_in = 8'hA5` (`10100101b`)**:
   * Tras recibir el pulso `start`, `shift_reg` se carga con `8'hA5`.
   * El registro ejecuta el corrimiento a la derecha tras cada intervalo de bit: `A5` $\rightarrow$ `52` $\rightarrow$ `29` $\rightarrow$ `14` $\rightarrow$ `0A` $\rightarrow$ `05` $\rightarrow$ `02` $\rightarrow$ `01` $\rightarrow$ `00`.
   * La salida `tx` emite la secuencia lógica en orden LSB-first: **`1, 0, 1, 0, 0, 1, 0, 1`**.

2. **Segunda Trama: `data_in = 8'h3C` (`00111100b`)**:
   * Al recibir un nuevo pulso `start` de 1 ciclo, se carga `8'h3C`.
   * `shift_reg` se desplaza progresivamente: `3C` $\rightarrow$ `1E` $\rightarrow$ `0F` $\rightarrow$ `07` $\rightarrow$ `03` $\rightarrow$ `01` $\rightarrow$ `00`.
   * La salida `tx` emite la secuencia lógica: **`0, 0, 1, 1, 1, 1, 0, 0`**.

3. **Temporización y Flags**:
   * Con `CLKS_PER_BIT = 8`, la señal `tick_cnt` realiza un conteo de 0 a 7 por cada uno de los 8 bits transmitidos, garantizando la estabilidad temporal en la línea `tx`.
   * La bandera `busy` se sostiene en nivel alto durante los 8 bits de transmisión.
   * La señal `done` genera un pulso de exactamente 1 ciclo de reloj al finalizar el octavo bit en ambas tramas.

---

### 5. Comandos de Compilación y Ejecución

```bash
# Entrar al directorio de código fuente
cd src/

# Compilar el código RTL y el testbench
iverilog -o sim_serial_tx.out tb_serial_tx.v serial_tx.v

# Ejecutar la simulación para generar el archivo de ondas VCD
vvp sim_serial_tx.out

# Visualizar las señales en GTKWave
gtkwave serial_tx.vcd
```
