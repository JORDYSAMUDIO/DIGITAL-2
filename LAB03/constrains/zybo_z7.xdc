## Reloj Principal (125 MHz)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## Switches (SW[3:0])
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## Botones (BTN0 a BTN3)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn0 }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn1 }];
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn2 }];
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn3 }];

## LEDs (LED0 a LED3)
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## LED RGB (LD5)
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { rgb_led[2] }]; # Rojo
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { rgb_led[1] }]; # Verde
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { rgb_led[0] }]; # Azul

## TM1637 Display en Puerto PMOD JB (High Speed)
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { tm1637_clk }]; # Pin 1 de PMOD JB
set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { tm1637_dio }]; # Pin 2 de PMOD JB