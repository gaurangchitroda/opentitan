# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

##############################################################
## Generic rules set for compiling SW for different targets ##
##                                                          ##
## Documentation: doc/deprecated_make_flow.md               ##
##                                                          ##
##############################################################

# rules
.SECONDEXPANSION:
ifeq ($(STANDALONE_SW), 1)
all: gen_dir standalone
else
all: gen_dir $(IMG_OUTPUTS)
endif

gen_dir:
	mkdir -p ${SW_BUILD_DIR}
	mkdir -p ${LIB_BUILD_DIR}
	env > ${SW_BUILD_DIR}/env_vars

standalone: $(SW_DEPS)
	$(STANDALONE_CMD)

$(LIB_TARGET): $(GEN_HEADER_OUTPUTS) $(LIB_OBJS)
	$(AR) $(ARFLAGS) $@ $(LIB_OBJS)

lib: $(LIB_TARGET)

# Note: this IMG_NAME requires the srecord package to be installed.
# XXX: This could be replaced by objcopy onc is merged.
# https://sourceware.org/bugzilla/show_bug.cgi?id=19921
# XXX: Currently the start address 0x1000 is hardcoded. It could/should be
# read from the elf file, but is lost in the bin file.
# Switching to objcopy will resolve that as well.
%.vmem: %.bin
	srec_cat $^ -binary -offset 0x0 -byte-swap 4 -o $@ -vmem

%.bin: %.elf
	$(OBJCOPY) -O binary $(OBJCOPY_FLAGS) $^ $@

%.dis: %.elf
	$(OBJDUMP) -SDhl $^ > $@

# link & generate elf
%.elf %.map: $(SW_DEPS) $(SW_OBJS) $(LINKER_SCRIPT)
	$(CC) $(CFLAGS) $(LINK_OPTS) -o $@

# compile sw sources
# TOOD: figure out a way to 'templatise' .o/.c ruleset for each dir containing srcs

$(SW_BUILD_DIR)/%.o: $(SW_DIR)/$$*.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(SW_BUILD_DIR)/%.o: $(SW_DIR)/$$*.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(SW_BUILD_DIR)/%.o: $(LIB_DIR)/$$*.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(SW_BUILD_DIR)/%.o: $(LIB_DIR)/$$*.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(SW_BUILD_DIR)/%.o: $(EXT_COMMON_DIR)/$$*.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(SW_BUILD_DIR)/%.o: $(EXT_COMMON_DIR)/$$*.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

# compile lib sources
$(LIB_BUILD_DIR)/%.o: $(LIB_DIR)/$$*.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(LIB_BUILD_DIR)/%.o: $(LIB_DIR)/$$*.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(LIB_BUILD_DIR)/%.o: $(EXT_COMMON_DIR)/$$*.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(LIB_BUILD_DIR)/%.o: $(EXT_COMMON_DIR)/$$*.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(LIB_BUILD_DIR)/%.o: $(UTIL_DIR)/$$*.c
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

$(LIB_BUILD_DIR)/%.o: $(UTIL_DIR)/$$*.S
	$(CC) $(CFLAGS) -MMD -c $(INCS) -o $@ $<

# regtool
$(LIB_BUILD_DIR)/%_regs.h: $(REPO_TOP)/hw/ip/$$*/data/$$*.hjson
	$(REGTOOL) -D -o $@ $<

$(LIB_BUILD_DIR)/%_regs.h: $(REPO_TOP)/hw/top_earlgrey/ip/$$*/data/autogen/$$*.hjson
	$(REGTOOL) -D -o $@ $<

$(LIB_BUILD_DIR)/pinmux_regs.h: $(REPO_TOP)/hw/top_earlgrey/ip/pinmux/data/autogen/pinmux.hjson
	$(REGTOOL) -D -o $@ $<

# chip_info
$(SW_BUILD_DIR)/sw/device/boot_rom/chip_info.h: $(INFOTOOL)
	$(INFOTOOL) -o $(dir $@) --ot_version "opentitan-<deprecated/make>"

-include $(DEPS)

# clean sources
clean:
	-$(RM) -r $(GEN_HEADER_OUTPUTS) $(LIB_OBJS) $(SW_OBJS) $(DEPS) \
	          $(IMG_OUTPUTS) $(LIB_TARGET) ${SW_BUILD_DIR}/env_vars

distclean: clean

.PHONY: gen_dir lib clean distclean standalone
