#!/usr/bin/env luajit
module(..., package.seeall)
package.path = package.path .. ";deps/pflua/src/?.lua"

local io = require("io")
local codegen = require("pf.codegen")
local expand = require("pf.expand")
local parse = require("pf.parse")

-- Generate pflang arithmetic
local PflangNumber, PflangSmallNumber, PflangOp
function PflangNumber() return math.random(0, 2^32-1) end
-- TODO: remove PflangSmallNumber; it's a workaround to avoid triggering
-- https://github.com/Igalia/pflua/issues/83 (float and integer muls diverge)
function PflangSmallNumber() return math.random(0, 2^17) end
function PflangOp() return utils.choose({ '+', '-', '*', '/' }) end
function PflangArithmetic()
   return { PflangNumber(), PflangOp(), PflangSmallNumber() }
end

-- Evaluate math expressions with tcpdump and pflang's IR

-- Pflang allows arithmetic as part of larger expressions.
-- This tool uses len < arbitrary_arithmetic_here as a scaffold

-- Here is a truncated example of the tcpdump output that is parsed
--tcpdump -d "len < -4 / 2"
--(000) ld       #pktlen
--(001) jge      #0x7ffffffe      jt 2    jf 3

function tcpdump_eval(str_expr)
   local expr = "len < " .. str_expr
   local cmdline = ('tcpdump -d "%s"'):format(expr)
   local bpf = io.popen(cmdline):read("*all")
   local res = string.match(bpf, "#(0x%x+)")
   return tonumber(res)
end

-- Here is an example of the pflua output that is parsed
-- return function(P,length)
--    local v1 = 3204555350 * 122882
--    local v2 = v1 % 4294967296
--    do return length < v2 end
-- end

function pflua_eval(str_expr)
   local expr = "len < " .. str_expr
   local ir = expand.expand(parse.parse(expr))
   local filter = codegen.compile_lua(ir, "Arithmetic check")
   local math_string = string.match(filter, "v1 = [%d-+/*()%a. ]*")
   v1 = nil
   loadstring(math_string)() -- v1 must not be local, or this approach will fail
   v1 = v1 % 2^32 -- TODO: it would be better to do this iff the filter does
   return v1
end
