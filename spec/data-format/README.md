# LDTab Data Format for Column Values 

All values in `ldtab` columns are encoded in JSON.
Even though we do not allow white space and impose a lexicographical order on JSON values,
the examples shown below do not comply with these restrictions for the sake of readability.

## String values

String values in the columns of the `statement` table are encoded pretty much as you would in Turtle syntax:

- IRIs (URLs) follow Turtle's [iri](https://www.w3.org/TR/turtle/#grammar-production-iri):
    - wrapped in angle brackets: `<http://example.com/foo>`
    - prefixed names use a prefix from the `prefix` table: `ex:foo`
- literals are 'raw' strings, meaning
    - no enclosing quotation marks
    - no escaping
    - no language tags
    - no datatype IRIs

Some differences from Turtle syntax:

- literals
    - can be multiline strings
    - booleans 'true' and 'false' are encoded as JSON strings
    - numeric literals are encoded as JSON strings
- blank nodes that do not occur in the position of objects are skolemized (as will explained later)

## Blank Node Structures

We encode [blankNodePropertyLists](https://www.w3.org/TR/turtle/#grammar-production-blankNodePropertyList) in Turtle as a JSON object.
For example, an OWL existential restriction in Turtle

```ttl
[ owl:onProperty pizza:hasBase ;
  owl:someValuesFrom pizza:PizzaBase ;
  rdf:type owl:Restriction
]
```

is encoded in `ldtab` as

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

We refer to such JSON objects as *predicate maps*.

Blank nodes occuring in the subject position of an RDF triple are skolemized using an IRI that is based on a hash of its corresponding `ldtab` row.


## RDF List

We encode RDF lists as JSON arrays similar to [collections](https://www.w3.org/TR/turtle/#grammar-production-collection) in turtle.

For example, the RDF list

```ttl
[ rdf:first "apple";
rdf:rest [ rdf:first "banana";
           rdf:rest rdf:nil ]
]
```

is encoded in `ldtab` as

```json
[
    {
      "datatype": "xsd:string",
      "object": "apple"
    },
    {
      "datatype": "xsd:string",
      "object": "banana"
    }
]
```

## Objects

RDF [objects](https://www.w3.org/TR/turtle/#grammar-production-object) are encoded using the two `ldtab` columns `object` and `datatype`.
The value in the `datatype` column indicates the type of the value in the `object` column as follows:

1. `_IRI`: used for IRIs and CURIEs, 
2. a language tag or an a datatype IRI: used for RDF literals,
3. `_JSONMAP`: used for predicate maps,
4. `_JSONLIST`: used for RDF lists.

Every `object` in `ldtab` is required to have a `datatype`.
So, [simple literals](https://www.w3.org/TR/rdf11-concepts/#section-Graph-Literal) (also referred to as [plain literals](https://www.w3.org/TR/rdf-plain-literal/)) are not supported by `ldtab`.
A literal without a datatype is serialized with the datatype IRI [xsd:string](http://www.w3.org/2001/XMLSchema#string).

The `datatype` of nested RDF objects is encoded with predicate maps (see the above example, e.g., for `owl:Restriction`).


## Predicate lists

A [predicateObjectList](https://www.w3.org/TR/turtle/#grammar-production-predicateObjectList) in Turtle is encoded by a JSON array. We use such arrays even if there is only one object.

For example TODO


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
