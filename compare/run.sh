#!/bin/sh

DATE="$(date +'%Y-%m-%dT%H:%M:%S')"
ROOT="$(pwd)"
BIN="${ROOT}/bin"
REPORT="${ROOT}/build/report-${DATE}.txt"
ROBOT="java -jar ${BIN}/robot.jar"
RDFTAB="${BIN}/rdftab"
LDTAB1="java -jar ${BIN}/ldtab-1.jar"
LDTAB2="java -jar ${BIN}/ldtab-2.jar"
WIRING="java -jar ${BIN}/wiring.jar"

# Compare RDFTab and three flavours of LDTab.

fail() {
  echo "ERROR:" "$@"
  exit 1
}

mkdir -p bin/ build/ || fail "Could not create bin/ and build/"

### Fetch or build binaries

# Get ROBOT release
if [ ! -f bin/robot.jar ]; then
  echo "Downloading ROBOT"
  curl -L -o bin/robot.jar \
    "https://github.com/ontodev/robot/releases/download/v1.9.5/robot.jar" \
    || fail "Could not fetch robot release"
fi

# Get RDFTab
if [ ! -f bin/rdftab ]; then
  if [ "$(uname)" = "Darwin" ]; then
    echo "Downloading RDFTab for macOS"
    curl -L -o bin/rdftab "https://github.com/ontodev/rdftab.rs/releases/download/v0.1.1/rdftab-x86_64-apple-darwin" \
      || fail "Could not fetch rdftab"
  else
    echo "Downloading RDFTab for Linux"
    curl -L -o bin/rdftab "https://github.com/ontodev/rdftab.rs/releases/download/v0.1.1/rdftab-x86_64-unknown-linux-musl" \
      || fail "Could not fetch rdftab"
  fi
  chmod +x bin/rdftab || fail "Could not chmod rdftab"
fi

# Get LDTab release
if [ ! -f bin/ldtab-1.jar ]; then
  echo "Downloading LDTab release"
  curl -L -o bin/ldtab-1.jar \
    "https://github.com/ontodev/ldtab.clj/releases/download/v2023-12-21/ldtab.jar" \
    || fail "Could not fetch ldtab release"
fi

# Build LDTab from 'rdf-lists' branch
if [ ! -f bin/ldtab-2.jar ]; then
  echo "Building LDTab rdf-lists"
  cd build/ || fail "Could not cd to build/"
  if [ ! -d ldtab.clj ]; then
    git clone https://github.com/ontodev/ldtab.clj.git \
      || fail "Could not git clone ldtab.clj"
  fi
  cd ldtab.clj || fail "Could not enter ldtab.clj working copy"
  git checkout rdf-lists || fail "Could not checkout rdf-lists branch"
  lein uberjar || fail "Could not build ldtab for rdf-lists"
  cp target/uberjar/ldtab-0.1.0-SNAPSHOT-standalone.jar ../../bin/ldtab-2.jar \
    || fail "Could not copy ldtab-2.jar"
  cd ../..
fi

# Build Wiring from '_JSONOWL' branch
if [ ! -f bin/wiring.jar ]; then
  echo "Building Wiring for JSONOWL"
  cd build/ || fail "Could not cd to build/"
  if [ ! -d wiring.clj ]; then
    git clone https://github.com/ontodev/wiring.clj.git \
      || fail "Could not git clone wiring.clj"
  fi
  cd wiring.clj || fail "Could not enter wiring.clj.clj working copy"
  git checkout _JSONOWL || fail "Could not checkout JSONOWL branch"
  lein uberjar || fail "Could not build wiring for JSONOWL"
  cp target/uberjar/wiring-0.1.0-SNAPSHOT-standalone.jar ../../bin/wiring.jar \
    || fail "Could not copy ldtab-2.jar"
  cd ../..
fi

### Define Database Functions

rdftab() {
  DB="$1"
  OWL="$2"
  sqlite3 "${DB}" \
    "CREATE TABLE prefix (prefix TEXT, base TEXT)" \
    ".mode tabs" \
    ".import --skip 1 ${ROOT}/src/prefix.tsv prefix" \
    || fail "Could not set up prefixes for ${DB}"
  ${RDFTAB} "${DB}" < "${OWL}" \
    || fail "Could not load ${OWL} into ${DB}"
}

ldtab1() {
  DB="$1"
  OWL="$2"
  ${LDTAB1} init "${DB}" || fail "Could not init ${DB}"
  ${LDTAB1} prefix "${DB}" "${ROOT}/src/prefix.tsv" \
    || fail "Could not set up prefixes for ${DB}"
  ${LDTAB1} import "${DB}" "${OWL}" \
    || fail "Could not load ${OWL} into ${DB}"
  rm -f ldtab-1.tsv
  ${LDTAB1} export "${DB}" ldtab-1.tsv \
    || fail "Could not export from ${DB}"
}

