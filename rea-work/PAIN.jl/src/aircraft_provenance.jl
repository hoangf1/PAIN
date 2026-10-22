# Phase 29b/29c — aircraft-path NASA-default guard and provenance tags.
# Aircraft runs only (`source=:aircraft` / `aircraft_json=…`). Validation / :e11 /
# :synthetic paths do not call this and stay bit-identical.

const PROVENANCE_TAGS = ("measured", "assumed", "nasa_default")

"""NASA test-article numeric defaults from VALIDATION_GUIDELINE §2.10 (29a audit)."""
const NASA_DEFAULTS = (
    a_m = 0.508,
    theta0_deg = 56.6,
    r_p_m = 0.965,           # a + 0.457 User Manual grid
    phi_p_deg = 90.0,
    z_p_m = 0.90,
    η_n_bare = 0.05,         # aircraft register default (register g)
    C_struc = 3.0,
    NY = 10,
    c0_mps = 340.0,
    rho_kg_m3 = 1.225,
    bb_j2_scale = 0.5,
    bb_alpha = 2.0,
    d_m = 0.0,
    rotation_direction = 1,
    spbl_anchor_H = 3,
    η_lining_phase3 = 0.5,   # Phase III test article (register f)
)

"""Smeared Phase III wall mass from `MRP_*` (same formula as `PainInputs`)."""
nasa_default_m_wall() =
    MRP_RHO_2024 * (MRP_T_SKIN + MRP_A_STRINGER / MRP_D_STRINGER + MRP_A_FRAME / MRP_ELL_FRAME)

nasa_default_L() = test_article_length()

"""
    parse_tagged_value(raw; name) -> (value, tag_or_nothing)

Plain number → `(v, nothing)` (tag assigned later). Object `{"value":v,"tag":…}` →
validated tag. Unknown tag → clear error.
"""
function parse_tagged_value(raw; name::AbstractString="input")
    if raw isa Number
        return (float(raw), nothing)
    end
    has_value = false
    has_tag = false
    v = nothing
    tag = nothing
    try
        v = getproperty(raw, :value)
        has_value = true
    catch
    end
    if !has_value && raw isa AbstractDict
        if haskey(raw, "value")
            v = raw["value"]; has_value = true
        elseif haskey(raw, :value)
            v = raw[:value]; has_value = true
        end
    end
    try
        tag = getproperty(raw, :tag)
        has_tag = true
    catch
    end
    if !has_tag && raw isa AbstractDict
        if haskey(raw, "tag")
            tag = raw["tag"]; has_tag = true
        elseif haskey(raw, :tag)
            tag = raw[:tag]; has_tag = true
        end
    end
    if has_value && has_tag
        t = lowercase(String(tag))
        t in PROVENANCE_TAGS ||
            error("aircraft JSON: unknown provenance tag \"$tag\" for $name " *
                  "(allowed: measured | assumed | nasa_default)")
        return (float(v), t)
    end
    error("aircraft JSON: $name must be a number or {\"value\":…, \"tag\":\"measured|assumed|nasa_default\"}")
end

"""Resolve a plain-number deferred tag against a NASA default (29c)."""
function resolve_plain_tag(value::Real, nasa_default)
    if isapprox(float(value), float(nasa_default); atol=0, rtol=0)
        return "nasa_default"
    end
    return "assumed"
end

_prov_row(name::AbstractString, value, source::AbstractString) =
    (; name=String(name), value=value, source=String(source))

_input_row(name::AbstractString, value, tag::AbstractString) =
    (; name=String(name), value=value, tag=String(tag))

"""Look up a possibly-tagged numeric field on `obj` under any of `keys`."""
function _get_tagged(obj, keys::Tuple; name::AbstractString="")
    obj === nothing && return nothing
    for k in keys
        v = nothing
        try
            v = getproperty(obj, k)
        catch
            v = nothing
        end
        if v === nothing && obj isa AbstractDict
            for kk in (k, String(k))
                haskey(obj, kk) || continue
                v = obj[kk]
                break
            end
        end
        v === nothing && continue
        return parse_tagged_value(v; name=isempty(name) ? String(k) : name)
    end
    return nothing
end

