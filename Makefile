PATH := deps/pflua/deps/luajit/usr/local/bin:$(PATH)

all: check_submodules
	$(MAKE) -C deps/pflua all

check:
	$(MAKE) -C deps/pflua check

clean:
	$(MAKE) -C deps/pflua clean

check_submodules:
	@if [ ! -f deps/pflua/deps/luajit/Makefile ]; then \
	    echo -n "Can't find deps/pflua/. You might need: " \
	    echo "git submodule update --init --recursive"; exit 1; \
	fi

quickcheck: check_submodules
	./pflua-quickcheck prop_opt_eq_unopt savefiles/wingolog.org.pcap test-filters
	./pflua-quickcheck prop_opt_eq_unopt savefiles/wingolog.org.pcap
	make tcpdumpchecks || echo "Skipped running properties that need tcpdump"

tcpdumpchecks: check_submodules
	./test_tcpdump.sh || exit 1
	./pflua-quickcheck --iterations=50 prop_pfluamath_eq_libpcap_math

.SERIAL: all
