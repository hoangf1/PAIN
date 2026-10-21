"""
Validation record template from docs/VALIDATION_GUIDELINE.md §6.
"""
struct ValidationRecord
    block::String
    class::String   # V-EXP | V-CODE | V-UNIT | V-ASSUMED | X-EXTRAP
    reference::String
    metric::String
    tolerance::String
    result::String  # PASS | FAIL | N/A
    notes::String
end

function write_validation_record(io::IO, r::ValidationRecord)
    println(io, "block: ", r.block)
    println(io, "class: ", r.class)
    println(io, "reference: ", r.reference)
    println(io, "metric: ", r.metric)
    println(io, "tolerance: ", r.tolerance)
    println(io, "result: ", r.result)
    println(io, "notes: ", r.notes)
    println(io)
end

function write_validation_record(path::AbstractString, records::Vector{ValidationRecord})
    open(path, "w") do io
        println(io, "# PAIN validation report")
        println(io)
        for r in records
            write_validation_record(io, r)
        end
    end
end
