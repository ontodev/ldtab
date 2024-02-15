# Examples

**Work in Progress!** Here are some quick examples of
querying an LDTab table called 'statement'.

## Parents

Get all the parents (direct superclasses) of a class 'ex:foo':

```sql
SELECT object AS parent
FROM statement
WHERE predicate = 'rdfs:subClassOf'
  AND subject = 'ex:foo';
```

## Children

Get all the children (direct subclasses) of a class 'ex:foo':

```sql
SELECT subject AS child
FROM statement
WHERE predicate = 'rdfs:subClassOf'
  AND object = 'ex:foo';
```

## Ancestors

Get all the ancestors (direct and indirect superclasses) of a class 'ex:foo':

```sql
WITH RECURSIVE ancestor(child, ancestor) AS (
  SELECT subject AS child, object AS ancestor
  FROM statement
  WHERE predicate = 'rdfs:subClassOf'
  UNION
  SELECT ancestor.subject, statement.object
  FROM ancestor
  LEFT JOIN statement ON ancestor.ancestor = statement.subject
  WHERE predicate = 'rdfs:subClassOf'
)
SELECT ancestor
FROM ancestor
WHERE subject = 'ex:foo';
```

## Descendants

Get all the descendants (direct and indirect subclasses) of a class 'ex:foo':

```sql
WITH RECURSIVE descendant(subject, descendant) AS (
  SELECT object AS subject, subject AS descendant
  FROM statement
  WHERE predicate = 'rdfs:subClassOf'
  UNION
  SELECT descendant.subject, statement.subject
  FROM descendant
  LEFT JOIN statement ON descendant.descendant = statement.object
  WHERE predicate = 'rdfs:subClassOf'
)
SELECT descendant
FROM descendant
WHERE subject = 'NCBITaxon:51291';
```