"""Read a plain (or `{value,tag}`) string/symbol field."""
function _get_tagged_symbol(obj, keys::Tuple; name::AbstractString="", allowed=())
    obj === nothing && return nothing
    for k in keys
        raw = _get(obj, k, nothing)
        raw === nothing && continue
        tag = "assumed"
        val = raw
        if !(raw isa AbstractString || raw isa Symbol || raw isa Bool)
            try
                val = getproperty(raw, :value)
                tag = lowercase(String(getproperty(raw, :tag)))
                tag in PROVENANCE_TAGS ||
                    error("aircraft JSON: unknown provenance tag \"$tag\" for $name")
            catch e
                e isa ErrorException && rethrow()
                error("aircraft JSON: $name must be a string or {\"value\":…, \"tag\":…}")
            end
        end
        if val isa Bool
            return (; value=val, tag)
        end
        s = Symbol(lowercase(String(val)))
        isempty(allowed) || s in allowed ||
            error("aircraft JSON: $name must be one of $(join(allowed, "|")), got $s")
        return (; value=s, tag)
    end
    return nothing
end

"""
    apply_aircraft_cabin_json(cfg, kw) -> NamedTuple

Merge aircraft JSON `cabin` (and existing 38f fuselage/air/propeller_placement
card keys) into pipeline kwargs. Geometry `L`/`a`/`θ0`/`r_p` are taken only from
the `cabin` object so documentary `fuselage.L_m` in older examples does not change
pipeline numbers. Returns `(; kwargs, provenance_inputs, supplied_names)`.
"""
function apply_aircraft_cabin_json(cfg, kw)
    L = kw.L
    a = kw.a
    theta0_deg = kw.theta0_deg
    r_p = kw.r_p
    phi_p_deg = kw.phi_p_deg
    z_p = kw.z_p
    rotation_direction = kw.rotation_direction
    η_n_bare = kw.η_n_bare
    C_struc = kw.C_struc
    NY = kw.NY
    ρ0 = kw.ρ0
    c0 = kw.c0
    ρ_ext = kw.ρ_ext
    c_ext = kw.c_ext
    ρ_int = kw.ρ_int
    c_int = kw.c_int
    L_c = kw.L_c
    d = kw.d
    use_table_d1 = kw.use_table_d1
    structural_solver = kw.structural_solver
    m_wall = kw.m_wall
    bb_j2_scale = kw.bb_j2_scale
    bb_α = kw.bb_α
    broadband_model = kw.broadband_model
    spbl_anchor_H = kw.spbl_anchor_H
    q_max = kw.q_max
    allow_extrapolation = kw.allow_extrapolation
    bands = kw.bands
    η_r_band = kw.η_r_band
    η_n_band = kw.η_n_band
    trim = kw.trim

    inputs = NamedTuple[]
    supplied = Set{String}()

    function take!(name::String, parsed, apply!)
        parsed === nothing && return
        val, tag0 = parsed
        apply!(val)
        push!(supplied, name)
        nasa_ref = _nasa_ref_for(name)
        tag = tag0 === nothing ?
            (nasa_ref === nothing ? "assumed" : resolve_plain_tag(val, nasa_ref)) : tag0
        push!(inputs, _input_row(name, val, tag))
        return nothing
    end

    cabin = _get(cfg, :cabin, nothing)
    fuse_j = _get(cfg, :fuselage, nothing)
    air_j = _get(cfg, :air, nothing)
    pp_j = _get(cfg, :propeller_placement, nothing)

    # Geometry — only `cabin.*` (avoids re-binding documentary fuselage.L_m in older JSONs)
    take!("L_m", _get_tagged(cabin, (:L_m, :L); name="L_m"), v -> (L = v))
    take!("a_m", _get_tagged(cabin, (:a_m, :a); name="a_m"), v -> (a = v))
    take!("theta0_deg", _get_tagged(cabin, (:theta0_deg,); name="theta0_deg"), v -> (theta0_deg = v))
    take!("r_p_m", _get_tagged(cabin, (:r_p_m, :r_p); name="r_p_m"), v -> (r_p = v))
    take!("phi_p_deg", _get_tagged(cabin, (:phi_p_deg,); name="phi_p_deg"), v -> (phi_p_deg = v))
    take!("z_p_m", _get_tagged(cabin, (:z_p_m, :z_p); name="z_p_m"), v -> (z_p = v))

    # Prefer first non-nothing parse (Julia `something` errors when all are nothing).
    _first(xs...) = (for x in xs; x !== nothing && return x; end; nothing)

    # Card 9 / 36 — cabin or existing fuselage / propeller_placement keys (38f)
    take!("L_c_m",
          _first(_get_tagged(cabin, (:L_c_m, :L_c); name="L_c_m"),
                 _get_tagged(fuse_j, (:L_c_m,); name="L_c_m")),
          v -> (L_c = v))
    take!("d_m",
          _first(_get_tagged(cabin, (:d_m, :d); name="d_m"),
                 _get_tagged(fuse_j, (:d_m,); name="d_m")),
          v -> (d = v))
    take!("rotation_direction",
          _first(_get_tagged(cabin, (:rotation_direction,); name="rotation_direction"),
                 _get_tagged(pp_j, (:rotation_direction,); name="rotation_direction")),
          v -> (rotation_direction = Int(round(v))))

    # Air (card 2) — cabin or air (not operating_point: that feeds F1A only today)
    take!("rho_kg_m3",
          _first(_get_tagged(cabin, (:rho_kg_m3, :ρ0, :rho0); name="rho_kg_m3"),
                 _get_tagged(air_j, (:rho_kg_m3, :rho0); name="rho_kg_m3")),
          v -> (ρ0 = v))
    take!("c0_mps",
          _first(_get_tagged(cabin, (:c0_mps, :c0); name="c0_mps"),
                 _get_tagged(air_j, (:c0_mps, :c0); name="c0_mps")),
          v -> (c0 = v))
    take!("rho_ext_kg_m3",
          _first(_get_tagged(cabin, (:rho_ext_kg_m3,); name="rho_ext_kg_m3"),
                 _get_tagged(air_j, (:rho_ext_kg_m3,); name="rho_ext_kg_m3")),
          v -> (ρ_ext = v))
    take!("rho_int_kg_m3",
          _first(_get_tagged(cabin, (:rho_int_kg_m3,); name="rho_int_kg_m3"),
                 _get_tagged(air_j, (:rho_int_kg_m3,); name="rho_int_kg_m3")),
          v -> (ρ_int = v))
    take!("c_ext_mps",
          _first(_get_tagged(cabin, (:c_ext_mps,); name="c_ext_mps"),
                 _get_tagged(air_j, (:c_ext_mps,); name="c_ext_mps")),
          v -> (c_ext = v))
    take!("c_int_mps",
          _first(_get_tagged(cabin, (:c_int_mps,); name="c_int_mps"),
                 _get_tagged(air_j, (:c_int_mps,); name="c_int_mps")),
          v -> (c_int = v))

    take!("eta_n_bare",
          _get_tagged(cabin, (:eta_n_bare, :η_n_bare); name="eta_n_bare"),
          v -> (η_n_bare = v))
    take!("C_struc",
          _get_tagged(cabin, (:C_struc, :C); name="C_struc"),
          v -> (C_struc = v))
    take!("m_wall_kg_m2",
          _get_tagged(cabin, (:m_wall_kg_m2, :m_wall); name="m_wall_kg_m2"),
          v -> (m_wall = v))
    take!("NY",
          _get_tagged(cabin, (:NY, :ny); name="NY"),
          v -> (NY = Int(round(v))))
    take!("bb_j2_scale",
          _get_tagged(cabin, (:bb_j2_scale,); name="bb_j2_scale"),
          v -> (bb_j2_scale = v))
    take!("bb_alpha",
          _get_tagged(cabin, (:bb_alpha, :bb_α); name="bb_alpha"),
          v -> (bb_α = v))
    take!("spbl_anchor_H",
          _get_tagged(cabin, (:spbl_anchor_H,); name="spbl_anchor_H"),
          v -> (spbl_anchor_H = Int(round(v))))
    take!("q_max",
          _get_tagged(cabin, (:q_max,); name="q_max"),
          v -> (q_max = Int(round(v))))

    sol = _get_tagged_symbol(cabin, (:structural_solver,);
                             name="structural_solver", allowed=(:table_d1, :ritz, :appd))
    if sol !== nothing
        structural_solver = sol.value
        use_table_d1 = (structural_solver === :table_d1)
        push!(supplied, "structural_solver")
        push!(inputs, _input_row("structural_solver", String(structural_solver), sol.tag))
    else
        ut = cabin === nothing ? nothing : _get(cabin, :use_table_d1, nothing)
        if ut !== nothing
            use_table_d1 = ut isa Bool ? ut : Bool(ut)
            structural_solver = use_table_d1 ? :table_d1 : :ritz
            push!(supplied, "structural_solver")
            push!(inputs, _input_row("structural_solver", String(structural_solver), "assumed"))
        end
    end

    bb = _get_tagged_symbol(cabin, (:broadband_model,);
                            name="broadband_model", allowed=(:surrogate, :eq19))
    if bb !== nothing
        broadband_model = bb.value
        push!(supplied, "broadband_model")
        push!(inputs, _input_row("broadband_model", String(broadband_model), bb.tag))
    end

    ae = cabin === nothing ? nothing : _get(cabin, :allow_extrapolation, nothing)
    if ae !== nothing
        allow_extrapolation = ae isa Bool ? ae : Bool(ae)
        push!(supplied, "allow_extrapolation")
        push!(inputs, _input_row("allow_extrapolation", allow_extrapolation, "assumed"))
    end

    tr = _get_tagged_symbol(cabin, (:trim,); name="trim", allowed=(:auto, :bare, :phase3))
    if tr !== nothing
        trim = tr.value
        push!(supplied, "trim")
        push!(inputs, _input_row("trim", String(trim), tr.tag))
    end

    if bands === nothing
        bj = _get(cfg, :bands_Hz, nothing)
        bj === nothing && (bj = _get(cfg, :bands, nothing))
        bj === nothing && cabin !== nothing && (bj = _get(cabin, :bands_Hz, nothing))
        bands = bj
        if bands !== nothing
            push!(supplied, "bands_Hz")
            push!(inputs, _input_row("bands_Hz", "user", "assumed"))
        end
    end
    if η_r_band === nothing
        η_r_band = _get(cfg, :eta_r_band, nothing)
        η_r_band === nothing && (η_r_band = _get(cfg, :η_r_band, nothing))
        η_r_band === nothing && cabin !== nothing && (η_r_band = _get(cabin, :eta_r_band, nothing))
        if η_r_band !== nothing
            push!(supplied, "eta_r_band")
            push!(inputs, _input_row("eta_r_band", "user", "assumed"))
        end
    end
    if η_n_band === nothing
        η_n_band = _get(cfg, :eta_n_band, nothing)
        η_n_band === nothing && (η_n_band = _get(cfg, :η_n_band, nothing))
        η_n_band === nothing && cabin !== nothing && (η_n_band = _get(cabin, :eta_n_band, nothing))
        if η_n_band !== nothing
            push!(supplied, "eta_n_band")
            push!(inputs, _input_row("eta_n_band", "user", "assumed"))
        end
    end

    new_kw = (;
        L, a, theta0_deg, r_p, phi_p_deg, z_p, rotation_direction,
        η_n_bare, C_struc, NY, ρ0, c0, ρ_ext, c_ext, ρ_int, c_int,
        L_c, d, use_table_d1, structural_solver, m_wall,
        bb_j2_scale, bb_α, broadband_model, spbl_anchor_H, q_max, allow_extrapolation,
        bands, η_r_band, η_n_band, trim,
    )
    return (; kwargs=new_kw, provenance_inputs=inputs, supplied_names=supplied)
