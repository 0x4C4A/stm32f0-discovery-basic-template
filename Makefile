# put your *.o targets here, make should handle the rest!
SRCS = main.c system_stm32f0xx.c stm32f0xx_it.c stm32f0xx_hal_msp.c

# all the files will be generated with this name (main.elf, main.bin, main.hex, etc)
PROJ_NAME=main

# Location of the Drivers folder from the STM32F0xx Cube Package
CUBE_DRIVERS_DIR=Drivers

# Location of the linker scripts
LDSCRIPT_INC=Device/ldscripts

# location of OpenOCD Board .cfg files (only used with 'make program')
OPENOCD_BOARD_DIR=/usr/share/openocd/scripts/board

# Configuration (cfg) file containing programming directives for OpenOCD
OPENOCD_PROC_FILE=extra/stm32f0-openocd.cfg

# Also change your chosen mcu in Drivers/choose_your_mcu_here.h!

# that's it, no need to change anything below this line!

###################################################

CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy
OBJDUMP=arm-none-eabi-objdump
SIZE=arm-none-eabi-size

CFLAGS  = -Wall -g -std=c99 -Os
#CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m0 -march=armv6s-m
CFLAGS += -mlittle-endian -mcpu=cortex-m0  -march=armv6-m -mthumb
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections -Wl,-Map=$(PROJ_NAME).map

###################################################

vpath %.c src
vpath %.a $(CUBE_DRIVERS_DIR)

ROOT=$(shell pwd)

CFLAGS += -include $(CUBE_DRIVERS_DIR)/choose_your_mcu_here.h
CFLAGS += -include $(CUBE_DRIVERS_DIR)/stm32f0xx_hal_conf.h
CFLAGS += -I inc
CFLAGS += -I $(CUBE_DRIVERS_DIR)
CFLAGS += -I $(CUBE_DRIVERS_DIR)/STM32F0xx_HAL_Driver/Inc
CFLAGS += -I $(CUBE_DRIVERS_DIR)/CMSIS/Device/ST/STM32F0xx/Include
CFLAGS += -I $(CUBE_DRIVERS_DIR)/CMSIS/Include
CFLAGS += -I $(CUBE_DRIVERS_DIR)/STM32F0xx_StdPeriph_Driver/inc
# Enable if needed
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/Adafruit_Shield
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/Components/Common
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/Components/hx8347d
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/Components/l3gd20
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/Components/spfd5408
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/Components/st7735
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/Components/stlm75
CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/STM32072B_EVAL
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/STM32091C_EVAL
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/STM32F0308-Discovery
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/STM32F072B-Discovery
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/STM32F0xx-Nucleo
#CFLAGS += -I $(CUBE_DRIVERS_DIR)/BSP/STM32F0xx_Nucleo_32


SRCS += Device/startup_stm32f0xx.s # add startup file to build

# need if you want to build with -DUSE_CMSIS
#SRCS += stm32f0_discovery.c
#SRCS += stm32f0_discovery.c stm32f0xx_it.c

OBJS = $(SRCS:.c=.o)

###################################################

.PHONY: lib proj

all: lib proj

lib:
	$(MAKE) -C $(CUBE_DRIVERS_DIR)

proj: $(PROJ_NAME).elf $(PROJ_NAME).hex $(PROJ_NAME).bin $(PROJ_NAME).lst

$(PROJ_NAME).elf: $(SRCS)
	$(CC) $(CFLAGS) $^ -o $@ -L$(CUBE_DRIVERS_DIR) -lstm32f0 -L$(LDSCRIPT_INC) -Tstm32f0.ld
	$(SIZE) $(PROJ_NAME).elf

$(PROJ_NAME).bin: $(PROJ_NAME).elf
	$(OBJCOPY) -O binary $(PROJ_NAME).elf $(PROJ_NAME).bin

$(PROJ_NAME).hex: $(PROJ_NAME).elf
	$(OBJCOPY) -O ihex $(PROJ_NAME).elf $(PROJ_NAME).hex

$(PROJ_NAME).lst: $(PROJ_NAME).elf
	$(OBJDUMP) -St $(PROJ_NAME).elf >$(PROJ_NAME).lst

program: $(PROJ_NAME).bin
	openocd -f $(OPENOCD_BOARD_DIR)/stm32f0discovery.cfg -f $(OPENOCD_PROC_FILE) -c "stm_flash $(PROJ_NAME).bin" -c shutdown

clean:
	find ./ -name '*~' | xargs rm -f
	rm -f *.o
	rm -f $(PROJ_NAME).elf
	rm -f $(PROJ_NAME).hex
	rm -f $(PROJ_NAME).bin
	rm -f $(PROJ_NAME).map
	rm -f $(PROJ_NAME).lst

reallyclean: clean
	$(MAKE) -C $(CUBE_DRIVERS_DIR) clean

debug: $(PROJ_NAME).elf
	st-util &
	arm-none-eabi-insight $^ &