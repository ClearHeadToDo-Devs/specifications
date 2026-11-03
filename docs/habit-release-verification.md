# Habit joint release verification — 2026-11-03

## Release candidate, not yet published

- Specification candidate: **v0.5.0**, branch `publish-habits-20261103`.
- Grammar candidate: **tree-sitter-actions v0.11.0**, branch `publish-habits-20261103` in its own repository.
- Approved source: `review/spec-habits-darrion` at `2d812ec`, findings 1–5 applied and approved by Darrion on 2026-11-03.
- Integration: `cb607c4` merges that approval with specification main `e9b0f84`, retaining v0.4.0 individual-close/root-tree-archival semantics. Artifact corrections: `5b705a5`.
- No specification release branch update or release tags have been published. No Core dependency, lockfile, specification declaration or platform gitlinks have moved.

Publication must remain joint. An actual `cargo publish` attempt from grammar candidate `b2b98f9` failed before upload with `error: no token found, please run cargo login` (or use `CARGO_REGISTRY_TOKEN`). The host has no configured crates.io publishing credentials; a publishing credential or authorized publisher is needed before release. The public sparse registry index at `https://index.crates.io/tr/ee/tree-sitter-actions` lists **0.10.0** as its latest version and does **not** list **0.11.0** (checked 2026-11-03). The crates.io API request returned HTTP 403, so availability was checked against the registry index rather than inferred from the API failure.

## Independent review

Reviewer: **Claude Opus 4.6**, different vendor from the GPT steward. Review records are sandbox sessions `20261103-055729/1` and `20261103-060542/1`.

The first review covered every group 6 machine-contract file against approved prose and skimmed group 5. It found artifact corrections, not product-policy questions:

1. Habit SHACL lacked the open-state/closed-date constraint.
2. The conformance check lacked the corresponding negative tests.
3. External schedule/occurrence JSON descriptions did not distinguish transport fields from authoritative native sidecar lineage.
4. The slot regex accepted missing time and trailing garbage.
5. The ontology draft header omitted Decision 57.

Corrections at `5b705a5` enforce closed dates exactly for terminal Habits; test all five states negatively; validate D/F/U slot syntax, seconds, frame suffixes and normalized fractional precision; clarify transport descriptions; and correct the citation. The new negative state test was run red before the SHACL correction, then the full suite passed green. The Habit graph fixture also gained its missing Objective/`app:serves` link so that its mapped CCO graph passes the existing `plan-names-objective` verification rule.

The second Claude review verified the corrections and merge resolution, independently reran the artifact checks, found **no policy changes**, and returned **land as-is**. Its only nonblocking nit: the Habit file-path SHACL pattern does not itself reject backslashes, although ontology rule 3 already forbids them and the Action shape rejects them. No new specification decision is pending from these reviews.

## Gates run on the integrated release candidate

All passed:

| Gate | Evidence |
| --- | --- |
| Habit artifacts | `python examples/conformance/habits/check.py` with `rdflib==7.2.1`, `pyshacl==0.30.1`, `jsonschema==4.25.1`: schema validity, Habit/sidecar JSON, positive/negative SHACL, all Habit states, slot strings, CCO mapping, UUID and cross-zone DST vectors |
| Baseline graph suite | Platform `scripts/check-graph-shapes.py`, unchanged, run against this candidate with `pyshacl==0.40.1`: app/CCO positive graphs, 15 CCO and 19 app negative fixtures, warnings, HermiT consistency, mapping isomorphism and all 16 mapping queries/term accounting |
| Ontology | `make -C ontology test`, ROBOT 1.9.8: fresh merge, HermiT, both verification rules, exact competency answers and report (`No violations found`) |
| Habit mapped graph | Execute all mapping queries over the Habit fixture; validate result with CCO SHACL; merge with ontology and run HermiT plus both existing ROBOT verification rules (zero violations) |
| Grammar regeneration | `CLEARHEAD_SPEC_DIR=<candidate> npm run regen:verify`: no tracked generated expectation drift |
| Full grammar suite | `CLEARHEAD_SPEC_DIR=<candidate> npm run test:all`: exact CST sources, 32 corpus cases, all 7 formatting pairs including Habits, highlight checks and 46 Node tests; no Habit exclusion and no fixture copies |
| Rust grammar | `cargo test` (one passing doctest, no Rust unit tests), `cargo doc` |
| Package contents | `npm pack --dry-run`, `cargo package --list`: parser/bindings/queries, no copied specification corpus |
| Registry package rehearsal | `cargo publish --dry-run --allow-dirty`: tree-sitter-actions 0.11.0 packages 31 files, builds the packaged source successfully, and aborts upload only because this is a dry run |
| Whitespace | `git diff --check` |

The grammar gates were rerun after bumping all four manifests and npm lockfile to 0.11.0. All eight specification JSON schema IDs name v0.5.0.

Host prerequisites were absent, so gate tools were bootstrapped only under `/tmp`: Python virtualenvs, ROBOT 1.9.8, GNU make with its runtime libraries and Topiary 0.7.3. No host package installation or committed tool workaround was introduced.

These are release artifact and grammar checks, **not a claim that Core implements Habits**. Real Core Habit conformance and released-composition `scripts/validate-pinned` belong to `=core-habit-pins` and its implementation successors. The current platform composition remains untouched.

## Resume publication

1. Provide crates.io publishing access securely; do not put a token in source, action descriptions or chat.
2. From the prepared grammar branch, rerun the publishing checklist as needed and `cargo publish`; confirm 0.11.0 in the sparse registry index and download/build the published crate.
3. Fast-forward each repository's `main` to its reviewed candidate; tag specification `v0.5.0` and grammar `v0.11.0`. Fast-forward specification `release` to its release tag and push; verify `clearhead.dev` schema/site availability. Do not update platform gitlinks here.
4. Record actual tags, commit hashes, registry availability and site proof here and in platform `=release-habits`; complete `=release-habits` and `=spec-habits` only then.
5. Queue `=core-habit-pins` against those exact published releases. Leave `=grammar-habits` open until released adoption is complete.
