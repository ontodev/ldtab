# Tables

The design of `ldtab` is based on three tables with the following structure:

1. `ldtab` table: storing metadata using the 2 columns: `key`, `value`
2. `prefix` table: storing prefixes for CURIEs using the 2 columns: `prefix`, `base`
3. `statement` table: storing an RDF graph using the 8 columns: `assertion`, `retraction`, `graph`, `subject`, `predicate`, `object`, `datatype`, `annotation`.

In the following, we discuss these tables and their contents in more detail.

## LDTab Metadata

Metadata typically consist of key–value pairs.
The `ldtab` table provides two TEXT columns  to store such metadata pairs about an RDF graph.
By default, this metadata includes the used `ldtab` version and the version of an associated JSON schema for validating `ldtab`'s data format.

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
Here, we only provide a high-level description for the table's columns.
For a specification of the column values, please refer to `ldtab`'s [data-format](link).

The columns `assertion` and `retraction` are used to maintain the edit history of an RDF graph over time.
This edit history can be used to create any version of the graph in its edit history.
This approach is inspired by [Datomic](https://www.datomic.com/).
We will specify this mechanism [here](link).

The `graph` column is used to serialize multiple named graphs similar to [TriG](https://www.w3.org/TR/trig/).

The columns `subject`, `predicate`, and `object` are used for triples in an RDF graph.
We encode triples in a way that is somewhat similar to [Turtle syntax](https://www.w3.org/TR/turtle/):

- IRIs are encoded as specified by Turtle: [iri](https://www.w3.org/TR/turtle/#grammar-production-iri),
- we 'collapse' blank node structures similar to [blankNodePropertyList](https://www.w3.org/TR/turtle/#grammar-production-blankNodePropertyList),
- we 'collapse' RDF lists similar to [collection](https://www.w3.org/TR/turtle/#grammar-production-collection).

The column `datatype` is used to specify the `ldtab` type of the value in the `object` column.

The column `annotation` contains OWL axiom annotations or RDF reifications.

We encode all values in `ldtab` colums in JSON as specified by `ldtab`'s [data-format](link).
This is where you can find more details about 'collapsed' blank node structures, `ldtab` types, `annotation` values, etc.

The similarities between RDF graphs serialized in `ldtab` and Turtle syntax allows for simple conversions between the two formats.
