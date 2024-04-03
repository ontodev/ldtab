-- Create the "morphology_term" table.
DROP TABLE IF EXISTS morphology_term;
CREATE TABLE morphology_term (
    ontology TEXT,
    id TEXT UNIQUE,
    label TEXT PRIMARY KEY  
);

-- Insert terms and labels from DOID.
-- Start with DOID:4 "disease"
-- then recursively collect 'rdfs:subClassOf' descendants.
WITH RECURSIVE descendant(subject) AS (
    VALUES('DOID:4')
  UNION
    SELECT doid.subject
    FROM descendant
    LEFT JOIN doid ON descendant.subject = doid.object
    WHERE predicate = 'rdfs:subClassOf'
      AND datatype = '_IRI'
)
-- Filter for rows with 'rdfs:label' predicate.
INSERT OR IGNORE INTO morphology_term
SELECT
    'doid' AS ontology,
    subject AS id,
    object AS label
FROM doid
JOIN descendant USING(subject)
WHERE predicate = 'rdfs:label';

-- Insert all terms with labels from MPATH.
INSERT OR IGNORE INTO morphology_term
SELECT
    'mpath' AS ontology,
    subject AS id,
    object AS label
FROM mpath
WHERE predicate = 'rdfs:label';
