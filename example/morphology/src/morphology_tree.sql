-- Import terms from DOID.
-- Starting from the "ontology_id" column of "morphology",
-- recursively select 'rdfs:subClassOf' ancestors from DOID
-- and create a temporary table of subject, ancestor pairs.
WITH RECURSIVE ancestor(subject) AS (
    SELECT ontology_id
    FROM morphology
    WHERE ontology_id LIKE 'DOID:%'
  UNION
    SELECT doid.object
    FROM ancestor
    LEFT JOIN doid ON ancestor.subject = doid.subject
    WHERE predicate = 'rdfs:subClassOf'
      AND datatype = '_IRI'
)
-- Select all rows from the "doid" table
-- where the "subject" is in "ancestor" (above),
-- excluding OWL axioms (which have datatype '_JSON').
INSERT INTO morphology_tree
SELECT *
FROM doid
WHERE subject IN (SELECT subject FROM ancestor)
  AND datatype != '_JSON';

-- Import terms from MPATH.
WITH RECURSIVE ancestor(subject) AS (
    SELECT ontology_id
    FROM morphology
    WHERE ontology_id LIKE 'MPATH:%'
  UNION
    SELECT mpath.object
    FROM ancestor
    LEFT JOIN mpath ON ancestor.subject = mpath.subject
    WHERE predicate = 'rdfs:subClassOf'
      AND datatype = '_IRI'
)
INSERT INTO morphology_tree
SELECT *
FROM mpath
WHERE subject IN (SELECT subject FROM ancestor)
  AND datatype != '_JSON';
