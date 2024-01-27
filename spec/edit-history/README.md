# Brief Overview

An LDTab database maintains the *edit history* of an OWL ontology or an RDF graph.
An *edit* consists of a set of *added* and *deleted* rows.
Inspired by Datomic, such edits are recorded using *transactions*. 
Transactions are associated with sequential numbers that reflect the order of edits over time.
So, *any version* of an OWL ontology or an RDF graph in its edit history, as maintained by different transactions, can be re-created with an LDTab database.

# Additions & Deletions

A [statements table](https://github.com/ontodev/ldtab/tree/draft/spec/tables#statements) in LDTab contains the column `retraction`. The value for this column is a `0` or a `1`, indicating whether a statement is *added* or *deleted* (retracted), respectively.

# Transactions

A [statements table](https://github.com/ontodev/ldtab/tree/draft/spec/tables#statements) in LDTab contains the column `assertion`. The value for this column is a number indicating a *point* in the edit history. We will refer to distinct numbers in the `assertion` column as a distinct *transactions*.

# Re-creating OWL Ontologies/RDF Graphs

Starting with the smallest transaction in an LDTab database (the smallest number in the `assertion` column),
an OWL Ontology / RDF graph can be-recreated up to a target transaction, i.e., a version in its edit-history, by adding and deleting rows in the sequential order of transactions. 

## Example: Consider the following LDTab database:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | graph | ex:A    | rdfs:subClassOf | ex:D | _IRI | 
1         | 0          | graph | ex:B    | rdfs:subClassOf | ex:D | _IRI | 
1         | 0          | graph | ex:C    | rdfs:subClassOf | ex:D | _IRI | 
2         | 0          | graph | ex:E    | rdfs:subClassOf | ex:D | _IRI | 
2         | 0          | graph | ex:C    | rdfs:subClassOf | ex:E | _IRI | 
2         | 1          | graph | ex:C    | rdfs:subClassOf | ex:D | _IRI | 
3         | 1          | graph | ex:C    | rdfs:subClassOf | ex:E | _IRI | 
3         | 0          | graph | ex:C    | rdfs:subClassOf | ex:D | _IRI | 
3         | 1          | graph | ex:E    | rdfs:subClassOf | ex:D | _IRI | 


Tee database contains three distinct transactions which correspond to the following three ontologies (using LDTab as a serialization format as explained in the next section) : 

Ontology corresponding to transaction `1`:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
1         | 0          | graph | ex:A    | rdfs:subClassOf | ex:D | _IRI | 
1         | 0          | graph | ex:B    | rdfs:subClassOf | ex:D | _IRI | 
1         | 0          | graph | ex:C    | rdfs:subClassOf | ex:D | _IRI | 

Ontology corresponding to transaction `2`:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
2         | 0          | graph | ex:A    | rdfs:subClassOf | ex:D | _IRI | 
2         | 0          | graph | ex:B    | rdfs:subClassOf | ex:D | _IRI | 
2         | 0          | graph | ex:C    | rdfs:subClassOf | ex:E | _IRI | 
2         | 0          | graph | ex:E    | rdfs:subClassOf | ex:D | _IRI | 

Ontology corresponding to transaction `3`:

assertion | retraction | graph | subject | predicate | object   | datatype   | annotation
----------|------------|-------|---------|-----------|----------|------------|------------
3         | 0          | graph | ex:A    | rdfs:subClassOf | ex:D | _IRI | 
3         | 0          | graph | ex:B    | rdfs:subClassOf | ex:D | _IRI | 
3         | 0          | graph | ex:C    | rdfs:subClassOf | ex:D | _IRI | 

Note: the OWL ontologies corresponding to transactions `1` and `3` are the same.
This is a common occurrence in practice when a change is reverted.
In LDTab, such scenarios can be easily identified.


# LDTab as a Serialization Format

In general, an LDTab database is *not* an OWL ontology nor an RDF graph. However, If an LDTab database contains a *single* transaction and all values in the column `retraction` are 0, then the database *can be seen* as an OWL ontology or an RDF graph. So, LDTab can be used as a concrete syntax for OWL and RDF.
