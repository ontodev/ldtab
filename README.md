# ldtab: Linked Data Tables

`ldtab` reads RDF graph and generates a `statements` table like this:

assertion | retraction | graph | subject     | predicate       | object   | datatype | annotation
----------|------------|-------|-------------|-----------------|----------|----------|------------
1         | 0          | graph | pizza:Pizza | skos:prefLabel  | Pizza    | @en	     | 
1         | 0          | graph | pizza:Pizza | rdfs:seeAlso    | <https://en.wikipedia.org/wiki/Pizza> | _IRI	|
1         | 0          | graph | pizza:Pizza | rdfs:label      | Pizza | @en	|
1         | 0          | graph | pizza:Pizza | rdfs:subClassOf | {"owl:onProperty":[{"datatype":"_IRI","object":"pizza:hasBase"}],"owl:someValuesFrom":[{"datatype":"_IRI","object":"pizza:PizzaBase"}],"rdf:type":[{"datatype":"_IRI","object":"owl:Restriction"}]} | _JSON	 | 
1         | 0          | graph | pizza:Pizza | rdfs:subClassOf | pizza:Food | _IRI	|
1         | 0          | graph | pizza:Pizza | rdf:type        | owl:Class | _IRI |


The design of `ldtab` is still in development. 
A prototype implementation is available in Clojure: [ldtab.clj](https://github.com/ontodev/ldtab.clj).
This implementation uses Jena to parse input RDF graphs and supports SQLite and PostgreSQL databases.

## Motivation

The motivation for `ldtab` is threefold:

1. facilitate work with *large RDF graphs*,
2. *simplify SPARQL queries* for complex RDF structures involving blank nodes,
3. enable text-based *diffs* between different versions of an RDF graph.

The following provides more details and examples for each of these goals. 

### 1. Querying large RDF Graphs 

RDF data consists of subject-predicate-object triples that form a graph.
With SPARQL we can perform queries over that graph.
However, loading a large RDF graph into a triplestore for SPARQL can be slow and require a lot of memory (similar issues exist with tools for OWL ontologies).

Yet, in many cases the queries we want to run are actually quite simple.
We often just want all the triples associated with a set of terms,
or all the subjects that match a given predicate and object.
In these cases, SQLite is both efficient and effective.
Consider the following examples:

<table>
  <tr>
    <th>Task</th>
    <th>SQL</th>
    <th>SPARQL</th>
  </tr>

  <tr>
    <td>Get subjects with labels</td>
    <td>
      <pre lang="sql">SELECT subject, value AS label
FROM statements
WHERE predicate = "rdfs:label";</pre>
    </td>
    <td>
      <pre lang="sparql">SELECT ?subject, ?label
WHERE {
  ?subject rdfs:label ?label .
}</pre>
    </td>
  </tr>

  <tr>
    <td>Get OWL classes with labels</td>
    <td>
      <pre lang="sql">SELECT s1.subject, s2.value AS label
FROM statements s1
JOIN statements s2 ON s2.subject = s1.subject
WHERE s1.predicate = "rdf:type"
  AND s1.object = "owl:Class"
  AND s2.predicate = "rdfs:label";</pre>
    </td>
    <td>
      <pre lang="sparql">SELECT ?subject, ?label
WHERE {
  ?subject
    rdf:type owl:Class ;
    rdfs:label ?label .
}</pre>
    </td>
  </tr>
</table>

### 2. Simplify Complex Queries 

Querying RDF data for an entity can be annoying and error-prone
if the entities representation involves complex structures, such as compound OWL class expressions or OWL annotation axioms.
In `ldtab`, such queries can be constructed in a straightforward manner:

<table>
  <tr>
    <th>Task</th>
    <th>SQL</th>
    <th>SPARQL</th>
  </tr>

  <tr>
    <td>Get all relevant RDF triples for a subject (including nested anonymous structures such as OWL class expressions)</td>
    <td>
      <pre lang="sql">SELECT *
FROM statements
WHERE subject = "pizza:Pizza";</pre>
    </td>
    <td>
    Annoying...
    </td>
  </tr>
</table>

### 3. Text-based Diffs between RDF Graphs

An RDF graph can be serialized in many equivalent ways using one concrete syntax.
Existing tools rarely serialize the same graph in a deterministic way.
This makes tracking changes in RDF graphs (or OWL ontologies) using popular version control systems, e.g., git, challenging.
`ldtab` provides support to serialize an RDF graph in a uniquely determined manner, enabling text-based diffs in version control systems.
