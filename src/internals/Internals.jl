"""
Namespace for the non-end-user functions in PkgGraph.

For ease of experimentation, you can import these with
```
using PkgGraph.Internals
```
They are also imported in the main module, so they
can be accessed as `PkgGraph.depgraph`, e.g.
"""
module Internals

using TOML
using Base: active_project
include("depgraph.jl")
export depgraph,
       packages_in_active_manifest,
       should_be_included,
       is_jll,
       is_in_stdlib,
       STDLIB,
       vertices

include("dot.jl")
export to_dot_str,
       default_style

using EzXML
include("svg.jl")
export add_darkmode

include("local.jl")
export is_dot_available,
       create_dot_image,
       dotcommand,
       output_path

using URIs: escapeuri
include("webapps.jl")
export url,
       webapps

using Base: @kwdef
include("options.jl")
export Options

end