# Lab02: Diseño, simulación e implementación de una ALU de 4 bits

**Plataforma:** FPGA Zybo Z7 · **Lenguaje:** Verilog · **Simulación:** Icarus Verilog + GTKWave · **Síntesis:** Vivado

**Integrantes:** _(completar)_

---

## 1. Explicación general del sistema

El sistema implementa una ALU de 4 bits operada desde la placa Zybo Z7. Los 4 switches funcionan como un **bus de datos compartido**: el usuario coloca un valor, lo almacena como Operando A con un botón, cambia los switches, lo almacena como Operando B con otro botón, y luego selecciona la operación con dos botones adicionales. El resultado se muestra en los 4 LEDs y la operación activa se identifica con el color del LED RGB.

Todo el almacenamiento (operandos y código de operación) vive en registros fuera de la ALU. La ALU es lógica puramente combinacional, por lo que su resultado depende solo de sus entradas actuales.

### Flujo de uso

1. Colocar un valor en `SW3..SW0` y presionar **BTN0** → se guarda en el Operando A.
2. Cambiar los switches y presionar **BTN1** → se guarda en el Operando B.
3. Presionar **BTN2** y/o **BTN3** para modificar el código de operación (cada pulsación conmuta un bit).
4. Leer el resultado en `LED3..LED0` y la operación en el LED RGB.
5. No es necesario mantener ningún botón presionado: operandos y operación permanecen almacenados.

---

## 2. Arquitectura propuesta

El diseño es jerárquico: un módulo superior (`top`) que solo interconecta tres módulos funcionales.

```
                       ┌──────────────────────────────────────────┐
                       │                  top                     │
                       │                                          │
  sw[3:0] ────────────►│                                          │
  btn[3:0] ───────────►│  ┌───────────────┐   reg_a[3:0]          │
  clk ────────────────►│  │ input_control │──────────────┐        │
                       │  │  (secuencial) │   reg_b[3:0] │        │
                       │  │               │────────────┐ │        │
                       │  │               │ reg_opcode │ │        │
                       │  └───────┬───────┘   [1:0]    │ │        │
                       │          │                    ▼ ▼        │
                       │          │             ┌──────────────┐  │
                       │          │             │     alu      │──┼──► led[3:0]
                       │          │             │(combinacional)│ │
                       │          │             └──────────────┘  │
                       │          ▼                               │
                       │   ┌─────────────┐                        │
                       │   │ rgb_decoder │────────────────────────┼──► led6_r / led6_g / led6_b
                       │   │(combinacional)│                      │
                       │   └─────────────┘                        │
                       └──────────────────────────────────────────┘
```

| Bloque | Tipo de lógica | Función |
|---|---|---|
| `input_control` | Secuencial (flip-flops, `posedge clk`) | Detecta flancos de los botones y almacena A, B y el opcode |
| `alu` | Combinacional | Calcula el resultado según el opcode |
| `rgb_decoder` | Combinacional | Convierte el opcode en un color del LED RGB |
| `top` | Estructural | Interconecta los módulos con los pines físicos |

---

## 3. Descripción de los módulos

### 3.1 `top.v`
Módulo superior. Expone los puertos físicos de la FPGA (`clk`, `sw`, `btn`, `led`, `led6_r/g/b`) e instancia `input_control`, `alu` y `rgb_decoder`. **No contiene ninguna operación aritmética ni lógica**, solo conexiones mediante los cables internos `reg_a`, `reg_b` y `reg_opcode`.

### 3.2 `input_control.v`
Es el único módulo con elementos de almacenamiento. Contiene:

- `reg_a`, `reg_b` (4 bits cada uno) y `reg_opcode` (2 bits), inicializados en cero.
- `btn_d`: registro con el estado del botón en el ciclo anterior, usado para **detectar flancos de subida** (`btn[i] && !btn_d[i]`).

Comportamiento (todo sincronizado con el reloj de 125 MHz):

| Botón | Acción al detectar flanco de subida |
|---|---|
| BTN0 | `reg_a <= sw` |
| BTN1 | `reg_b <= sw` |
| BTN2 | `reg_opcode[0] <= ~reg_opcode[0]` |
| BTN3 | `reg_opcode[1] <= ~reg_opcode[1]` |

### 3.3 `alu.v`
Módulo puramente combinacional (`assign` con operador condicional). Recibe `a`, `b` (4 bits) y `opcode` (2 bits) y entrega `result` (4 bits). No tiene reloj, registros ni estado.

