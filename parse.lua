function getTable (s)
   --/dial/r/g/b
   --/mode/n
   s=s.."/"
   local fieldstart = 2
   local t = {}

   while fieldstart < string.len(s) do
      local nexti = string.find(s, '/', fieldstart + 1)
      --print(nexti .. " fieldstart " .. fieldstart)
      print(string.sub(s,fieldstart, nexti-1))
      table.insert(t,string.sub(s,fieldstart, nexti-1))
      fieldstart = string.find(s, '/', fieldstart) + 1
   end

   return t
end
