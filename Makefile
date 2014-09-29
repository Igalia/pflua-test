PATH := deps/pflua/deps/luajit/usr/local/bin:$(PATH)

all: check_submodules
	$(MAKE) -C deps/pflua all

check:
	$(MAKE) -C deps/pflua check

clean:
	$(MAKE) -C deps/pflua clean

check_submodules:
	@if [ ! -f deps/pflua/deps/luajit/Makefile ]; then \
	    echo "Can't find deps/pflua/. You might need to: git submodule update --init --recursive"; exit 1; \
	fi

.SERIAL: all