### 3.4 `rgb_decoder.v`
Módulo combinacional (`always @(*)` con `case`) que traduce el opcode almacenado a las tres señales del LED RGB.

---

## 4. Tabla de operaciones implementadas

| Opcode (`BTN3 BTN2`) | Operación | Expresión en Verilog |
|:---:|---|---|
| `00` | Suma | `a + b` |
| `01` | Resta | `a - b` |
| `10` | AND | `a & b` |
| `11` | OR | `a \| b` |

**Notas:**
- La suma y la resta son de 4 bits: el resultado se trunca (aritmética módulo 16). No se implementan banderas de acarreo ni de préstamo. Ejemplo: `9 + 8 = 17 → 0001`; `3 - 5 → 1110` (−2 en complemento a 2).
- Dado que el opcode se modifica por conmutación de bits, la secuencia de pulsaciones determina la operación: partiendo de `00`, BTN2 pasa a `01` (resta), BTN3 pasa a `10` (AND), y ambos a `11` (OR).

---

## 5. Almacenamiento de los operandos

Los operandos se guardan en los registros `reg_a` y `reg_b` dentro de `input_control`, implementados con flip-flops disparados por el flanco de subida del reloj.

La carga **no depende del nivel** del botón sino de su **flanco de subida**: se compara el valor actual `btn[i]` con el del ciclo anterior `btn_d[i]`. Así, aunque el botón permanezca presionado, la carga ocurre una sola vez, en un único ciclo de reloj, y el valor almacenado se mantiene aunque después se muevan los switches, hasta una nueva carga.

```verilog
if (btn[0] && !btn_d[0]) reg_a <= sw;   // Carga A
if (btn[1] && !btn_d[1]) reg_b <= sw;   // Carga B
```

Los registros A y B son independientes: cada uno tiene su propio botón de carga.

---

## 6. Conservación del código de operación

El código de operación se guarda en `reg_opcode[1:0]`, también dentro de `input_control`. Cada botón de selección está asociado a un bit del código y, al detectarse su flanco de subida, **conmuta** (invierte) dicho bit:

```verilog
if (btn[2] && !btn_d[2]) reg_opcode[0] <= ~reg_opcode[0];  // BTN2 → bit 0
if (btn[3] && !btn_d[3]) reg_opcode[1] <= ~reg_opcode[1];  // BTN3 → bit 1
```

Como el valor reside en flip-flops, la operación permanece activa al soltar los botones. El mismo registro alimenta tanto a la ALU como al decodificador del LED RGB, por lo que el color mostrado corresponde siempre al código almacenado.

---

## 7. Colores del LED RGB

| Opcode | Operación | R | G | B | Color |
|:---:|---|:-:|:-:|:-:|---|
| `00` | Suma | 0 | 1 | 0 | **Verde** |
| `01` | Resta | 1 | 0 | 0 | **Rojo** |
| `10` | AND | 0 | 0 | 1 | **Azul** (elegido por el grupo) |
| `11` | OR | 1 | 0 | 1 | **Magenta** (Rojo + Azul, elegido por el grupo) |

Los cuatro colores son claramente distinguibles entre sí.

---

## 8. Asignación de hardware (Zybo Z7)

Definida en `Zybo_Z7_Master.xdc`. Reloj de 125 MHz (periodo de 8 ns), todos los pines en `LVCMOS33`.

| Señal | Pin | Función |
|---|:-:|---|
| `clk` | K17 | Reloj de 125 MHz |
| `sw[0..3]` | G15, P15, W13, T16 | Bus de datos (bits 0 a 3) |
| `btn[0]` | K18 | Cargar Operando A |
| `btn[1]` | P16 | Cargar Operando B |
| `btn[2]` | K19 | Conmutar bit 0 del opcode |
| `btn[3]` | Y16 | Conmutar bit 1 del opcode |
| `led[0..3]` | M14, M15, G14, D18 | Resultado (bits 0 a 3) |
| `led6_r` | V16 | LED RGB, rojo |
| `led6_g` | F17 | LED RGB, verde |
| `led6_b` | M17 | LED RGB, azul |

---

## 9. Estructura del repositorio

```
.
├── README.md
├── src/
│   ├── top.v
│   ├── input_control.v
│   ├── alu.v
│   ├── rgb_decoder.v
│   └── Zybo_Z7_Master.xdc
└── sim/
    ├── alu_tb.v            # testbench
    ├── alu_tb.vcd          # archivo de ondas
    └── img/                # capturas de GTKWave
```

> Ajustar los nombres de archivo del testbench y del VCD a los que realmente se usen.

