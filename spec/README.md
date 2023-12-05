# Design

The design of `ldtab` is based on tables with the following structure:

- ldtab: metadata
    - key
    - value
- prefix: used to convert between IRIs and CURIEs
    - prefix: the short prefix string
    - base: its expansion
- statement: used to store an RDF graph
    - assertion: an integer indicating when the statement was asserted
    - retraction: an integer indicating when the statement was retracted;
      defaults to 0, which means **no** retraction;
      must be greater than the transaction
    - graph
    - subject
    - predicate
    - object
    - datatype
    - annotation: for RDF reifications and OWL annotations

In the following, we discuss these tables in more detail.

## LDTab Metadata

Metadata typically consist of key–value pairs. Metadata that describe the contents of the RDF graph can me stored in the ldtab table. Such metadata can include the `ldtab` verison, relevant schemas for data validation, etc.

## Prefixes

While any IRI can be wrapped in angle brackets,
it's much easier for people to read prefixed names.
When reading RDFXML `ldtab` uses a `prefix` table from your database,
and tries to convert each IRI it encounters into a prefixes name.

Some warnings:

- Since SQL simply compares strings, not expanded IRIs,
  it's your job to ensure that your prefixes are consistent across your data.
- Turtle prefixed names are a superset of XML QNames and a subset of CURIEs.
  `ldtab`'s prefix handling is currently very primitive.
  Depending on your choices of prefixes and the IRIs in your RDF,
  `ldtab` may generate prefixed names that are not valid in Turtle.

## Statements

If you've worked with RDF before,
most of the columns in the statement tables should be familiar.

The columns `assertion` and `retraction` are used to maintain the edit history of an RDF graph over time. This edit history can be used to create any version of the graph in its edit history. This approach is inspired by [Datomic](https://www.datomic.com/). We will explain how this works in more detail later.

The `graph` column is used for different graphs.

Values in the columns `subject`, `predicate`, `object`, `datatype`, `annotation` are encoded pretty much as you would in Turtle syntax:

- IRIs (URLs) are wrapped in angle brackets: `<http://example.com/foo>`
- prefixed names use a prefix from the `prefix` table: `ex:foo`

This means it's quite simple to convert this table to Turtle format.

Some differences from Turtle syntax:

- literals are multiline strings, without enclosing quotations marks or escaping,
- blank nodes are skolemized using IRIs derived from a Hash of RDF structure it represents,
- instead of [blankNodePropertyLists](https://www.w3.org/TR/turtle/#grammar-production-blankNodePropertyList) `ldtab` uses JSON objects as will be explained next.

## Predicate Maps

A *predicate map* is a JSON object essentially encoding a blankNodePropertyLists in Turtle.
For example, an OWL existential restriciton in Turtle

```ttl
[ rdf:type owl:Restriction ;
  owl:onProperty pizza:hasBase ;
  owl:someValuesFrom pizzaBase
]
```

is encoded in `ldtab` as follows:

```json
{
  "owl:onProperty": [
    {
      "datatype": "_IRI",
      "object": "pizza:hasBase"
    }
  ],
  "owl:someValuesFrom": [
    {
      "datatype": "_IRI",
      "object": "pizza:PizzaBase"
    }
  ],
  "rdf:type": [
    {
      "datatype": "_IRI",
      "object": "owl:Restriction"
    }
  ]
}
```

A [predicateObjectList](https://www.w3.org/TR/turtle/#grammar-production-predicateObjectList) in Turtle is encoded by a JSON array. We use such arrays even if there is only one object.

## Objects

We  encode *RDF objects* using two the columns `object` and `datatype`.
RDF objects fall into three categories indicated by the `datatype` column:

1. IRI: `datatype` is _IRI,
2. Literal: `datatype` is either a language tag or an a datatype IRI,
3. Predicate Map: `datatype` is _JSON

## OWL Annotation Axioms

OWL Annotation Axioms provide a way to make statements about other statements in the RDF graph.
For example, we can add a comment on a label:

```ttl
ex:foo rdfs:label "Foo" .
[ rdf:type owl:Axiom ;
  owl:annotatedSource ex:foo ;
  owl:annotatedProperty ex:label ;
  owl:annotatedTarget "Foo" ;
  rdfs:comment "A silly label"
] .
```

The top-level subject for the OWL Annotation Axiom is a blank node.
However when we query for `ex:foo` we want to get this information as well.
So `ldtab` provides this information in the annotation column:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | graph | ex:foo  | ex:label  | Foo      | xsd:string | {"rdf:comment":[{"object":"A silly label", "datatype":"xsd:string"}],"datatype":"_JSON","meta":"owl:Axiom"}
