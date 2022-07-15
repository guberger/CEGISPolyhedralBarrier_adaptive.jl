struct _AF{N}
    a::SVector{N,VariableRef}
    β::VariableRef
end
_eval(af::_AF, point) = dot(point, af.a) + af.β

function compute_af(
        neg_points::Vector{Point{N}}, point::Point{N}, ϵ, βmax, solver
    ) where N
    model = solver()
    a = SVector(ntuple(
        k -> @variable(model, lower_bound=-1, upper_bound=1), Val(N)
    ))
    β = @variable(model, lower_bound=-βmax, upper_bound=βmax)
    r = @variable(model, upper_bound=10)
    af = _AF(a, β)

    for point in neg_points
        @constraint(model, _eval(af, point) + r + ϵ ≤ 0)
    end

    @constraint(model, _eval(af, point) - r - ϵ ≥ 0)

    @objective(model, Max, r)

    optimize!(model)

    @assert termination_status(model) == OPTIMAL
    @assert primal_status(model) == FEASIBLE_POINT

    return AffForm(value.(af.a), value(af.β)), value(r)
end