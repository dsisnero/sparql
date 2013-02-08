require 'rdf' # @see http://rubygems.org/gems/rdf
require 'sparql/algebra'
require 'json'
require 'sxp'

module SPARQL
  ##
  # A SPARQL grammar for RDF.rb.
  #
  # ## Representation
  # The parser natively generates  native SPARQL S-Expressions (SSE),
  # a hierarch of `SPARQL::Algebra::Operator` instances
  # which can be executed against a queryable object, such as a Repository identically
  # to `RDF::Query`.
  # 
  # Other elements within the hierarchy
  # are generated using RDF objects, such as `RDF::URI`, `RDF::Node`, `RDF::Literal`, and `RDF::Query`.
  # 
  # See {SPARQL::Grammar::Parser} for a full listing
  # of algebra operations and RDF objects generated by the parser.
  # 
  # The native SSE representation may be serialized to a textual representation of SSE as
  # serialized general S-Expressions (SXP).
  # The SXP generated closely follows that of [OpenJena ARQ](http://openjena.org/wiki/SSE), which is intended principally for
  # running the SPARQL rules. Additionally, SSE is generated for CONSTRUCT, ASK, DESCRIBE and FROM operators.
  # 
  # SXP is generated by serializing the parser result as follows:
  # 
  #     sse = SPARQL::Grammar.parse("SELECT * WHERE { ?s ?p ?o }")
  #     sxp = sse.to_sxp
  # 
  # The following examples illustrate SPARQL transformations:
  #
  # SPARQL:
  #
  #     SELECT * WHERE { ?a ?b ?c }
  # 
  # SXP:
  #
  #     (bgp (triple ?a ?b ?c))
  # 
  # SPARQL:
  #
  #     SELECT * FROM <a> WHERE { ?a ?b ?c }
  # 
  # SXP:
  #
  #     (dataset (<a>) (bgp (triple ?a ?b ?c)))
  # 
  # SPARQL:
  #
  #     SELECT * FROM NAMED <a> WHERE { ?a ?b ?c }
  # 
  # SXP:
  #
  #     (dataset ((named <a>)) (bgp (triple ?a ?b ?c)))
  # 
  # SPARQL:
  #
  #     SELECT DISTINCT * WHERE {?a ?b ?c}
  # 
  # SXP:
  #
  #     (distinct (bgp (triple ?a ?b ?c)))
  # 
  # SPARQL:
  #
  #     SELECT ?a ?b WHERE {?a ?b ?c}
  # 
  # SXP:
  #
  #     (project (?a ?b) (bgp (triple ?a ?b ?c)))
  # 
  # SPARQL:
  #
  #     CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}
  # 
  # SXP:
  #
  #     (construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c))))
  # 
  # SPARQL:
  #
  #     SELECT * WHERE {<a> <b> <c> OPTIONAL {<d> <e> <f>}}
  # 
  # SXP:
  #
  #     (leftjoin (bgp (triple <a> <b> <c>)) (bgp (triple <d> <e> <f>)))
  # 
  # SPARQL:
  #
  #     SELECT * WHERE {<a> <b> <c> {<d> <e> <f>}}
  # 
  # SXP:
  #
  #     (join (bgp (triple <a> <b> <c>)) (bgp (triple <d> <e> <f>)))
  # 
  # SPARQL:
  #
  #     PREFIX : <http://example/> 
  # 
  #     SELECT * 
  #     { 
  #        { ?s ?p ?o }
  #       UNION
  #        { GRAPH ?g { ?s ?p ?o } }
  #     }
  # 
  # SXP:
  #
  #     (prefix ((: <http://example/>))
  #       (union
  #         (bgp (triple ?s ?p ?o))
  #         (graph ?g
  #           (bgp (triple ?s ?p ?o)))))
  # 
  # ## Implementation Notes
  # The parser is driven through a rules table contained in lib/sparql/grammar/parser/meta.rb. This includes
  # branch rules to indicate productions to be taken based on a current production.
  # 
  # The meta.rb file is generated from etc/sparql-selectors.n3 which is the result of parsing
  # http://www.w3.org/2000/10/swap/grammar/sparql.n3 (along with bnf-token-rules.n3) using cwm using the following command sequence:
  # 
  #     cwm ../grammar/sparql.n3 bnf-token-rules.n3 --think --purge --data > sparql-selectors.n3
  # 
  # sparql-selectors.n3 is itself used to generate lib/sparql/grammar/parser/meta.rb using script/build_meta.
  # 
  # Note that The SWAP version of sparql.n3 is an older version of the grammar with the newest in http://www.w3.org/2001/sw/DataAccess/rq23/parsers/sparql.ttl,
  # which uses the EBNF form. Sparql.n3 file has been updated by hand to be consistent with the etc/sparql.ttl version.
  # A future direction will be to generate rules from etc/sparql.ttl to generate branch tables similar to those
  # expressed in meta.rb, but this requires rules not currently available.
  # 
  # ## Next Steps for Parsing EBNF
  # A more modern approach is to use the EBNF grammar (e.g., etc/sparql.bnf) to generate a Turtle/N3 representation of the grammar, transform
  # this to and LL1 representation and use this to create meta.rb.
  # 
  # Using SWAP utilities, this would seemingly be done as follows:
  # 
  #     python http://www.w3.org/2000/10/swap/grammar/ebnf2turtle.py \
  #       http://www.w3.org/2001/sw/DataAccess/rq23/parsers/sparql.bnf \
  #       en \
  #       'http://www.w3.org/2001/sw/DataAccess/parsers/sparql#' > etc/sparql.ttl
  # 
  #     python http://www.w3.org/2000/10/swap/cwm.py etc/sparql.ttl \
  #       http://www.w3.org/2000/10/swap/grammar/ebnf2bnf.n3 \
  #       http://www.w3.org/2000/10/swap/grammar/first_follow.n3 \
  #       --think --data > etc/sparql-ll1.n3
  # 
  # At this point, a variation of script/build_meta should be able to extract first/follow information to re-create the meta branch tables.
  # 
  # @see http://www.w3.org/TR/rdf-sparql-query/#grammar
  module Grammar
    autoload :Lexer,   'sparql/grammar/lexer'
    autoload :Parser,  'sparql/grammar/parser'
    autoload :Meta,    'sparql/grammar/parser/meta'
    autoload :VERSION, 'sparql/grammar/version'

    METHODS   = %w(SELECT CONSTRUCT DESCRIBE ASK).map(&:to_sym)
    KEYWORDS  = %w(BASE PREFIX LIMIT OFFSET DISTINCT REDUCED
                   ORDER BY ASC DESC FROM NAMED WHERE GRAPH
                   OPTIONAL UNION FILTER).map(&:to_sym).unshift(*METHODS)
    FUNCTIONS = %w(STR LANGMATCHES LANG DATATYPE BOUND sameTerm
                   isIRI isURI isBLANK isLITERAL REGEX).map(&:to_sym)

    # Make all defined non-autoloaded constants immutable:
    constants.each { |name| const_get(name).freeze unless autoload?(name) }

    ##
    # Parse the given SPARQL `query` string.
    #
    # @example
    #   result = SPARQL::Grammar.parse("SELECT * WHERE { ?s ?p ?o }")
    #
    # @param  [IO, StringIO, Lexer, Array, String, #to_s] query
    #   Query may be an array of lexed tokens, a lexer, or a
    #   string or open file.
    # @param  [Hash{Symbol => Object}] options
    # @return [Parser]
    # @raise  [Parser::Error] on invalid input
    def self.parse(query, options = {}, &block)
      Parser.new(query, options).parse
    end

    ##
    # Parses input from the given file name or URL.
    #
    # @param  [String, #to_s] filename
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see `RDF::Reader#initialize` and `RDF::Format.for`)
    # @option options [Symbol] :format (:ntriples)
    # @yield  [reader]
    # @yieldparam  [RDF::Reader] reader
    # @yieldreturn [void] ignored
    # @raise  [RDF::FormatError] if no reader found for the specified format
    def self.open(filename, options = {}, &block)
      RDF::Util::File.open_file(filename, options) do |file|
        self.parse(file, options, &block)
      end
    end

    ##
    # Returns `true` if the given SPARQL `query` string is valid.
    #
    # @example
    #     SPARQL::Grammar.valid?("SELECT ?s WHERE { ?s ?p ?o }")  #=> true
    #     SPARQL::Grammar.valid?("SELECT s WHERE { ?s ?p ?o }")   #=> false
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{Symbol => Object}] options
    # @return [Boolean]
    def self.valid?(query, options = {})
      Parser.new(query, options).valid?
    end

    ##
    # Tokenizes the given SPARQL `query` string.
    #
    # @example
    #     lexer = SPARQL::Grammar.tokenize("SELECT * WHERE { ?s ?p ?o }")
    #     lexer.each_token do |token|
    #       puts token.inspect
    #     end
    #
    # @param  [String, #to_s]          query
    # @param  [Hash{Symbol => Object}] options
    # @yield  [lexer]
    # @yieldparam [Lexer] lexer
    # @return [Lexer]
    # @raise  [Lexer::Error] on invalid input
    def self.tokenize(query, options = {}, &block)
      Lexer.tokenize(query, options, &block)
    end
    
    class SPARQL_GRAMMAR < RDF::Vocabulary("http://www.w3.org/2000/10/swap/grammar/sparql#"); end
  end # Grammar
end # SPARQL
