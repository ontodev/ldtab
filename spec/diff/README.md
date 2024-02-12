# LDTab-Diff

`ldtab-diff` is a command-line tool for generating text-based diffs between two RDF graphs or two OWL ontologies.

## Basic Concept

A `diff` in the context of `ldtab` is understood in terms of *added* and *deleted* statements.
Since `ldtab`'s [dataformat](https://github.com/ontodev/ldtab/tree/draft/spec/data-format) represents any RDF graph/OWL ontology in terms of a uniquely determined set of rows in the [statement](https://github.com/ontodev/ldtab/tree/draft/spec/tables#statements) table, a text-based `diff` between two such tables can be generated in a straightforward way by first sorting and then comparing the rows in both tables. 

## Example

Consider the following two OWL ontologies

<table>
  <tr>
    <th>Ontology 1</th>
    <th>Ontology 2</th>
  </tr>
  <tr>
    <td>
     <pre lang="ttl">
     ex:A rdfs:subClassOf [ rdf:type owl:Restriction ;
                            owl:onProperty ex:p ;
                            owl:someValuesFrom ex:B
                          ] .
     ex:B rdfs:subClassOf ex:D .
     ex:C rdfs:subClassOf ex:D .
     </pre>
    </td>
    <td>
     <pre lang="ttl">
     ex:A rdfs:subClassOf [ rdf:type owl:Restriction ;
                            owl:onProperty ex:p ;
                            owl:someValuesFrom ex:B
                          ] .
     ex:B rdfs:subClassOf [ rdf:type owl:Restriction ;
                            owl:onProperty ex:p ;
                            owl:someValuesFrom ex:C
                          ] .
     </pre>
    </td>
  </tr>
<table>

These two ontologies are represented in `ldtab` as follows:

Ontology 1:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | graph | ex:A    | rdfs:subClassOf | {"owl:onProperty":[{"datatype":"_IRI","object":"ex:p"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"ex:B"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]} | _JSONMAP | 
1         | 0          | graph | ex:B    | rdfs:subClassOf | ex:D | _IRI | 
1         | 0          | graph | ex:C    | rdfs:subClassOf | ex:D | _IRI | 

Ontology 2:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | graph | ex:A    | rdfs:subClassOf | {"owl:onProperty":[{"datatype":"_IRI","object":"ex:p"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"ex:B"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]} | _JSONMAP | 
1         | 0          | graph | ex:B    | rdfs:subClassOf | {"owl:onProperty":[{"datatype":"_IRI","object":"ex:p"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"ex:C"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]} | _JSONMAP | 

An `ldtab-diff` between Ontology 1 and Ontology 2 will report the following rows as deleted:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | graph | ex:B    | rdfs:subClassOf | ex:D | _IRI | 
1         | 0          | graph | ex:C    | rdfs:subClassOf | ex:D | _IRI | 

and these as added:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | graph | ex:B    | rdfs:subClassOf | {"owl:onProperty":[{"datatype":"_IRI","object":"ex:p"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"ex:C"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]} | _JSONMAP | 
