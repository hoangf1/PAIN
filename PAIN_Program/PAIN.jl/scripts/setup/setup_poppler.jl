using Pkg
Pkg.add("Poppler_jll")
using Poppler_jll
println(Poppler_jll.pdftoppm_path)
println(Poppler_jll.pdftotext_path)
