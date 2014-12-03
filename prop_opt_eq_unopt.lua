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
local pfutils = require('pf.utils')
local pp = pfutils.pp

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

-- Several variables are non-local for print_extra_information()
function property(packets, filter_list)
   local packet
   -- Reset these every run, to minimize confusing output on crashes
   optimized_pred, unoptimized_pred, expanded, optimized = nil, nil, nil, nil
   packet, packet_idx = utils.choose_with_index(packets)
   P, packet_len = packet.packet, packet.len
   local F
   if filters then
      F = utils.choose(filters)
      expanded = expand.expand(parse.parse(F), "EN10MB")
   else
      F = "generated expression"
      expanded = pflua_ir.Logical()
   end
   optimized = optimize.optimize(expanded)

   unoptimized_pred = codegen.compile(expanded, F)
   optimized_pred = codegen.compile(optimized, F)
   return unoptimized_pred(P, packet_len), optimized_pred(P, packet_len)
end

-- The test harness calls this on property failure.
function print_extra_information()
   if expanded then
      print("--- Expanded:")
      pp(expanded)
   else return -- Nothing else useful available to print
   end
   if optimized then
      print("--- Optimized:")
      pp(optimized)
   else return -- Nothing else useful available to print
   end

   print(("On packet %s: unoptimized was %s, optimized was %s"):
         format(packet_idx,
                unoptimized_pred(P, packet_len),
                optimized_pred(P, packet_len)))
end

function handle_prop_args(prop_args)
   if #prop_args < 1 or #prop_args > 2 then
      print("Usage: (pflua-quickcheck [args] prop_opt_eq_unopt) " ..
            "PATH/TO/CAPTURE.PCAP [FILTER-LIST]")
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
