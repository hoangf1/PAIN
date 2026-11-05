# Phase 127 (2026-11-04): every PAIN input as a GUI field.
#
# Author 2026-11-04: "instead of a json id like the user inputs in the gui", "if there are any constants then make it
# available for change in the gui". The Run tab edits fields, grouped in tabs; a project file (the aircraft JSON format)
# is only an optional Open / Save. A run writes the project to a temporary file and calls `run_pain_pipeline` with it.
#
# Rule that keeps the default run unchanged: a field is written to the project only when its value differs from the
# project it was loaded from (a loaded value, with its provenance tag, is kept as it was), and a value equal to the code's
# own default is not added. So the default project runs exactly as `run_pain_pipeline` does without the GUI.

"""Path of the GUI's default project: the generic twin turboprop of Cabin_Noise's default project, values copied by
hand (Phase 128; the two programs share no code or file). The scale Hartzell project stays in examples/."""
gui_default_project_path() = normpath(joinpath(@__DIR__, "..", "examples", "aircraft_generic_twin_turboprop.json"))

_F(key, group, label, unit, kind, path, default, tip; choices=String[], optional=false) =
    (; key=String(key), group=String(group), label=String(label), unit=String(unit), kind=kind,
     path=String.(path), default=String(default), tip=String(tip), choices=String.(choices), optional=optional)

const _APPD_LABELS = Dict(
    "t_skin_m" => ("Skin thickness", "m"), "t_floor_m" => ("Floor thickness", "m"),
    "A_stringer_m2" => ("Stringer area", "m²"), "d_stringer_m" => ("Stringer spacing", "m"),
    "I_stringer_m4" => ("Stringer inertia", "m⁴"), "A_frame_m2" => ("Frame area", "m²"),
    "ell_frame_m" => ("Frame spacing", "m"), "I_frame_m4" => ("Frame inertia", "m⁴"),
    "A_floor_beam_m2" => ("Floor beam area", "m²"), "I_floor_beam_m4" => ("Floor beam inertia", "m⁴"),
    "E_Pa" => ("Young's modulus E", "Pa"), "nu" => ("Poisson's ratio ν", ""),
    "rho_struc_kg_m3" => ("Structure density", "kg/m³"),
    "t_shell_card_m" => ("Card: shell thickness", "m"), "m_shell_kg_m2" => ("Card: shell mass", "kg/m²"),
    "Dp_stringers_Nm" => ("Card: D′ stringers", "N·m"), "Dp_frames_Nm" => ("Card: D′ frames", "N·m"),
    "t_floor_card_m" => ("Card: floor thickness", "m"), "m_floor_kg_m2" => ("Card: floor mass", "kg/m²"),
    "Dp_floor_beams_Nm" => ("Card: D′ floor beams", "N·m"), "Dp_floor_supports_Nm" => ("Card: D′ floor supports", "N·m"))

_gstr(x) = x isa AbstractFloat ? repr(Float64(x)) : string(x)

# Phase 130 (2026-11-04, author: broadband "shouldnt be an input currently especially if it hasnt been verified"): the
# interior broadband path (Eqs. 19–23 or the surrogate, from an f^−α exterior spectrum anchored to a tone) has no met
# comparison with data, so the GUI has no broadband field and every GUI run is tones only (`gui_run_args` sets
# settings.broadband = false). The code path stays for the validation cases. Hidden settings:
const GUI_BROADBAND_SETTINGS = (:broadband, :bb_start_Hz, :bb_tone_skip, :j2_fallback, :j2_min, :surr_bw_rel, :surr_n_coef,
                                :surr_n_fref_Hz, :surr_df_min_Hz, :surr_nref_modes, :surr_nref_fc_Hz, :surr_chi_min,
                                :surr_chi_max)

