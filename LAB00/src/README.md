# Lab ab00 — Introducción a Verilog, Simulación y Máquinas de Estados Finitos (FSM)

**Curso:** [nombre del curso]
**Autor(es):** [tu nombre / integrantes del grupo]
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

## 5. Ejercicio 2 — FSM con datapath: Acumulador secuencial

### Descripción

Sistema secuencial que acumula el valor de entrada `x` durante 4 ciclos, controlado por una FSM de 4 estados (`IDLE`, `LOAD`, `ADD`, `DONE`).

### Entradas / Salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---|---|
| `clk` | entrada | 1 | Reloj del sistema |
| `rst` | entrada | 1 | Reset asíncrono |
| `start` | entrada | 1 | Pulso de inicio |
| `x` | entrada | 4 bits | Valor a acumular |
| `acc` | salida | 6 bits | Acumulador |
| `done` | salida | 1 | Pulso de fin de operación |

### Diagrama de estados (ASM)

![Diagrama de estados del acumulador](DiagramaEstadosAcum.png)

| Estado | Función |
|---|---|
| `S0_IDLE` | Espera `start = 1` |
| `S1_LOAD` | Inicializa `acc = 0` y el contador interno `cnt = 0` |
| `S2_ADD` | Suma `acc <= acc + x` durante 4 ciclos (`cnt` de 0 a 3) |
| `S3_DONE` | Activa `done = 1` durante un ciclo y regresa a `IDLE` |

**Variante implementada:** suma de `x` durante **4 ciclos** de reloj (condición de salida de `S2_ADD`: `cnt == 3`).

### Testbench (`tb_accumulator.v`)

Aplica reset inicial, luego dos pruebas consecutivas:

| Prueba | `x` | Acumulaciones | `acc` esperado |
|---|---|---|---|
| 1 | 5 | 4 | 20 |
| 2 | 3 | 4 | 12 |

El testbench genera el pulso de `start` de un solo ciclo, espera la señal `done` con `wait(done)` y finaliza con `$finish` tras confirmar ambas pruebas (`accumulator.vcd`).

**Observaciones esperadas en GTKWave:**
- `state` recorre `IDLE → LOAD → ADD → DONE → IDLE` en cada prueba.
- `acc` incrementa en pasos de `x` durante los 4 ciclos de `S2_ADD`, alcanzando 20 y 12 respectivamente.
- `done` se activa por un único ciclo al finalizar cada acumulación.

---

## 6. Ejercicio 3 — ASM completa: Transmisor serial síncrono (UART simplificado)

### Descripción

Transmisor serial síncrono de 8 bits (LSB primero) que recibe un byte, lo transmite bit a bit por la línea `tx` y controla la duración de cada bit mediante el parámetro `CLKS_PER_BIT`.

### Entradas / Salidas

| Señal | Dirección | Ancho | Descripción |
|---|---|---|---|
| `clk` | entrada | 1 | Reloj del sistema |
| `rst` | entrada | 1 | Reset asíncrono |
| `start` | entrada | 1 | Pulso de inicio (1 ciclo) |
| `data_in` | entrada | 8 bits | Byte a transmitir |
| `tx` | salida | 1 | Línea serial de salida |
| `busy` | salida | 1 | Transmisión en curso |
| `done` | salida | 1 | Pulso de fin de transmisión |

**Parámetro:** `CLKS_PER_BIT = 8` (usado en la simulación).

### Diagrama de estados (ASM)

![Diagrama de estados del transmisor serial](DiagramaEstadosAcum.png)

| Estado | Función |
|---|---|
| `S0_IDLE` | `tx = 1`, `busy = 0`, espera `start` |
| `S1_LOAD` | Carga `shift_reg <= data_in`, reinicia `bit_cnt` y `tick_cnt`, activa `busy` |
| `S2_BIT_HOLD` | `tx <= shift_reg[0]`; `tick_cnt` cuenta hasta `CLKS_PER_BIT - 1` para sostener el bit actual |
| `S3_SHIFT_NEXT` | Desplaza `shift_reg >> 1`, incrementa `bit_cnt`, reinicia `tick_cnt` |
| `S4_DONE` | `done = 1` durante un ciclo, `busy = 0`, retorna a `IDLE` |

El ciclo `S2_BIT_HOLD ⇄ S3_SHIFT_NEXT` se repite 8 veces (una por cada bit de `data_in`) antes de pasar a `S4_DONE`.

### Registros internos

```verilog
reg [7:0] shift_reg;                          // registro de desplazamiento
reg [2:0] bit_cnt;                            // contador de bits (0-7)
reg [$clog2(CLKS_PER_BIT)-1:0] tick_cnt;       // contador de temporización por bit
```

### Testbench (`tb_serial_tx.v`)

Aplica reset inicial y transmite dos bytes distintos, esperando la señal `done` entre cada uno:

| Prueba | `data_in` | Binario (LSB primero) |
|---|---|---|
| 1 | `8'hA5` | `10100101` |
| 2 | `8'h3C` | `00111100` |

El `.vcd` resultante (`wave.vcd`) incluye las señales `clk`, `rst`, `start`, `state`, `data_in`, `shift_reg`, `bit_cnt`, `tick_cnt`, `tx`, `busy`, `done`.

**Confirmación observada en GTKWave:**
- Se transmiten correctamente los 8 bits de cada byte, en el orden LSB primero.
- Cada bit permanece estable exactamente `CLKS_PER_BIT = 8` ciclos de reloj (medible entre flancos consecutivos de `tick_cnt` reiniciándose).
- `busy` permanece activo durante toda la transmisión (desde `LOAD` hasta antes de `DONE`).
- `done` se activa por un único ciclo de reloj al finalizar cada byte.
- `shift_reg` se desplaza un bit a la derecha en cada transición `SHIFT_NEXT`, y `bit_cnt` se incrementa de forma coherente hasta llegar a 7.

---

## 7. Conclusiones

- Se verificó el correcto funcionamiento del entorno de simulación (Icarus Verilog + GTKWave) mediante el smoke test inicial.
- Los tres ejercicios (semáforo, acumulador y transmisor serial) se modelaron siguiendo la misma estructura de tres bloques `always`: registro de estado, lógica combinacional de siguiente estado y lógica de salidas/datapath, lo cual facilita la extensión hacia sistemas más complejos (unidad de control + datapath).
- Las simulaciones en GTKWave confirmaron que cada FSM cumple con las duraciones de estado y la temporización especificadas en el enunciado.
- [Agregar aquí cualquier dificultad encontrada, decisiones de diseño propias del grupo, o aprendizajes adicionales.]

## 8. Recursos

- [¿Qué es una máquina de estados y cómo se escriben en Verilog?](#)
- [¿Cómo escribir una FSM en Verilog?](#)
- [Semáforo avanzado: análisis y Verilog](#)

> Nota: reemplaza los enlaces anteriores por las URLs reales indicadas en la guía del laboratorio.