end

function _nasa_ref_for(name::AbstractString)
    name == "L_m" && return nasa_default_L()
    name == "a_m" && return NASA_DEFAULTS.a_m
    name == "theta0_deg" && return NASA_DEFAULTS.theta0_deg
    name == "r_p_m" && return NASA_DEFAULTS.r_p_m
    name == "phi_p_deg" && return NASA_DEFAULTS.phi_p_deg
    name == "z_p_m" && return NASA_DEFAULTS.z_p_m
    name == "rotation_direction" && return NASA_DEFAULTS.rotation_direction
    name == "eta_n_bare" && return NASA_DEFAULTS.η_n_bare
    name == "C_struc" && return NASA_DEFAULTS.C_struc
    name == "m_wall_kg_m2" && return nasa_default_m_wall()
    name == "NY" && return NASA_DEFAULTS.NY
    name == "bb_j2_scale" && return NASA_DEFAULTS.bb_j2_scale
    name == "bb_alpha" && return NASA_DEFAULTS.bb_alpha
    name == "spbl_anchor_H" && return NASA_DEFAULTS.spbl_anchor_H
    name == "d_m" && return NASA_DEFAULTS.d_m
    name == "rho_kg_m3" && return NASA_DEFAULTS.rho_kg_m3
    name == "c0_mps" && return NASA_DEFAULTS.c0_mps
    name == "rho_ext_kg_m3" && return NASA_DEFAULTS.rho_kg_m3
    name == "rho_int_kg_m3" && return NASA_DEFAULTS.rho_kg_m3
    name == "c_ext_mps" && return NASA_DEFAULTS.c0_mps
    name == "c_int_mps" && return NASA_DEFAULTS.c0_mps
    return nothing