"""
GUI input fields: (key, group, label, unit, kind, path, default, tip, choices, optional). `path` is the place in the
project file; `default` is what the code uses when the project does not give the value (as text; "" for optional fields
that mean "not given"). Kinds: :float, :int, :bool, :choice, :list (comma-separated numbers), :bandmap ("band: value" pairs
or a list), :text, :elements (one trim element per line). The `PainSettings` fields follow as `settings.<name>`.
"""
function gui_input_specs()
    nd = NASA_DEFAULTS
    f = Any[
        # Run
        _F("blocking", "Run", "Blocking variant", "", :choice, ["run", "blocking"], "R2",
           "Eq. 43 blocking: R2 = 0.8 × Eq. 43, at least 1 (CR-172428 §5.3.2); R1 = Eq. 43 itself"; choices=["R2", "R1"]),
        _F("n_harmonics", "Run", "Harmonics", "", :int, ["run", "n_harmonics"], "5",
           "Number of blade-passage harmonics H = 1…n."),
        _F("cabin_blocks", "Run", "Cabin blocks", "", :choice, ["cabin", "cabin_blocks"], "auto",
           "auto = parametric on the aircraft path (App. D modes, Eqs. 19–23 broadband); surrogate = Table D-1 path";
           choices=["auto", "parametric", "surrogate"]),
        # Propeller
        _F("num_blades", "Propeller", "Blades B", "", :int, ["propeller", "num_blades"], "6", "Number of blades."),
        _F("rpm", "Propeller", "Shaft speed", "rpm", :float, ["propeller", "rpm"], "1181", "Propeller rpm; BPF = B·rpm/60."),
        _F("tip_radius_m", "Propeller", "Tip radius", "m", :float, ["propeller", "tip_radius_m"], "1.7526", "Blade tip radius."),
        _F("hub_radius_m", "Propeller", "Hub radius", "m", :float, ["propeller", "hub_radius_m"], "0.368", "Hub radius (BEMT hub loss)."),
        _F("pitch_offset_deg", "Propeller", "Pitch offset", "deg", :float, ["propeller", "pitch_offset_deg"], "0.0",
           "Added to every section twist (blade pitch setting)."),
        _F("thickness_over_chord", "Propeller", "Thickness / chord", "", :float, ["propeller", "thickness_over_chord"], "0.0",
           "Section t/c for the F1A thickness term (0 = loading only)."),
        _F("radii_m", "Propeller", "Station radii", "m", :list, ["propeller", "radii_m"], "",
           "Blade station radii, hub to tip (comma-separated)."),
        _F("chord_m", "Propeller", "Station chords", "m", :list, ["propeller", "chord_m"], "",
           "Chord at each station (same count as the radii)."),
        _F("twist_deg", "Propeller", "Station twist", "deg", :list, ["propeller", "twist_deg"], "",
           "Twist at each station (same count as the radii)."),
        _F("area_over_chord2", "Propeller", "Station area / chord²", "", :list, ["propeller", "area_over_chord2"], "",
           "Per-station cross-section area / chord² for the thickness term; blank = t/c at every station."; optional=true),
        # Flight condition
        _F("forward_speed_mps", "Flight", "Flight speed", "m/s", :float, ["operating_point", "forward_speed_mps"], "20.0",
           "Free-stream speed at the propeller (below the static guard it is replaced; Numerics: Source)."),
        _F("op_rho", "Flight", "Air density at the propeller", "kg/m³", :float, ["operating_point", "rho_kg_m3"], "1.225",
           "Density for the BEMT loads and F1A."),
        _F("op_c0", "Flight", "Sound speed at the propeller", "m/s", :float, ["operating_point", "c0_mps"], "340.0",
           "Sound speed for F1A and the section Mach number."),
        _F("mu_Pa_s", "Flight", "Air viscosity", "Pa·s", :float, ["operating_point", "mu_Pa_s"], _gstr(AIR_MU_PA_S),
           "Dynamic viscosity for the section Reynolds number."),
        _F("anopp_table8_calibrate", "Flight", "Scale to ANOPP Table 8 peaks", "", :bool, ["anopp_table8_calibrate"], "true",
           "Scale the free field so its ℓ = 1 peaks match CR-3813 Table 8 (the code's default when the project does not say)."),
        _F("anopp_table8_csv", "Flight", "Table 8 file", "", :text, ["anopp_table8_csv"], "",
           "Peak levels to scale to; blank = data/cr3813/anopp_table8_spl_dB.csv."; optional=true),
        # Placement
        _F("r_p_m", "Placement", "Hub distance from axis r_p", "m", :float, ["cabin", "r_p_m"], _gstr(nd.r_p_m),
           "Propeller hub to fuselage axis (User Manual: a + 0.457 m)."),
        _F("phi_p_deg", "Placement", "Hub azimuth φ_p", "deg", :float, ["cabin", "phi_p_deg"], _gstr(nd.phi_p_deg),
           "Hub azimuth from the bottom centreline (90 = level with the axis)."),
        _F("z_p_m", "Placement", "Propeller plane station z_p", "m", :float, ["cabin", "z_p_m"], _gstr(nd.z_p_m),
           "Propeller plane from the forward end of the cabin."),
        _F("rotation_direction", "Placement", "Rotation sense", "", :choice, ["cabin", "rotation_direction"], "1",
           "User Manual card 36: +1 or −1."; choices=["1", "-1"]),
        # Cabin
        _F("L_m", "Cabin", "Structure length L", "m", :float, ["cabin", "L_m"], _gstr(test_article_length()), "Cylinder length."),
        _F("a_m", "Cabin", "Radius a", "m", :float, ["cabin", "a_m"], _gstr(nd.a_m), "Fuselage radius."),
        _F("theta0_deg", "Cabin", "Floor angle θ0", "deg", :text, ["cabin", "theta0_deg"], "auto",
           "Floor angle from the bottom centreline; auto = the printed aircraft nearest in radius."),
        _F("L_c_m", "Cabin", "Cavity length L_c", "m", :float, ["cabin", "L_c_m"], "",
           "Cabin cavity length; blank = L (card 9)."; optional=true),
        _F("d_m", "Cabin", "Cavity offset d", "m", :float, ["cabin", "d_m"], _gstr(nd.d_m),
           "Start of the structure from the start of the cavity (card 9)."),
        _F("rho_kg_m3", "Cabin", "Air density ρ0", "kg/m³", :float, ["cabin", "rho_kg_m3"], _gstr(nd.rho_kg_m3),
           "Air density outside and inside unless set below."),
        _F("c0_mps", "Cabin", "Sound speed c0", "m/s", :float, ["cabin", "c0_mps"], _gstr(nd.c0_mps),
           "Sound speed outside and inside unless set below."),
        _F("rho_ext_kg_m3", "Cabin", "Outside density", "kg/m³", :float, ["cabin", "rho_ext_kg_m3"], "", "Blank = ρ0."; optional=true),
        _F("c_ext_mps", "Cabin", "Outside sound speed", "m/s", :float, ["cabin", "c_ext_mps"], "", "Blank = c0."; optional=true),
        _F("rho_int_kg_m3", "Cabin", "Cabin density", "kg/m³", :float, ["cabin", "rho_int_kg_m3"], "", "Blank = ρ0."; optional=true),
        _F("c_int_mps", "Cabin", "Cabin sound speed", "m/s", :float, ["cabin", "c_int_mps"], "", "Blank = c0."; optional=true),
        _F("NY", "Cabin", "CYL2D grid NY", "", :int, ["cabin", "NY"], string(nd.NY), "App. C finite-difference grid (card 7)."),
        _F("q_max", "Cabin", "Axial cabin modes q_max", "", :int, ["cabin", "q_max"], "",
           "Highest axial cabin mode; blank = automatic truncation."; optional=true),
        # Structure
        _F("structural_solver", "Structure", "Structural modes", "", :choice, ["cabin", "structural_solver"], "auto",
           "auto = App. D on the parametric path; table_d1 = NASA's printed Table D-1; ritz = surrogate";
           choices=["auto", "appd", "table_d1", "ritz"]),
        _F("m_wall_kg_m2", "Structure", "Wall mass per area", "kg/m²", :float, ["cabin", "m_wall_kg_m2"], "",
           "Blank = smeared from the structure given here: skin + stringers + frames, or the card shell mass."; optional=true),
    ]
    for s in APPD_INPUT_SPECS
        lab, unit = _APPD_LABELS[s.name]
        push!(f, _F(s.name, "Structure", lab, unit, :float, ["cabin", s.name], _gstr(s.nasa()), "App. D input (default: CR-3813 test article)."))
    end
    for s in APPD_DECK_SPECS
        lab, unit = _APPD_LABELS[s.name]
        push!(f, _F(s.name, "Structure", lab, unit, :float, ["cabin", s.name], "",
                    "PAIN's own MRP card value (cards 10–15); give all eight to describe the structure as NASA's deck does."; optional=true))
    end
    append!(f, Any[
        # Damping & trim
        _F("eta_n_bare", "Damping and trim", "Cabin loss factor η_n (bare)", "", :float, ["cabin", "eta_n_bare"], _gstr(nd.η_n_bare),
           "Acoustic loss factor of an untrimmed cabin."),
        _F("C_struc", "Damping and trim", "Structural damping C (Eq. 80)", "", :float, ["cabin", "C_struc"], _gstr(nd.C_struc),
           "η_r′ = C / f_r (CR-3813: C between 2 and 4)."),
        _F("trim", "Damping and trim", "Trim", "", :choice, ["cabin", "trim"], "auto",
           "auto = bare on the aircraft path; phase3 = the CR-3813 Phase III treatment; stack = the layers below";
           choices=["auto", "bare", "phase3", "stack"]),
        _F("trim_insulation_table", "Damping and trim", "Stack: insulation table", "", :text, ["cabin", "trim_stack", "insulation_table"], "",
           "Insulation property file (blank = PF-105, Fig. A-2)."; optional=true),
        _F("trim_sidewall", "Damping and trim", "Stack: sidewall elements", "", :elements, ["cabin", "trim_stack", "sidewall", "elements"],
           "insulation 0.0508\nlimp_mass 0.095 0.05",
           "One per line, outside to inside: \"insulation <thickness m>\" or \"limp_mass <kg/m²> [η]\"."),
        _F("trim_endplates", "Damping and trim", "Stack: end plate elements", "", :elements, ["cabin", "trim_stack", "endplates", "elements"], "",
           "Same form; blank = one 13 mm insulation layer."; optional=true),
        _F("trim_mech", "Damping and trim", "Stack: mechanical path", "", :bool, ["cabin", "trim_stack", "mechanical"], "false",
           "Add the frame-to-trim mechanical path (Eqs. A.23–A.26)."),
        _F("mech_m_t", "Damping and trim", "Mechanical: trim mass", "kg/m²", :float, ["cabin", "trim_stack", "mechanical", "m_t"], "0.1", ""),
        _F("mech_h_t", "Damping and trim", "Mechanical: trim thickness", "m", :float, ["cabin", "trim_stack", "mechanical", "h_t"], "0.00079", ""),
        _F("mech_c_t", "Damping and trim", "Mechanical: trim wave speed", "m/s", :float, ["cabin", "trim_stack", "mechanical", "c_t"], "3200.0", ""),
        _F("mech_eta_t", "Damping and trim", "Mechanical: trim loss factor", "", :float, ["cabin", "trim_stack", "mechanical", "eta_t"], "0.05", ""),
        _F("mech_N_points", "Damping and trim", "Mechanical: point mounts", "", :int, ["cabin", "trim_stack", "mechanical", "N_points"], "0", ""),
        _F("mech_n_lines", "Damping and trim", "Mechanical: line mounts", "", :float, ["cabin", "trim_stack", "mechanical", "n_lines"], "0.0",
           "Lines along the cabin length."),
        # Bands (Phase 130: the broadband inputs are not GUI fields; GUI runs are tones only, see GUI_BROADBAND_SETTINGS)
        _F("allow_extrapolation", "Bands", "Extrapolate the insulation table", "", :bool, ["cabin", "allow_extrapolation"], "false",
           "Continue the insulation properties beyond Fig. A-2."),
        _F("bands_Hz", "Bands", "Band centres", "Hz", :list, ["bands_Hz"], "",
           "1/3-octave centres to report (cards 3–6); blank = 63 Hz … 8 kHz."; optional=true),
        _F("eta_r_band", "Bands", "η_r per band", "", :bandmap, ["eta_r_band"], "",
           "Structural loss factor per band (cards 11–18), \"1000: 0.02, 1250: 0.03\" or one value per band centre above; blank = Eqs. 79–82."; optional=true),
        _F("eta_n_band", "Bands", "η_n per band", "", :bandmap, ["eta_n_band"], "",
           "Cabin loss factor per band, in the same form; blank = Eq. 77 or the bare value."; optional=true),
    ])
    base = PainSettings()
    for s in PAIN_SETTING_SPECS
        s.key in GUI_BROADBAND_SETTINGS && continue
        v = getfield(base, s.key)
        push!(f, _F("settings." * String(s.key), "Numerics: " * s.group, s.label, s.unit, s.kind, ["settings", String(s.key)],
                    v isa Symbol ? String(v) : _gstr(v), s.tip; choices=s.choices))
    end
    return f
