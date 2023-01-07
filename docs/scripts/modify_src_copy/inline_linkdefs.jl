"""
Replace "Hello [blah]."

    (or "Hello [text][blah].")

        "[blah]: https://url"

with    "Hello [blah](https://url)."
"""

# Regex for substrings like "[blah]": an opening `[`,
# then anything that's not a closing `]`, and a closing `]`.
# Capture contents in a (group).
bracketed = r"\[([^\]]+)\]"

# "Hello [blah][1] more. \n\n[1]: …"
doublebracket = bracketed * bracketed

linkdef = r": +(http\S+).*\n"
# ↪ `\S`: _not_ a whitespace char
#   Note that this ignores footnotes (eg "[^1]: This is footnote text").

# "[blah]:   http://…   <!-- comment -->  \n"
linkdefline = bracketed * linkdef

singlebracket = bracketed * Regex("(?!$(linkdef.pattern))")
# Negative lookahead (See eg https://stackoverflow.com/a/406408/2611913)
# (A note: in the final regex the `:` does not mean 'non-capturing';
#  but is rather literally the ": " in linkdef strings).

first_couple(md) = begin
    linkdefs = collect(eachmatch(linkdefline, md))
    doublebraks = collect(eachmatch(doublebracket, md))
    singlebraks = collect(eachmatch(singlebracket, md))
    f(m) = !is_in_code_block(md, m)
    filter!(f, doublebraks)
    filter!(f, singlebraks)
    while !isempty(linkdefs)
        ld = popfirst!(linkdefs)
        linkdef_label = ld.captures[1]
        for db in doublebraks
            label = db.captures[2]
            (label == linkdef_label) && return (db, ld)
        end
        for sb in singlebraks
            label = sb.captures[1]
            (label == linkdef_label) && return (sb, ld)
        end
    end
    return nothing
end

function inline_linkdef(md, couple; verbose=true)
    textbrak, linkd = couple
    text = textbrak.captures[1]
    url = linkd.captures[2]
    verbose && println("  Inlining linkdef of [$text]")
    replace_matches(
        md,
        textbrak => "[$text]($url)",
        linkd => "",
    )
end

replace_matches(
    s,
    old_new::Pair{RegexMatch, <:AbstractString}...
) =
    replace_ranges(s, (range_(old)=>new for (old,new) in old_new)...)

range_(m::RegexMatch) = start(m):end_(m)
start(m::RegexMatch) = m.offset
end_(m::RegexMatch) = m.offset + length(m.match) - 1
# ↪ Minus one: "abcd"[2:3] == "bc", of length 2. But 2→3 = +1

function replace_ranges(
    s,
    old_new::Pair{<:AbstractRange, <:AbstractString}...
)
    ranges = collect(first.(old_new))
    substitutions = last.(old_new)
    check_overlap(ranges)
    sort!(ranges)
    parts = []
    i = firstindex(s)
    for (r, subst) in zip(ranges, substitutions)
        before = prevind(s, r.start)
        after = nextind(s, r.stop)
        push!(parts, SubString(s, i:before))
        push!(parts, subst)
        i = after
    end
    push!(parts, SubString(s, i:lastindex(s)))
    join(parts)
end

function check_overlap(ranges)
    @assert allunique(ranges)
    for r1 in ranges, r2 in ranges
        r1 == r2 && continue
        if length(intersect(r1, r2)) > 0
            @error "Ranges $r1 and $r2 overlap"
        end
    end
end

function inline_linkdefs(md; verbose=true)
    while true
        couple = first_couple(md)
        if isnothing(couple)
            return md
        else
            md = inline_linkdef(md, couple; verbose)
        end
    end
end



# --comments--


# What happens when:
# [Text][1]
# [1]: link
# and later in the same file:
# [Blah][1]
# [1]: otherlink
# I.e. reuse of the same label.
# Well the first couple will get replaced first.
# So this'll work.
# What will _not_ work is multiple references to the same link.
# i.e.
# [Text][1] and another [reff][1].
# [1]: …
# The first will get replaced, and then the second
# won't have a match anymore.


# I should rewrite this whole thing:
# gather all `[single brackets]`, `[double][bracktes]`
# and `[linkdefs]: …` first.
# And only then start replacing.


# Broken atm: [[blah]] (to get a `[ ]` wrapped link).
# (I replaced it with {[blah]} now, in bg/related-work, and bg/abbrevs)
