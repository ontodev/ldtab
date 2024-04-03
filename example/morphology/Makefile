# Morphology Example
# James A. Overton <james@overton.ca>
#
# Shows how LDTab can be used for ontology term mapping.


### Configuration
#
# These are standard options to make Make sane:
# <http://clarkgrubb.com/makefile-style-guide#toc2>

MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:
.PRECIOUS:
.SUFFIXES:

export PATH := $(shell pwd)/bin:$(PATH)

DB := build/morphology.db

### Main Tasks
#
# The main tasks for running Arborist.

.PHONY: help
help:
	@echo "Morphology Example"
	@echo ""
	@echo "TASKS"
	@echo "  fetch       fetch OWL files"
	@echo "  morphology  build morphology example"
	@echo "  all         build all files"
	@echo "  clean       remove all build files"
	@echo "  clobber     remove all generated files"
	@echo "  help        print this message"

.PHONY: fetch
fetch: build/doid.owl build/mpath.owl

.PHONY: morphology
morphology: build/morphology_tree.owl

.PHONY: all
all: morphology

.PHONY: clean
clean:
	rm -rf build/

.PHONY: clobber
clobber:
	rm -rf bin/ build/

bin/ build/:
	mkdir -p $@


### Install Dependencies

# Require SQLite
ifeq ($(shell command -v sqlite3),)
$(error 'Please install SQLite 3')
endif

# Require Java
ifeq ($(shell command -v java),)
$(error 'Please install Java, so we can run ROBOT and LDTab')
endif

# Install ROBOT
bin/robot.jar: | bin/
	curl -L -o $@ 'https://github.com/ontodev/robot/releases/download/v1.9.5/robot.jar'

bin/robot: bin/robot.jar
	curl -L -o $@ 'https://raw.githubusercontent.com/ontodev/robot/master/bin/robot'
	chmod +x $@

# Install LDTab (Clojure implementation)
bin/ldtab.jar: | bin/
	curl -L -o $@ 'https://github.com/ontodev/ldtab.clj/releases/download/v2023-12-21/ldtab.jar'

bin/ldtab: bin/ldtab.jar
	echo '#!/bin/sh' > $@
	echo 'java -jar "$$(dirname $$0)/ldtab.jar" "$$@"' >> $@
	chmod +x $@

### Fetch Ontologies

build/doid.owl: | bin/robot build/
	robot merge \
	--input-iri 'http://purl.obolibrary.org/obo/doid/releases/2024-01-31/doid.owl' \
	--collapse-import-closure true \
	--output $@

build/mpath.owl: | bin/robot build/
	robot merge \
	--input-iri 'http://purl.obolibrary.org/obo/mpath.owl' \
	--collapse-import-closure true \
	--output $@

### Convert Ontologies

$(DB): src/prefix.tsv | bin/ldtab build/
	ldtab init $(DB) --table doid
	ldtab prefix $(DB) $<

build/%.tsv: build/%.owl src/prefix.tsv | $(DB)
	sqlite3 $(DB) 'DROP TABLE IF EXISTS $*'
	rm -f $@
	ldtab init $(DB) --table $*
	ldtab import $(DB) $< --table $*
	sqlite3 $(DB) 'CREATE INDEX idx_$*_subject ON $*(subject)'
	sqlite3 $(DB) 'CREATE INDEX idx_$*_predicate ON $*(predicate)'
	sqlite3 $(DB) 'CREATE INDEX idx_$*_object ON $*(object)'
	sqlite3 $(DB) 'ANALYZE $*'
	ldtab export $(DB) $@ --table $* --format tsv

### Build Tables

build/morphology_term.built: src/morphology_term.sql build/doid.tsv build/mpath.tsv
	sqlite3 $(DB) < $< > $@

build/morphology.built: src/morphology.sql src/morphology.tsv build/morphology_term.built
	sqlite3 $(DB) < $< > $@

build/morphology_tree.built: src/morphology_tree.sql build/morphology.built
	sqlite3 $(DB) 'DROP TABLE IF EXISTS morphology_tree'
	ldtab init $(DB) --table morphology_tree
	sqlite3 $(DB) < $< > $@

### Build OWL Files

build/%.ttl: build/%.built
	rm -f $@
	ldtab export $(DB) $@ --table $* --format ttl

build/morphology_tree.owl: build/morphology_tree.ttl
	robot convert --input $< --output $@