end

# ---- project dictionaries ------------------------------------------------------------------------------------------

_load_project_dict(path::AbstractString) = JSON3.read(read(path, String), Dict{String,Any})

function _path_get(d, path::Vector{String})
    x = d
    for k in path
        x isa AbstractDict || return nothing
        haskey(x, k) || return nothing
        x = x[k]
    end
    return x
end

function _path_set!(d::AbstractDict, path::Vector{String}, v)
    x = d
    for k in path[1:end-1]
        (haskey(x, k) && x[k] isa AbstractDict) || (x[k] = Dict{String,Any}())
        x = x[k]
    end
    x[path[end]] = v
    return d
end

function _path_delete!(d::AbstractDict, path::Vector{String})
    x = _path_get(d, path[1:end-1])
    x isa AbstractDict && delete!(x, path[end])
    return d
end

"""A loaded value without its provenance tag ({"value": v, "tag": t} → v)."""
_untag(v) = v isa AbstractDict && haskey(v, "value") ? v["value"] : v

# Other places the code reads a value from when the field's own path is absent (cabin aliases, then the fuselage / air /
# propeller_placement / cabin.structure objects; the band cards at the top level or in cabin), in the code's order
# (aircraft_provenance.jl). Keyed by field key.
const _GUI_ALT_KEYS = Dict(
    "L_m" => ["L"], "a_m" => ["a"], "r_p_m" => ["r_p"], "z_p_m" => ["z_p"], "L_c_m" => ["L_c"], "d_m" => ["d"],
    "rho_kg_m3" => ["ρ0", "rho0"], "c0_mps" => ["c0"], "eta_n_bare" => ["η_n_bare"], "C_struc" => ["C"],
    "m_wall_kg_m2" => ["m_wall"], "NY" => ["ny"], "bb_alpha" => ["bb_α"])
