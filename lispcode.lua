require "import"
LispParser = import "parser"
LispSexp = import "Sexp"
LispExecutor = import "executor"
LispFunctions = import "functions"

local function pkg_init(Lisp)
	Lisp.code = function(str)
		local newenv = {}
		setmetatable(newenv, {__index = LispFunctions})
		local parser = LispParser.parse(LispParser.stringstream(str))
		local parsed,cont = parser()
		local result
		
		while cont do
			result = LispExecutor.exec(parsed, newenv)
			parsed,cont = parser()
		end
		
		return result

	end

	Lisp.RunFile = LispFunctions["run-file"]
	
	Lisp.require = LispFunctions["require-lisp"]
end

return pkg_init
