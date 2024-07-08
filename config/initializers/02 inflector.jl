import Inflector

if ! isempty(LinkSUS.Genie.config.inflector_irregulars)
  push!(Inflector.IRREGULAR_NOUNS, LinkSUS.Genie.config.inflector_irregulars...)
end