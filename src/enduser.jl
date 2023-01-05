
"""
    open(pkgname; kw...)

Open the browser to an image of `pkgname`'s dependency graph.

The given package must be installed in the currently active project.

See [`PkgGraph.Options`](@ref) for possible keyword arguments.
"""
function open(pkgname; test = false, kw...)
    link = url(pkgname, Options(; kw...))
    if !test
        DefaultApplication.open(link)
    end
    # ↪ Passing a URL (and not a file) opens the browser on all
    #   platforms. (Even though that is undocumented behaviour:
    #   https://github.com/tpapp/DefaultApplication.jl/issues/12)
    return nothing
end

"""
    create(pkgname, dir = tempdir(); fmt = :png, kw...)

Render the dependency graph of the given package as an image in `dir`,
and open it with your default image viewer. Uses the external program
'`dot`' (see [graphviz.org](https://graphviz.org)), which must be
available on `PATH`.

`fmt` is an output file format supported by dot, such as `:svg` or `:png`.

The given package must be installed in the currently active project.

See [`PkgGraph.Options`](@ref) for possible keyword arguments.
"""
function create(pkgname, dir = tempdir(); fmt = :png, test = false, kw...)
    if !is_dot_available() && !test
        error("`dot` program not found on `PATH`. Get it at https://graphviz.org/download/")
    end
    dotstr = to_dot_str(pkgname, Options(; kw...))
    imgpath = output_path(pkgname, dir, fmt)
    if !test
        create_dot_image(dotstr, fmt, imgpath)
        DefaultApplication.open(imgpath)
    end
    return nothing
end
