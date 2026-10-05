# Build and test the ontology with ROBOT (https://robot.obolibrary.org).
# Merge and reason run as separate steps: chaining them in one robot call
# reported an inconsistent ontology as fine.

CCO_TAG    := v2.2
CCO_URL    := https://raw.githubusercontent.com/CommonCoreOntology/CommonCoreOntologies/$(CCO_TAG)/src/cco-merged/CommonCoreOntologiesMerged.ttl
CCO_SHA256 := a9453382b25b40781c181d6ba44981f228abb76d90d548846713adba9baadb42

# From IAO we take only the terms we use, with their parents (MIREOT).
IAO_RELEASE := 2026-03-30
IAO_URL     := http://purl.obolibrary.org/obo/iao/$(IAO_RELEASE)/iao.owl
IAO_SHA256  := c27ff2964a2ad8165bc365698b628aae95108411384aa4450e6e1b1e82bf0f41
IAO_TERMS   := IAO_0000007  # action specification
IAO_MODULE  := imports/iao-$(IAO_RELEASE)-module.owl

ROBOT    := robot --catalog catalog-v001.xml
BUILD    := build
EXAMPLES := $(wildcard examples/*.ttl)
QUERIES  := $(wildcard queries/*.rq)
VERIFY   := $(wildcard verify/*.rq)
EXPECTED := queries/expected

.PHONY: test lint answers imports clean

# Always merges fresh: a stale merge is how a gate goes green on deleted data.
# Each competency answer must match its expected CSV, so a query that runs
# but answers wrong (or empty) fails.
test:
	mkdir -p $(BUILD)
	$(ROBOT) merge --input clearhead.ttl $(addprefix --input ,$(EXAMPLES)) --output $(BUILD)/merged.owl
	robot reason --reasoner HermiT --input $(BUILD)/merged.owl --output $(BUILD)/reasoned.owl
	robot verify --input $(BUILD)/merged.owl --queries $(VERIFY) --output-dir $(BUILD)/verify
	robot query --input $(BUILD)/merged.owl $(foreach q,$(QUERIES),--query $(q) $(BUILD)/$(notdir $(q:.rq=.csv)))
	for q in $(QUERIES); do n=$$(basename $$q .rq); diff -u $(EXPECTED)/$$n.csv $(BUILD)/$$n.csv || exit 1; done
	$(MAKE) lint

# The ontology header only: example data has unlabelled helper nodes by design.
lint:
	$(ROBOT) report --input clearhead.ttl --output $(BUILD)/report.tsv

# Accept the current answers as expected, after reading the diff.
answers:
	mkdir -p $(EXPECTED)
	cp $(foreach q,$(QUERIES),$(BUILD)/$(notdir $(q:.rq=.csv))) $(EXPECTED)/

# Re-fetch the pinned releases; fails if the bytes differ from the pins.
imports:
	curl -sSfL $(CCO_URL) -o imports/cco-$(CCO_TAG).ttl
	echo "$(CCO_SHA256)  imports/cco-$(CCO_TAG).ttl" | sha256sum -c -
	mkdir -p $(BUILD)
	curl -sSfL $(IAO_URL) -o $(BUILD)/iao.owl
	echo "$(IAO_SHA256)  $(BUILD)/iao.owl" | sha256sum -c -
	robot extract --method MIREOT --input $(BUILD)/iao.owl \
	    $(foreach t,$(IAO_TERMS),--lower-term http://purl.obolibrary.org/obo/$(t)) --annotate-with-source true \
	    --output-iri https://clearhead.us/vocab/clearhead/imports/iao --output $(IAO_MODULE)

clean:
	rm -rf $(BUILD)
