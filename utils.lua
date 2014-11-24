#!/usr/bin/env luajit
-- -*- lua -*-
module(..., package.seeall)

function choose(choices)
   local idx = math.random(#choices)
   return choices[idx], idx
end