const _GUI_ALT_PATHS = Dict(
    "L_c_m" => [["fuselage", "L_c_m"]], "d_m" => [["fuselage", "d_m"]],
    "rotation_direction" => [["propeller_placement", "rotation_direction"]],
    "rho_kg_m3" => [["air", "rho_kg_m3"], ["air", "rho0"]], "c0_mps" => [["air", "c0_mps"], ["air", "c0"]],
    "rho_ext_kg_m3" => [["air", "rho_ext_kg_m3"]], "rho_int_kg_m3" => [["air", "rho_int_kg_m3"]],
    "c_ext_mps" => [["air", "c_ext_mps"]], "c_int_mps" => [["air", "c_int_mps"]],
    "bands_Hz" => [["bands"], ["cabin", "bands_Hz"]], "eta_r_band" => [["η_r_band"], ["cabin", "eta_r_band"]],
    "eta_n_band" => [["η_n_band"], ["cabin", "eta_n_band"]])

"""The value the code would read for a field: its own path, else an alias or a fallback object."""
function _effective_get(project, spec)
    v = _path_get(project, spec.path)
    v === nothing || return v
    if spec.path[1] == "cabin" && length(spec.path) == 2   # cabin aliases and cabin.structure before fallback objects
        k = spec.path[2]
        for alt in get(_GUI_ALT_KEYS, k, String[])
            v = _path_get(project, ["cabin", alt]); v === nothing || return v
        end
        for sp in (APPD_INPUT_SPECS..., APPD_DECK_SPECS...)
            sp.name == k || continue
            for key in sp.keys
                v = _path_get(project, ["cabin", String(key)]); v === nothing || return v
            end
            for key in sp.keys
                v = _path_get(project, ["cabin", "structure", String(key)]); v === nothing || return v
            end
        end
    end
    for p in get(_GUI_ALT_PATHS, spec.key, Vector{String}[])
        v = _path_get(project, p); v === nothing || return v
    end
    return nothing
