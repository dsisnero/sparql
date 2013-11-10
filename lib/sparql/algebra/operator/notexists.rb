module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `exists` operator.
    #
    # @example
    #    (prefix ((ex: <http://www.example.org/>))
    #      (filter (exists
    #                 (filter (notexists (bgp (triple ?s ?p ex:o2)))
    #                   (bgp (triple ?s ?p ex:o1))))
    #        (bgp (triple ?s ?p ex:o))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-abs
    # @see http://www.w3.org/TR/xpath-functions/#func-abs
    class NotExists < Operator::Unary
      include Evaluatable

      NAME = [:notexists]

      ##
      # Exvaluating this operator executes the query in the first operator passing in each existing bindings.
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @option options[RDF::Queryable] queryable
      #   queryable to execute, using bindings as an initial solution.
      # @return [RDF::Literal::Boolean] `true` or `false`
      def evaluate(bindings, options = {})
        solutions = RDF::Query::Solutions::Enumerator.new {|yielder| yielder << bindings}
        queryable = options[:queryable]
        operand(0).execute(queryable, options.merge(:solutions => solutions)).empty?
      end
    end # NotExists
  end # Operator
end; end # SPARQL::Algebra
