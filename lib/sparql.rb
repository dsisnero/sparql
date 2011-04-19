##
# A SPARQL for RDF.rb.
#
# @see http://www.w3.org/TR/rdf-sparql-query
module SPARQL
  # @see http://rubygems.org/gems/sparql-algebra
  autoload :Algebra, 'sparql/algebra'
  # @see http://rubygems.org/gems/sparql-grammar
  autoload :Grammar, 'sparql/grammar'
  # @see http://rubygems.org/gems/sparql-client
  autoload :Client,  'sparql/client'
end
