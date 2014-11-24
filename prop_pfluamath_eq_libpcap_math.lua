#!/usr/bin/env luajit
-- -*- lua -*-
module(..., package.seeall)
pflang_math = require("pflang_math")
utils = require("utils")

function property()
   arithmetic_expr = table.concat(pflang_math.PflangArithmetic(), ' ')
   tcpdump_result = pflang_math.tcpdump_eval(arithmetic_expr)
   pflua_result = pflang_math.pflua_eval(arithmetic_expr)
   return tcpdump_result, pflua_result
end