end

# ---- text ↔ value ----------------------------------------------------------------------------------------------------

function _value_text(spec, v)
    v === nothing && return spec.default
    v = _untag(v)
    spec.kind === :list && return join((_gstr(x) for x in v), ", ")
    if spec.kind === :bandmap
        v isa AbstractDict || return join((_gstr(x) for x in v), ", ")
        ks = sort(collect(keys(v)); by=k -> something(tryparse(Float64, string(k)), Inf))
        return join(("$(k): $(_gstr(v[k]))" for k in ks), ", ")
    end
    spec.kind === :elements && return _elements_text(v)
    spec.kind === :bool && return string(v == true || v == "true")
    v isa AbstractDict && return string(get(v, "path", get(v, "file", "")))   # insulation table given as an object
    return _gstr(v)
end

function _elements_text(els)
    lines = String[]
    for el in els
        t = lowercase(String(get(el, "type", get(el, "kind", ""))))
        if t in ("insulation", "insulation_layer", "layer")
            push!(lines, "insulation " * _gstr(get(el, "thickness_m", get(el, "thickness", 0.0))))
        else
            m = get(el, "m_kg_m2", get(el, "m", 0.0))
            η = get(el, "eta", get(el, "η", nothing))
            push!(lines, "limp_mass " * _gstr(m) * (η === nothing ? "" : " " * _gstr(η)))
        end
    end
    return join(lines, "\n")
