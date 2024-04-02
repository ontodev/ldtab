-- Create the "morphology" table.
-- Use the "id" column of the "morphology_term" table
-- as a foreign key constraint on the "ontology_id" column.
DROP TABLE IF EXISTS morphology;
CREATE TABLE morphology (
    term TEXT PRIMARY KEY,
    ontology_id TEXT,
    comment TEXT,
    FOREIGN KEY (ontology_id) REFERENCES morphology_term(id)
);

-- Enforce the foreign key constraint.
PRAGMA foreign_keys = ON;

-- Import data from "src/morphology.tsv".
.mode tabs
.import --skip 1 src/morphology.tsv morphology