ldtab2() {
  DB="$1"
  OWL="$2"
  ${LDTAB2} init "${DB}" || fail "Could not init ${DB}"
  # This is a hack!
  sqlite3 "${DB}" "DROP TABLE statement"
  sqlite3 "${DB}" "CREATE TABLE statement (assertion INT, retraction INT, graph TEXT, subject TEXT, predicate TEXT, object TEXT, datatype TEXT, annotation TEXT)"
  ${LDTAB2} prefix "${DB}" "${ROOT}/src/prefix.tsv" \
    || fail "Could not set up prefixes for ${DB}"
  ${LDTAB2} import "${DB}" "${OWL}" \
    || fail "Could not load ${OWL} into ${DB}"
  rm -f ldtab-2.tsv
  ${LDTAB2} export "${DB}" ldtab-2.tsv \
    || fail "Could not export from ${DB}"
}

index_rdftab() {
  DB="$1"
  sqlite3 "${DB}" "CREATE INDEX IF NOT EXISTS idx_statements_subject ON statements(subject)"
  sqlite3 "${DB}" "CREATE INDEX IF NOT EXISTS idx_statements_predicate ON statements(predicate)"
  sqlite3 "${DB}" "CREATE INDEX IF NOT EXISTS idx_statements_object ON statements(object)"
  sqlite3 "${DB}" "CREATE INDEX IF NOT EXISTS idx_statements_value ON statements(value)"
  sqlite3 "${DB}" "ANALYZE statements"
}

index_ldtab() {
  DB="$1"
  sqlite3 "${DB}" "CREATE INDEX IF NOT EXISTS idx_statement_subject ON statement(subject)"
  sqlite3 "${DB}" "CREATE INDEX IF NOT EXISTS idx_statement_predicate ON statement(predicate)"
  sqlite3 "${DB}" "CREATE INDEX IF NOT EXISTS idx_statement_object ON statement(object)"
  sqlite3 "${DB}" "ANALYZE statement"
}


### Define Ontology Build Function

build_databases() {
  ONT="$1"
  OWL="${ONT}.owl"
  DIR="build/${ONT}"
  URL="http://purl.obolibrary.org/obo/${ONT}.owl"

  cd "${ROOT}" || fail "Could not cd to ${ROOT}"
  mkdir -p "${DIR}" || fail "Could not create ${DIR}"
  cd "${DIR}" || fail "Could not cd to ${DIR}"

  if [ ! -f "${OWL}" ]; then
    ${ROBOT} merge \
      --collapse-import-closure \
      --input-iri "${URL}" \
      --output "${OWL}" \
      || fail "Could not fetch ${OWL}"
  fi

  echo "Building databases for '${ONT}':" >> "${REPORT}"

  echo "1. RDFTab" >> "${REPORT}"
  DB=rdftab.db
  if [ ! -f "${DB}" ]; then
    rdftab "${DB}" "${OWL}" >> "${REPORT}"
  fi

  echo "2. LDTab with JSON predicate maps" >> "${REPORT}"
  DB=ldtab-1.db
  if [ ! -f "${DB}" ]; then
    ldtab1 "${DB}" "${OWL}" >> "${REPORT}"
  fi

  echo "3. LDTab with JSON lists" >> "${REPORT}"
  DB=ldtab-2.db
  if [ ! -f "${DB}" ]; then
    ldtab2 "${DB}" "${OWL}" >> "${REPORT}"
  fi

  echo "2. LDTab with JSON OWL" >> "${REPORT}"
  DB=ldtab-3.db
  if [ ! -f "${DB}" ]; then
    cp ldtab-1.db "${DB}" || fail "Could not copy ldtab-1.db to ${DB}"
    ${WIRING} "${DB}" || fail "Could not convert ldtab-1.db to ${DB}"
    sqlite3 "${DB}" "VACUUM"
  fi

  {
    echo
    echo "Database sizes before indexing:"
    ls -lahS ./*.db
  } >> "${REPORT}"

  index_rdftab rdftab.db
  index_ldtab ldtab-1.db
  index_ldtab ldtab-2.db
  index_ldtab ldtab-3.db

  {
    echo
    echo "Database sizes after indexing:"
    ls -lahS ./*.db
    echo
  } >> "${REPORT}"

  cd "${ROOT}" || fail "Could not cd to ${ROOT}"
}

### Test on Ontologies

build_databases obi
build_databases uberon

cat "${REPORT}"