---

## 10. Simulación

### 10.1 Ejecución

```bash
cd sim
iverilog -o alu_tb.out alu_tb.v ../src/alu.v
vvp alu_tb.out
gtkwave alu_tb.vcd
```

### 10.2 Testbench

El testbench instancia la ALU, aplica múltiples combinaciones de `a`, `b` y `opcode`, cubre las cuatro operaciones y genera el archivo de ondas (`$dumpfile` / `$dumpvars`). _(Describir aquí los casos probados: valores límite como 0000 y 1111, casos con desbordamiento en suma y resta, etc.)_

### 10.3 Capturas de GTKWave

_(Insertar capturas con las señales `a`, `b`, `opcode` y `result`.)_

![Simulación completa](sim/img/gtkwave_completa.png)
![Detalle de operaciones](sim/img/gtkwave_detalle.png)

### 10.4 Comportamiento observado

_(Completar con lo que se ve en las ondas. Puntos a cubrir:)_

- Cada operación produce el resultado esperado para los operandos aplicados.
- El resultado cambia al variar el opcode sin modificar `a` y `b`.
- El resultado responde a cualquier cambio de sus entradas, sin retener estados anteriores: comportamiento combinacional.
- Casos de truncamiento en suma y resta (resultado módulo 16).

---

## 11. Implementación y verificación en FPGA

El diseño sintetiza e implementa en Vivado y se descarga a la Zybo Z7. Procedimiento de verificación realizado:

| # | Prueba | Resultado |
|:-:|---|:-:|
| 1 | Colocar un valor en los switches y cargarlo como A (BTN0) | ☐ |
| 2 | Mover los switches y comprobar que A conserva su valor | ☐ |
| 3 | Cargar un nuevo valor como B (BTN1) | ☐ |
| 4 | Seleccionar una operación (BTN2/BTN3) y soltar los botones | ☐ |
| 5 | Verificar que la operación permanece seleccionada | ☐ |
| 6 | Observar el resultado en los LEDs | ☐ |
| 7 | Verificar el color del LED RGB para la operación | ☐ |
| 8 | Cambiar la operación sin tocar los operandos y verificar el resultado | ☐ |
| 9 | Verificar el cambio de color del LED RGB | ☐ |
| 10 | Mover los switches y verificar que A y B no cambian sin nueva carga | ☐ |

### Evidencia

_(Insertar fotos o video del funcionamiento en la placa, una por operación, mostrando LEDs y color del RGB.)_

![Suma](img/fpga_suma.jpg)
![Resta](img/fpga_resta.jpg)
![AND](img/fpga_and.jpg)
![OR](img/fpga_or.jpg)

---

## 12. Cumplimiento de los criterios de éxito

| Criterio | Cumplimiento |
|---|---|
| ALU ejecuta correctamente todas las operaciones | `alu.v`: suma, resta, AND, OR |
| ALU como módulo independiente y combinacional | Solo `assign`, sin reloj ni registros |
| Operaciones no implementadas en el módulo superior | `top.v` solo instancia y conecta |
| ALU no almacena información | Sin estado interno |
| Operandos A y B independientes | `reg_a` y `reg_b`, cargados por BTN0 y BTN1 |
| Operandos persisten al mover los switches | Flip-flops con carga por flanco |
| Opcode persiste al soltar los botones | `reg_opcode` en `input_control` |
| No se requiere mantener botones presionados | Detección de flanco + registro |
| LED RGB indica la operación | `rgb_decoder` a partir de `reg_opcode` |
| Un color distinto por operación | Verde, rojo, azul y magenta |
| Colores de AND y OR documentados | Sección 7 |
| Simulación coincide con lo esperado | Sección 10 |
| Sintetiza en Vivado | Sección 11 |
| Responde a las entradas físicas | Sección 11 |

---

## 13. Limitaciones y posibles mejoras

- **Sin antirrebote (debounce) en los botones:** la detección de flancos opera directamente sobre la señal del botón. Los rebotes mecánicos podrían causar cargas o conmutaciones múltiples, aunque en la práctica la carga de A/B no se ve afectada porque el valor de los switches es el mismo, pero la conmutación del opcode sí podría verse afectada.
- **Sin sincronizador de entrada:** las señales asíncronas de botones entran directamente a la lógica sincronizada con `clk`; un sincronizador de dos flip-flops reduciría el riesgo de metaestabilidad.
- **Sin banderas de estado:** la ALU no expone acarreo, préstamo ni desbordamiento.

