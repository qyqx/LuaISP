require "import"
local LispParser = import "parser"
local LispExecutor = import "executor"


function pkg_init(LispFunctions)
	LispFunctions.MetaFunction = {}
	LispFunctions["+"] = function(...)
				local rval = 0
				for i,v in ipairs(arg) do
					rval = rval + v
				end
				return rval
		end
		
	LispFunctions["-"] = function(...)
				local rval = arg[1] * 2
				for i,v in ipairs(arg) do
					rval = rval - v
				end
				return rval
		end


	LispFunctions.car = function(expr)
				if not expr then return nil end
				if not type(expr) == "table" then return nil end
				if not expr.dtype == type_sexp then return nil end
				
				return LispExecutor.apply_literal(expr.car)
		end

	LispFunctions.cdr = function(expr)
				if not expr then return nil end
				if not type(expr) == "table" then return nil end
				if not expr.dtype == type_sexp then return nil end
				
				return expr.cdr
		end


	LispFunctions.totable = function (expr)
		local i = 1
		local rval = {}
		while expr do
			rval[i] = expr.car
			expr = expr.cdr
			i = i + 1
		end
		return rval
	end
	
	LispFunctions.eq = function(a,b)
						return a == b
					end
	
	function LispFunctions.eqv(a,b)
			a,b = LispExecutor.apply_literal(a), LispExecutor.apply_literal(b)
			if type(a) ~= type(b) then
				return false
			elseif type(a) == "table" and a.dtype ~= b.dtype then
				return false
			elseif type(a) == "table" then
				
				if a.dtype == LispParser.type_ident then
					return a.ident == b.ident
				elseif a.dtype == LispParser.type_sexp then
					
					if not LispFunctions.eqv(a.car, b.car) then
						return false
					else
						return LispFunctions.eqv(a.cdr, b.cdr)
					end
				end
			end
			
			return a == b
	end
	
	LispFunctions.quot = {fun = function(environ, rest)
							return LispExecutor.apply_literal(rest.car)
						end}
	setmetatable(LispFunctions.quot, LispFunctions.MetaFunction)
	
	LispFunctions.lambda = {fun = function(environ, rest)
							return function(...)
								local blah = rest.car
								local newenv = {}
								local i = 1
								local sexp = rest.cdr
								local rval = nil
								setmetatable(newenv, {__index = environ})
								while blah and blah.car do
									--for now
									assert(type(blah.car) == "table" and blah.car.dtype == LispParser.type_ident)
									newenv[blah.car.ident] = arg[i]
									i = i + 1
									blah = blah.cdr
								end
								
								while sexp do
									rval = LispExecutor.exec(sexp.car, newenv)
									sexp = sexp.cdr
								end
								return rval
							end
						end}
						
	LispFunctions.set = {fun = function(environ, rest)
								assert(type(rest.car) == "table" and rest.car.dtype == LispParser.type_ident)
								environ[rest.car.ident] = LispExecutor.exec(rest.cdr.car, environ)
								return environ[rest.car.ident]
						end}
						
	LispFunctions["if"] = {fun = function(environ, rest)
								if (LispExecutor.exec(rest.car, environ)) then
									return LispExecutor.exec(rest.cdr.car, environ)
								elseif rest.cdr.cdr then
									return LispExecutor.exec(rest.cdr.cdr.car, environ)
								end
								
								return nil
						end}
	LispFunctions["while"] = {fun = function(environ, rest)
								local rval
								while (LispExecutor.exec(rest.car, environ)) do
									rval = LispExecutor.exec(rest.cdr.car, environ)
								end
								
								return rval
						end}
	setmetatable(LispFunctions.quot, LispFunctions.MetaFunction)
	setmetatable(LispFunctions.lambda, LispFunctions.MetaFunction)
	setmetatable(LispFunctions.set, LispFunctions.MetaFunction)
	setmetatable(LispFunctions["if"], LispFunctions.MetaFunction)
	setmetatable(LispFunctions["while"], LispFunctions.MetaFunction)
	
	
	
	
	LispFunctions["true"] = true
	LispFunctions["false"] = false
	
	
	setmetatable(LispFunctions, {__index = getfenv(1)});
end

return pkg_init
