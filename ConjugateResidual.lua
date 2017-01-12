--[[
source: https://en.wikipedia.org/wiki/Conjugate_residual_method#Preconditioning
args:
	A = linear function A : x -> x
	b = solution vector
	x0 (optional) = initial guess vector
	clone = vector clone function
	dot = vector dot function
	MInv = inverse of preconditioner linear function MInv : x -> x
	errorCallback (optional) = function(|r|/|b|, iteration, x, |r|^2, |b|^2)
		accepts error, iteration; returns true if iterations should be stopped
	epsilon (optional)
	maxiter (optional)

vectors need operators + - * overloaded

this method applies MInv to r, then computes norms, etc
the conjugate gradient applies MInv as a weighted norm of r (i.e. only applies once between r's rather than twice) 
which is better?
which is correct?

--]]
return function(args)
	local A = assert(args.A)
	local b = assert(args.b)
	local clone = assert(args.clone)
	local dot = assert(args.dot)
	local MInv = args.MInv or clone
	local errorCallback = args.errorCallback
	local epsilon = args.epsilon or 1e-50
	local maxiter = args.maxiter or 10000
	
	local bSq = dot(b,b)

	local x = clone(args.x0 or b)
	local r = MInv(b - A(x))

	local rSq = dot(r, r)
	local err = math.sqrt(bSq > 0 and rSq / bSq or rSq)
	if errorCallback and errorCallback(err, 0, x, rSq, bSq) then return x end
	if err < epsilon then return x end
	
	local Ar = A(r)
	local rAr = dot(r, Ar)
	local p = clone(r)
	local Ap = A(p)
	for iter=1,maxiter do
		local alpha = rAr / dot(Ap, MInv(Ap))	-- dot() could be replaced by weightedNorm() ...
		x = x + p * alpha
		local nr = r - MInv(Ap) * alpha
		local nAr = A(nr)
		local nrAr = dot(nr, nAr)
		local beta = nrAr / rAr

		rSq = dot(nr, nr)
		local err = math.sqrt(bSq > 0 and rSq / bSq or rSq)
		if errorCallback and errorCallback(err, iter, x, rSq, bSq) then break end
		if err < epsilon then break end

		r = nr
		rAr = nrAr
		Ar = nAr
		p = nr + p * beta
		Ap = nAr + Ap * beta
	end
	return x
end