end

function _parse_elements(txt::AbstractString, label)
    els = Any[]
    for (i, ln) in enumerate(split(txt, '\n'))
        p = split(strip(ln))
        isempty(p) && continue
        t = lowercase(p[1])
        num(j) = (x = tryparse(Float64, p[j]); x === nothing ? error("$label, line $i: \"$(p[j])\" is not a number") : x)
        if t in ("insulation", "layer")
            length(p) == 2 || error("$label, line $i: \"insulation <thickness m>\"")
            push!(els, Dict{String,Any}("type" => "insulation", "thickness_m" => num(2)))
        elseif t in ("limp_mass", "limp", "septum", "facing")
            length(p) in (2, 3) || error("$label, line $i: \"limp_mass <kg/m²> [η]\"")
            el = Dict{String,Any}("type" => "limp_mass", "m_kg_m2" => num(2))
            length(p) == 3 && (el["eta"] = num(3))
            push!(els, el)
        else
            error("$label, line $i: element type must be insulation or limp_mass (got \"$(p[1])\")")
        end
    end
    return els
end

"""Field text → value (`nothing` for blank optional fields and for "auto" choices). Errors name the field."""
function _parse_field(spec, txt::AbstractString)
    s = strip(txt)
    lab = spec.label
    if isempty(s)
        (spec.optional || spec.kind in (:list, :bandmap, :text, :elements)) && return nothing
        error("$lab: a value is needed")
    end
    k = spec.kind
    if k === :float
        x = tryparse(Float64, s); x === nothing && error("$lab: \"$s\" is not a number"); return x
    elseif k === :int
        x = tryparse(Float64, s)
        (x === nothing || !isinteger(x)) && error("$lab: \"$s\" is not a whole number")
        return Int(x)
    elseif k === :bool
        s in ("true", "false") || error("$lab: true or false"); return s == "true"
    elseif k === :choice
        s in spec.choices || error("$lab: one of $(join(spec.choices, ", "))")
        s == "auto" && spec.path[1] != "settings" && return nothing   # "auto" = not given (the code decides)
        return spec.path[end] == "rotation_direction" ? parse(Int, s) : String(s)
    elseif k === :list
        xs = Float64[]
        for t in split(s, r"[,\s;]+"; keepempty=false)
            x = tryparse(Float64, t); x === nothing && error("$lab: \"$t\" is not a number"); push!(xs, x)
        end
        return xs
    elseif k === :elements
        return _parse_elements(s, lab)
    elseif k === :bandmap   # "1000: 0.02, 1250: 0.03" (band → value) or a list, one value per band centre
        occursin(':', s) || return _parse_field((; spec..., kind=:list), s)
        d = Dict{String,Any}()
        for t in split(s, r"[,;]+"; keepempty=false)
            kv = split(t, ':')
            length(kv) == 2 || error("$lab: \"$(strip(t))\" is not \"band: value\"")
            f = tryparse(Float64, strip(kv[1])); x = tryparse(Float64, strip(kv[2]))
            (f === nothing || x === nothing) && error("$lab: \"$(strip(t))\" is not \"band: value\"")
            d[_gstr(isinteger(f) ? Int(f) : f)] = x
        end
        return d
    else
        return String(s)
    end
end

