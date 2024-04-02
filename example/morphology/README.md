# Morphology Example

This example demonstrates how LDTab can be used to:

1. convert OWL ontologies to SQL tables
2. use those to build a table of allowed ontology terms
3. use the allowed terms as a foreign key constraint on valid data
4. build a new LDTab table from existing ontologies
5. convert the new LDTab table to a Turtle or OWL file

This kind of "mapping" workflow is a common curation task
when developing application ontologies for validating scientific data.
In this case, we are mapping "morphology" terms from a toxicology database
to ontology terms from
the [Human Disease Ontology (DOID)](https://disease-ontology.org)
and the [Mouse Pathology Ontology (MPATH)](http://obofoundry.org/ontology/mpath.html).

This example creates a single `build/morphology.db` SQLite database file
that you can build with `make all`
and browse to see how everything works.
The code is the `Makefile` and `src/` directory.

Our [Nanobot](https://github.com/ontodev/nanobot.rs) tool
is designed to provide a web interface for tasks like this one,
including table validation, interactive forms, and ontology browsers.

## 1. Convert Ontologies

The first step is to fetch the OWL files for DOID and MPATH.
We use [ROBOT](http://robot.obolibrary.org)
to handle details of merging ontology imports.
We use the Clojure implementation of LDTab
([ldtab.clj](https://github.com/ontodev/ldtab.clj))
to convert the OWL files into LDTab tables in the SQLite database.
This also requires prefix declarations from the [src/prefix.tsv](src/prefix.tsv) file.

## 2. Collect Allowed Ontology Terms

We are going to constrain the "ontology_id" column of the "morphology" table
to only include terms that we consider "morphologies".
This will include all the terms in MPATH,
only the descendants of DOID:4 'disease' from DOID.
The [src/morphology_term.sql](src/morphology_term.sql) file
contains a SQL query that defines the "morphology_term" table with
"ontology", "id", and "label" columns,
then uses a recursive SQL query to insert rows
for DOID:4 and all its descendants,
and finally insert rows for all terms in MPATH.
If our example was more complex,
requiring different constraints on additional columns,
then we could define more tables like this one to suit each distinct constraint.


## 3. Use Allowed Terms

The [src/morphology.tsv](src/morphology.tsv) table
is a simple example of a common mapping task.
In the "term" column we have the local terminology used in our project.
In the "ontology_id" column we "map" that local term
to a community standard ontology ID.
The [src/morphology.sql](src/morphology.sql)
puts a foreign key constraint on the "ontology_id" column,
saying that the values in the column
must come from the "id" column of the "morphology_term" table
that we defined above.
So the "ontology_id" column of the "morphology" table
must contain an MPATH term ID
or a DOID term ID that is DOID:4 or one of its descendants.

Tools such as Nanobot can use this foreign key constraint
to present the user with autocomplete suggestions.

## 4. Build an LDTab Table

We can use the "ontology_id" column of the "morphology" table
to build a new ontology with just that subset of terms and their ancestors.
The [src/morphology_tree.sql](src/morphology_tree.sql) file
contains a query that starts with the DOID and MPATH terms in "morphology"
and recursively selects their 'rdfs:subClassOf' ancestors,
then copies all the relevant rows from the LDTab tables for DOID and MPATH
into a new "morphology_tree" LDTab table.
This is a simple but effective way to "extract" terms from source ontologies.

In this case we exclude rows with '_JSON' datatypes,
which usually contain OWL logical expressions.
A more thorough method would extract the signatures from these OWL expressions,
and also extract those terms.

## 5. Convert to Turtle and OWL

Finally, we use `ldtab.clj` to convert the "morphology_tree" table to Turtle format,
and use ROBOT to convert Turtle to RDF/OWL format.
This shows how LDTab can be used to import RDF/OWL,
use the content in various SQL queries,
and finally export a new LDTab table to standard formats.
