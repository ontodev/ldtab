# LDTab Data Format for Column Values 

All values in `ldtab` columns are encoded in JSON.  Most of these JSON values can be seen as syntactic variants of expressions in [Turtle Syntax](https://www.w3.org/TR/turtle/). This means it's quite simple to convert an `ldtab` table to Turtle. Note, however, that there is no one-to-one mapping between Turtle and `ldtab` because some values in `ldtab` can be represented in more than one way in Turtle (more formally: the transformation from Turtle to `ldtab` is uniquely determined but there is more than one way of transforming `ldtab` into Turtle.)

Even though we do not allow white space and impose a lexicographical order on JSON values,
the examples shown below do not comply with these restrictions for improved readability.

In the following, we describe `ldtab`'s data format by way of example. Using Turtle's specification as a guide, we provide explanations for `ldtabs`'s design in terms of Turtle's [language features](https://www.w3.org/TR/turtle/#language-features):

- [String Values](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#string-values)
- [Object Lists](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#object-lists)
- [Predicate Lists](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#predicate-lists)
- [Blank Nodes](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#blank-node-structures)
- [RDF Lists](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#rdf-list)

## String Values

String values in the columns of the `statement` table are encoded pretty much as you would in Turtle:

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


## Object Lists

RDF Triples with the same subject and predicate can be encoded more succinctly in Turtle using an [objectList](https://www.w3.org/TR/turtle/#grammar-production-objectList).
For example, the RDF triples


```ttl
pizza:PrawnsTopping rdfs:label "PrawnsTopping"@en
pizza:PrawnsTopping rdfs:label "CoberturaDeCamarao"@pt
```

can be encoded (using a `,`) as 

```ttl
pizza:PrawnsTopping rdfs:label "PrawnsTopping"@en, "CoberturaDeCamarao"@pt
```

Such object lists are *not* supported in `ldtab`. Every RDF triple is encoded via a dedicated row in `ldtab`:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | g1 | pizza:PrawnsTopping  | rdf:label  | PrawnsTopping      | @en | 
1         | 0          | g1 | pizza:PrawnsTopping  | rdf:label | CoberturaDeCamarao    | @pt | 

Note how the literal `"PrawnsTopping"@en` is encoded as a string without enclosing double quotes and with no language tag (see section on [String Values](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#string-values)). The language tag can be found in the `datatype` column as will be explained in more detail in the [section on objects](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#objects).

## Predicate Lists

RDF Triples with the same subject can be encoded more succinctly in Turtle using an [predicateObjectList](https://www.w3.org/TR/turtle/#grammar-production-predicateObjectList).
For example, the RDF triples

```ttl
pizza:AmericanHot rdf:type owl:Class
pizza:AmericanHot rdf:label "AmericanHot"
```

can be encoded (using a `;`) as 

```ttl
pizza:AmericanHot rdf:type owl:Class ;
                  rdf:label "AmericanHot"
```

Such predicate lists are *not* supported in `ldtab`. Every RDF triple is encoded via a dedicated row in `ldtab`:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | g1 | pizza:AmericanPizza  | rdf:type  | owl:Class      | _IRI | 
1         | 0          | g1 | pizza:AmericanPizza  | rdf:label | AmericanHot    | xsd:string | 

Note that the RDF literal `"AmericanHot"` is not enclosed in double quotes in `ldtab` (see section above on [String Values](https://github.com/ontodev/ldtab/tree/draft/spec/data-format#string-values)). The `ldtab` string `AmericanHot` in the second row can be identified as an RDF literal due to its associated value in the `datatype` column, as will be explained next.

## Objects

A Turtle [object](https://www.w3.org/TR/turtle/#grammar-production-object) is one of the following:
- [iri](https://www.w3.org/TR/turtle/#grammar-production-iri),
- [BlankNode](https://www.w3.org/TR/turtle/#grammar-production-BlankNode),
- [collection](https://www.w3.org/TR/turtle/#grammar-production-collection) (RDF list),
- [blankNodePropertyList](https://www.w3.org/TR/turtle/#grammar-production-blankNodePropertyList),
- [literal](https://www.w3.org/TR/turtle/#grammar-production-literal).

In `ldtab`, each such object is associated with a `datatype` in `ldtab`:

- iri: `_IRI`,
- BlankNode: `_IRI`,
- collection: `_JSONLIST`,
- blankNodePropertyList: `_JSONMAP`,
- literal: a [language tag](https://www.w3.org/TR/rdf11-concepts/#dfn-language-tagged-string) or an a [datatype IRI](https://www.w3.org/TR/rdf11-concepts/#dfn-datatype-iri).


Every `object` in `ldtab` is required to have a `datatype` (the column `datatype` is `NOT NULL` in `ldtab`'s schema).
So, [simple literals](https://www.w3.org/TR/rdf11-concepts/#section-Graph-Literal) (also referred to as [plain literals](https://www.w3.org/TR/rdf-plain-literal/)) are not supported by `ldtab`.
A literal without a datatype is serialized with the datatype IRI [xsd:string](http://www.w3.org/2001/XMLSchema#string).

The production rules for Turtle's collection and blankNodePropertyList are cyclic, i.e, collections and blankNodePropertyLists allow for object nesting. Such nested structures in Turtle are represented using nested JSON objects, as will be explained next.


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

A blank node that cannot be transformed into a non-empty JSON object is turned into an IRI.
The IRI is based on a hash of the blank node's associated `ldtab` structure.

Consider for example:

```ttl
[] rdfs:subClassOf [ owl:onProperty pizza:hasBase ;
                     owl:someValuesFrom pizza:PizzaBase ;
                     rdf:type owl:Restriction ]
```
Here, the left-hand side of the `rdfs:subClassOf` is a blank node that would correspond to an empty JSON object. So, we first translate the right-hand side of `rdfs:subClassOf` into an `ldtab` JSON object, compute a hash of this JSON object, and then use this hash to introduce an IRI for the blank node.

<span style="color:red">TODO: we currently don not have a decent strategy for deriving IRIs for blank nodes in general.</span>


## RDF List

We encode RDF lists as JSON arrays similar to [collections](https://www.w3.org/TR/turtle/#grammar-production-collection) in Turtle.

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