_same(a, b) = a === nothing || b === nothing ? a === b :
              (a isa Number && b isa Number) ? a == b :
              (a isa AbstractVector && b isa AbstractVector) ? length(a) == length(b) && all(_same.(a, b)) :
              (a isa AbstractDict && b isa AbstractDict) ? keys(a) == keys(b) && all(_same(a[k], b[k]) for k in keys(a)) :
              string(a) == string(b)

# ---- GUI state ---------------------------------------------------------------------------------------------------------

"""Field texts of a project: the project's value where it gives one, else the code default."""
function gui_field_values(project::AbstractDict)
    vals = Dict{String,String}()
    tr = _path_get(project, ["cabin", "trim"])
    stack = _path_get(project, ["cabin", "trim_stack"])
    stack === nothing && _untag(tr) isa AbstractDict && (stack = tr)   # a stack given under cabin.trim
    for spec in gui_input_specs()
        if length(spec.path) >= 3 && spec.path[2] == "trim_stack"
            sub = stack === nothing ? nothing : _path_get(stack, spec.path[3:end])
            if spec.key == "trim_sidewall" && sub === nothing && stack !== nothing && haskey(stack, "elements")
                sub = stack["elements"]   # single stack form: elements at the top
            end
            vals[spec.key] = spec.key == "trim_mech" ? string(sub !== nothing) : _value_text(spec, sub)
        elseif spec.key == "trim"
            vals[spec.key] = stack !== nothing ? "stack" : _value_text(spec, tr)
        else
            vals[spec.key] = _value_text(spec, _effective_get(project, spec))
        end
    end
    return vals
end

"""
    gui_build_project(base, values) -> Dict

The project to run: `base` (the loaded project) with every changed field written. Unchanged fields keep the loaded
value and tag; a value equal to the code default is not added; blank optional fields are removed. θ0 "auto" resolves to
the auto floor angle of the radius. Trim "stack" writes `cabin.trim_stack` from the stack fields.
"""
function gui_build_project(base::AbstractDict, values::AbstractDict)
    proj = deepcopy(base)
    specs = gui_input_specs()
    errs = String[]
    parsed = Dict{String,Any}()
    for spec in specs
        try
            parsed[spec.key] = _parse_field(spec, get(values, spec.key, spec.default))
        catch e
            push!(errs, sprint(showerror, e))
        end
    end
    isempty(errs) || error("Input errors:\n" * join(errs, "\n"))
    # θ0: "auto" → the auto floor angle for the radius in use
    th = parsed["theta0_deg"]
    if th === nothing || lowercase(th) == "auto"
        parsed["theta0_deg"] = auto_floor_angle(parsed["a_m"]).theta0_deg
    else
        x = tryparse(Float64, th)
        x === nothing && error("Input errors:\nFloor angle θ0: \"$th\" is not a number or auto")
        parsed["theta0_deg"] = x
    end
    code_default = Dict{String,Any}("theta0_deg" => NASA_DEFAULTS.theta0_deg)
    for spec in specs
        length(spec.path) >= 3 && spec.path[2] == "trim_stack" && continue
        spec.key == "trim" && continue
        new = parsed[spec.key]
        old = _untag(_effective_get(base, spec))
        _same(new, old) && continue
        if new === nothing   # blank optional field: remove it wherever the code would find it
            _path_delete!(proj, spec.path)
            if spec.path[1] == "cabin" && length(spec.path) == 2
                for alt in get(_GUI_ALT_KEYS, spec.path[2], String[])
                    _path_delete!(proj, ["cabin", alt])
                end
            end
            for q in get(_GUI_ALT_PATHS, spec.key, Vector{String}[])
                _path_delete!(proj, q)
            end
            continue
        end
        dflt = get(code_default, spec.key) do
            isempty(spec.default) ? nothing : _parse_field(spec, spec.default)
        end
        old === nothing && _same(new, dflt) && continue
        _path_set!(proj, spec.path, new)
    end
    # Trim
    trim = parsed["trim"]
    old_stack = _path_get(base, ["cabin", "trim_stack"])
    old_trim = _path_get(base, ["cabin", "trim"])
    if trim == "stack"
        stack = Dict{String,Any}()
        old_stack isa AbstractDict && haskey(old_stack, "tag") && (stack["tag"] = old_stack["tag"])
        parsed["trim_insulation_table"] === nothing || (stack["insulation_table"] = parsed["trim_insulation_table"])
        sw = parsed["trim_sidewall"]
        (sw === nothing || isempty(sw)) && error("Input errors:\nStack: sidewall elements: at least one element is needed")
        stack["sidewall"] = Dict{String,Any}("elements" => sw)
        ep = parsed["trim_endplates"]
        ep === nothing || isempty(ep) || (stack["endplates"] = Dict{String,Any}("elements" => ep))
        if parsed["trim_mech"] == true
            stack["mechanical"] = Dict{String,Any}(k => parsed["mech_" * k] for k in ("m_t", "h_t", "c_t", "eta_t", "N_points", "n_lines"))
        end
        cab = get!(proj, "cabin", Dict{String,Any}())
        if old_stack === nothing && _untag(old_trim) isa AbstractDict && _same(stack, old_trim)
            # the loaded stack sat under cabin.trim and is unchanged: the file stays as loaded
        else
            _same(stack, old_stack) || (cab["trim_stack"] = stack)
            delete!(cab, "trim")   # a stack under cabin.trim moves to trim_stack; a plain trim would only mislead
        end
    else
        _path_delete!(proj, ["cabin", "trim_stack"])
        if _untag(old_trim) isa AbstractDict || !_same(trim, _untag(old_trim))
            trim === nothing ? _path_delete!(proj, ["cabin", "trim"]) : _path_set!(proj, ["cabin", "trim"], trim)
        end
    end
    return proj
