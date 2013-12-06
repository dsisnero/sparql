$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'

describe RDF::Queryable do
  context "#concise_bounded_description" do
    {
      :canonical => [
        %q(
        @prefix dc: <http://purl.org/dc/terms/> .
        @prefix dc11: <http://purl.org/dc/elements/1.1/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        @prefix owl: <http://www.w3.org/2002/07/owl#> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        <http://example.com/aBookCritic> <http://example.com/dislikes> <http://example.com/anotherGreatBook>;
           <http://example.com/likes> <http://example.com/aReallyGreatBook> .
        <http://example.com/john.jpg> dc11:extent "1234";
           dc11:format "image/jpeg";
           a foaf:Image .
        foaf:mbox a rdf:Property,
           owl:InverseFunctionalProperty .
        <http://example.com/anotherGreatBook> dc11:creator "June Doe (june@example.com)";
           dc11:format "application/pdf";
           dc11:language "en";
           dc11:publisher "Examples-R-Us";
           dc11:rights "Copyright (C) 2004 Examples-R-Us. All rights reserved.";
           dc11:title "Another Great Book";
           dc:issued "2004-05-03"^^xsd:date;
           rdfs:seeAlso <http://example.com/aReallyGreatBook> .
        <http://example.com/aReallyGreatBook> dc11:contributor [ a foaf:Person;
             foaf:name "Jane Doe"];
           dc11:creator [ a foaf:Person;
             foaf:img <http://example.com/john.jpg>;
             foaf:mbox "john@example.com";
             foaf:name "John Doe";
             foaf:phone <tel:+1-999-555-1234>];
           dc11:format "application/pdf";
           dc11:language "en";
           dc11:publisher "Examples-R-Us";
           dc11:rights "Copyright (C) 2004 Examples-R-Us. All rights reserved.";
           dc11:title "A Really Great Book";
           dc:issued "2004-01-19"^^xsd:date;
           rdfs:seeAlso <http://example.com/anotherGreatBook> .
         [ rdf:object "image/jpeg";
            rdf:predicate dc11:format;
            rdf:subject foaf:Image;
            a rdf:Statement;
            rdfs:isDefinedBy <http://example.com/image-formats.rdf>] .
         [ rdf:object "application/pdf";
            rdf:predicate dc11:format;
            rdf:subject <http://example.com/aReallyGreatBook>;
            a rdf:Statement;
            rdfs:isDefinedBy <http://example.com/book-formats.rdf>] .
        ),

        %q(
        @prefix dc: <http://purl.org/dc/terms/> .
        @prefix dc11: <http://purl.org/dc/elements/1.1/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        <http://example.com/aReallyGreatBook> dc11:contributor [ a foaf:Person;
             foaf:name "Jane Doe"];
           dc11:creator [ a foaf:Person;
             foaf:img <http://example.com/john.jpg>;
             foaf:mbox "john@example.com";
             foaf:name "John Doe";
             foaf:phone <tel:+1-999-555-1234>];
           dc11:format "application/pdf";
           dc11:language "en";
           dc11:publisher "Examples-R-Us";
           dc11:rights "Copyright (C) 2004 Examples-R-Us. All rights reserved.";
           dc11:title "A Really Great Book";
           dc:issued "2004-01-19"^^xsd:date;
           rdfs:seeAlso <http://example.com/anotherGreatBook> .
         [ rdf:object "application/pdf";
            rdf:predicate dc11:format;
            rdf:subject <http://example.com/aReallyGreatBook>;
            a rdf:Statement;
            rdfs:isDefinedBy <http://example.com/book-formats.rdf>] .
        )
      ],
    }.each do |test, (input, output)|
      it "creates isomorphic output for #{test}" do
        graph_input = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        graph_output = RDF::Graph.new << RDF::Turtle::Reader.new(output)
        graph_cdb = graph_input.concise_bounded_description(RDF::URI("http://example.com/aReallyGreatBook"))
        expect(graph_cdb).to eq graph_output
      end
    end
  end
end
