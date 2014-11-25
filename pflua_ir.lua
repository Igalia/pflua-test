#!/usr/bin/env luajit
-- -*- lua -*-
-- This module generates (a subset of) pflua's IR,
-- for property-based tests of pflua internals.

module(..., package.seeall)
utils = require("utils")

local True, False, Fail, ComparisonOp, BinaryOp, UnaryOp, Number, Len
local Unary, Binary, Arithmetic, Comparison, Conditional --, Logical

function True() return { 'true' } end
function False() return { 'false' } end
function Fail() return { 'fail' } end
function ComparisonOp() return utils.choose({ '<', '>' }) end
function BinaryOp() return utils.choose({ '+', '-', '/' }) end
function UnaryOp() return utils.choose({ 'uint32', 'int32', 'ntohs', 'ntohl' }) end
-- Boundary numbers are often particularly interesting; test them often
function Number()
   if math.random() < 0.2 then return math.random(-2^31, 2^32 - 1)
   else return utils.choose({ 0, 1, -2^31, 2^32-1, 2^31-1 })
   end
end
function Len() return 'len' end
function Unary(db) return { UnaryOp(), Arithmetic(db) } end
function Binary(db)
   local op, lhs, rhs = BinaryOp(), Arithmetic(db), Arithmetic(db)
   if op == '/' then table.insert(db, { '!=', rhs, 0 }) end
   return { op, lhs, rhs }
end
function PacketAccess(db)
   local pkt_access_size = utils.choose({1, 2, 4})
   local position = {'uint32', Arithmetic(db) }
   table.insert(db, {'>=', 'len', {'+', position, pkt_access_size}})
   return { '[]', position, pkt_access_size }
end
function Arithmetic(db)
   -- Only return the chosen value, not the index too
   -- (expr) is standard Lua; it returns only the first value of a multi-value expr
   return utils.choose({ Unary, Binary, Number, Len, PacketAccess })(db)
end
function Comparison()
   local assertions = {}
   local expr = { ComparisonOp(), Arithmetic(assertions), Arithmetic(assertions) }
   while #assertions > 0 do
      expr = { 'if', table.remove(assertions), expr, { 'fail' } }
   end
   return expr
end
function Conditional() return { 'if', Logical(), Logical(), Logical() } end
function Logical()
   return utils.choose({ Conditional, Comparison, True, False, Fail })()
end
