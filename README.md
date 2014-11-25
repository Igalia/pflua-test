# pflua-test
pflua-quickcheck [--seed=N] [--iterations=N] lua_property_file [property-specific-args]

Pflua-quickcheck is a tool inspired by Haskell's quickcheck, for property-based testing.

It takes one mandatory argument, which generates examples for a property, in Lua; that file can optionally require more arguments, if generating examples needs them.

Examples:
The simplest possible use: specify a property file
./pflua-quickcheck prop_pfluamath_eq_libpcap_math

This example's property file takes one mandatory and one optional argument:
./pflua-quickcheck prop_opt_eq_unopt savefiles/wingolog.org.pcap test-filters
./pflua-quickcheck prop_opt_eq_unopt savefiles/wingolog.org.pcap

This example gives arguments to pflua-quickcheck, specifying the seed and number of iterations.
./pflua-quickcheck --seed=379782615 --iterations=85 prop_opt_eq_unopt savefiles/wingolog.org.pcap

About property files:
A property file need to define a 'property' function, which must return two values, which are expected to be equal if the property is true. See the file prop_trivial.lua for an example.
Run it as: ./pflua-quickcheck prop_trivial

A property file may also optionally define functions that parse extra arguments (handle_prop_args), and/or that show more internal information if a property failure occurs (print_extra_information).

See also:
https://github.com/Igalia/pflua