end

"""
    collect_nasa_defaults_used(; …) -> Vector{NamedTuple}

29b list: every §2.10 test-article default this aircraft run actually used.
A JSON value tagged `assumed` or `measured` is omitted even if numerically equal
to a NASA default; tag `nasa_default` is listed.
"""
function collect_nasa_defaults_used(;
        L, a, theta0_deg, r_p, phi_p_deg, z_p, rotation_direction,
        η_n_bare, C_struc, NY, ρ0, c0, L_c, d,
        m_wall_resolved, m_wall_was_fallback::Bool,
        structural_solver::Symbol, use_table_d1::Bool,
        bb_j2_scale, bb_α, broadband_model::Symbol, spbl_anchor_H::Int,
        trim_used::Symbol, sidewall_is_phase3::Bool,
        supplied::Set{String},
        input_rows::Vector{<:NamedTuple})
    tag_of = Dict{String,String}(r.name => r.tag for r in input_rows)
    out = NamedTuple[]

    function maybe!(name, value, source; nasa=nothing)
        if name in supplied
            t = get(tag_of, name, "assumed")
            if t == "nasa_default"
                push!(out, _prov_row(name, value, source))
            end
            return
        end
        if nasa === nothing ||
           (nasa isa Number && isapprox(float(value), float(nasa); atol=0, rtol=0)) ||
           (nasa isa Bool && value == nasa) ||
           (nasa isa Symbol && value == nasa) ||
           (nasa isa AbstractString && string(value) == string(nasa))
            push!(out, _prov_row(name, value, source))
        end
    end

    maybe!("L_m", L, "run_pain_pipeline / TEST_ARTICLE_L"; nasa=nasa_default_L())
    maybe!("a_m", a, "run_pain_pipeline default"; nasa=NASA_DEFAULTS.a_m)
    maybe!("theta0_deg", theta0_deg, "run_pain_pipeline default"; nasa=NASA_DEFAULTS.theta0_deg)
    maybe!("r_p_m", r_p, "run_pain_pipeline default"; nasa=NASA_DEFAULTS.r_p_m)
    maybe!("phi_p_deg", phi_p_deg, "run_pain_pipeline default"; nasa=NASA_DEFAULTS.phi_p_deg)
    maybe!("z_p_m", z_p, "run_pain_pipeline default"; nasa=NASA_DEFAULTS.z_p_m)
    maybe!("rotation_direction", Int(rotation_direction), "Manual card 36 default";
           nasa=NASA_DEFAULTS.rotation_direction)
    maybe!("eta_n_bare", η_n_bare, "register g / PainInputs"; nasa=NASA_DEFAULTS.η_n_bare)
    maybe!("C_struc", C_struc, "register g / Eq. (80)"; nasa=NASA_DEFAULTS.C_struc)
    maybe!("NY", NY, "cyl2d_modes default"; nasa=NASA_DEFAULTS.NY)
    maybe!("c0_mps", c0, "pipeline c0 default"; nasa=NASA_DEFAULTS.c0_mps)
    maybe!("rho_kg_m3", ρ0, "pipeline ρ0 default"; nasa=NASA_DEFAULTS.rho_kg_m3)
    maybe!("d_m", d, "card 9 default"; nasa=NASA_DEFAULTS.d_m)

    if !("L_c_m" in supplied) && isapprox(L_c, L; atol=0, rtol=0)
        push!(out, _prov_row("L_c_m", L_c, "card 9 default (= fuse.L)"))
    elseif "L_c_m" in supplied && get(tag_of, "L_c_m", "") == "nasa_default"
        push!(out, _prov_row("L_c_m", L_c, "card 9 / user tag nasa_default"))
    end

    if m_wall_was_fallback
        if !("m_wall_kg_m2" in supplied)
            push!(out, _prov_row("m_wall_kg_m2", m_wall_resolved,
                                 "MRP_* smeared skin (PainInputs NaN fallback)"))
        elseif get(tag_of, "m_wall_kg_m2", "") == "nasa_default"
            push!(out, _prov_row("m_wall_kg_m2", m_wall_resolved, "MRP_* / user tag nasa_default"))
        end
    end

    if structural_solver === :table_d1 || use_table_d1
        if !("structural_solver" in supplied)
            push!(out, _prov_row("structural_solver", "table_d1",
                                 "hybrid Table D-1 modes (use_table_d1=true)"))
        elseif get(tag_of, "structural_solver", "") == "nasa_default"
            push!(out, _prov_row("structural_solver", "table_d1", "Table D-1 / user tag nasa_default"))
        end
    end

    maybe!("spbl_anchor_H", spbl_anchor_H, "blocked_broadband_band_p2 H anchor";
           nasa=NASA_DEFAULTS.spbl_anchor_H)
    maybe!("bb_alpha", bb_α, "Spbl f⁻α slope (V-ASSUMED)"; nasa=NASA_DEFAULTS.bb_alpha)

    if broadband_model === :surrogate
        maybe!("bb_j2_scale", bb_j2_scale, "stale T2 fit / interior_spl"; nasa=NASA_DEFAULTS.bb_j2_scale)
        if !("broadband_model" in supplied)
            push!(out, _prov_row("absorption_curve", "absorption_coefficient(f)",
                                 "trim_loss.jl surrogate α(f)"))
        elseif get(tag_of, "broadband_model", "") == "nasa_default"
            push!(out, _prov_row("absorption_curve", "absorption_coefficient(f)",
                                 "surrogate / user tag nasa_default"))
        end
    end

    if sidewall_is_phase3 || trim_used === :phase3
        if !("trim" in supplied) || get(tag_of, "trim", "") == "nasa_default"
            push!(out, _prov_row("phase3_trim", "phase3_trim()",
                                 "trim_loss.jl Phase III stacks (App. E p. E-8)"))
            push!(out, _prov_row("PF105_fig_A2", "data/cr3813/fig_a2_pf105.csv",
                                 "App. A insulation table"))
            push!(out, _prov_row("end_plate_aluminium", "1.3 cm Al path",
                                 "phase3_trim end-plate mass"))
            push!(out, _prov_row("eta_lining", NASA_DEFAULTS.η_lining_phase3,
                                 "phase3_trim η_lining default (p. E-24)"))
        end
    end

    return out
end

"""Warn once listing every NASA default used on this aircraft run."""
function warn_nasa_defaults!(nasa_defaults::Vector{<:NamedTuple})
    isempty(nasa_defaults) && return nothing
    parts = ["$(r.name)=$(r.value)" for r in nasa_defaults]
    @warn "Aircraft run uses NASA test-article defaults (phase 29b): " * join(parts, ", ")
    return nothing
end

"""Header label fragments for report / GUI."""
function provenance_header_labels(prov)
    nasa = prov.nasa_defaults
    inputs = prov.inputs
    uses = isempty(nasa) ? "" :
        "uses NASA test-article defaults: " * join((String(r.name) for r in nasa), ", ")
    tagged_nasa = [String(r.name) for r in inputs if r.tag == "nasa_default"]
    names = unique(vcat(tagged_nasa, [String(r.name) for r in nasa]))
    article = isempty(names) ? "" :
        "NASA test article inputs used for: " * join(names, ", ") * ", not the aircraft"
    return (; uses_defaults=uses, nasa_article=article)
end

empty_provenance() = (; nasa_defaults=NamedTuple[], inputs=NamedTuple[])