end

"""Top-level project keys the code does not read (said when a project is opened, so no value is taken as used)."""
const GUI_UNREAD_KEYS = ("grid", "harmonics", "acoustic_analogies", "fuselage.L_m", "fuselage.a_m", "fuselage.theta0_deg",
                         "propeller_placement.r_p_m", "propeller_placement.phi_p_deg", "propeller_placement.z_p_m",
                         "propeller.diameter_m", "propeller.airfoil_polar_files", "operating_point.altitude_m",
                         "operating_point.pitch_deg")

function gui_unread_keys(project::AbstractDict)
    return [k for k in GUI_UNREAD_KEYS if _path_get(project, String.(split(k, '.'))) !== nothing &&
            !(k == "propeller.airfoil_polar_files" && isempty(_path_get(project, ["propeller", "airfoil_polar_files"])))]
end

"""Spec + value JSON the QML builds its tabs from: {"groups": [{"name", "fields": [...]}]}."""
function gui_inputs_json(values::AbstractDict)
    groups = Dict{String,Vector{Any}}()
    order = String[]
    for s in gui_input_specs()
        haskey(groups, s.group) || (push!(order, s.group); groups[s.group] = Any[])
        push!(groups[s.group], Dict("key" => s.key, "label" => s.label, "unit" => s.unit, "kind" => String(s.kind),
                                    "choices" => s.choices, "tip" => s.tip, "value" => get(values, s.key, s.default),
                                    "default" => s.default))
    end
    return JSON3.write(Dict("groups" => [Dict("name" => g, "fields" => groups[g]) for g in order]))
end

"""BPF readout from the Propeller fields (B·rpm/60), or "" when they do not parse."""
function gui_bpf_text(values::AbstractDict)
    B = tryparse(Float64, strip(get(values, "num_blades", "")))
    n = tryparse(Float64, strip(get(values, "rpm", "")))
    (B === nothing || n === nothing) && return ""
    return "BPF = $(round(B * n / 60; digits=2)) Hz"
end

"""
    gui_run_args(base, values) -> (; project, path, kwargs)

Build the project, write it to a temporary file (removed by the caller) and return the `run_pain_pipeline` keywords.
"""
function gui_run_args(base::AbstractDict, values::AbstractDict)
    proj = gui_build_project(base, values)
    st = get!(proj, "settings", Dict{String,Any}())
    st["broadband"] = false                         # Phase 130: GUI runs are tones only (GUI_BROADBAND_SETTINGS)
    run = get(proj, "run", Dict{String,Any}())
    blk = uppercase(String(get(run, "blocking", "R2"))) == "R1" ? R1 : R2
    nH = Int(get(run, "n_harmonics", 5))
    path, io = mktemp()
    write(io, JSON3.write(proj))
    close(io)
    return (; project=proj, path, kwargs=(; source=:aircraft, aircraft_json=path, blocking=blk, n_harmonics=nH))
end
