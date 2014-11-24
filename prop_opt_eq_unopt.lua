#!/usr/bin/env luajit
-- -*- lua -*-
module(..., package.seeall)
package.path = package.path .. ";deps/pflua/src/?.lua"

local ffi = require("ffi")
local parse = require("pf.parse")
local savefile = require("pf.savefile")
local expand = require("pf.expand")
local optimize = require("pf.optimize")
local codegen = require('pf.codegen')

local pflua_ir = require('pflua_ir')
local utils = require('utils')

local function load_packets(file)
   local header, ptr, ptr_end = savefile.open_and_mmap(file)
   local ret = {}
   while ptr < ptr_end do
      local record = ffi.cast("struct pcap_record *", ptr)
      local packet = ffi.cast("unsigned char *", record + 1)
      table.insert(ret, { packet=packet, len=record.incl_len })
      ptr = packet + record.incl_len
   end
   return ret
end

local function load_filters(file)
   local ret = {}
   for line in io.lines(file) do table.insert(ret, line) end
   return ret
end


function property(packets, filter_list)
   local packet
   packet, packet_idx = utils.choose(packets)
   local P, len = packet.packet, packet.len
   local F, expanded
   if filters then
      F = utils.choose(filters)
      expanded = expand.expand(parse.parse(F), "EN10MB")
   else
      F = "generated expression"
      expanded = pflua_ir.Logical()
   end
   local optimized = optimize.optimize(expanded)

   unoptimized_pred = codegen.compile(expanded, F)
   optimized_pred = codegen.compile(optimized, F)

   return unoptimized_pred(P, len), optimized_pred(P, len)
end

-- The test harness calls this on property failure.
function print_extra_information()
   print("--- Expanded:")
   pp(expanded)
   print("--- Optimized:")
   pp(optimized)
   print(string.format("Packet idx: %s", packet_idx))
end

function handle_prop_args(prop_args)
   if #prop_args < 1 or #prop_args > 2 then
      print("Usage: (pflua-quickcheck [args] prop_opt_eq_unopt) PATH/TO/CAPTURE.PCAP [FILTER-LIST]")
      os.exit(1)
   end

   local capture, filter_list = prop_args[1], prop_args[2]
   local packets = load_packets(capture)
   local filters
   if filter_list then
      filters = load_filters(filter_list)
   end
   return packets, filter_list
end
