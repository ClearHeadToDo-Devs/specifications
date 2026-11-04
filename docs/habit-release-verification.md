# Habit joint release verification — 2026-11-03

## Published joint transition

- Specification: **v0.5.0**, released 2026-11-04 from `publish-habits-20261103` to `main` and `release`.
- Grammar: **tree-sitter-actions v0.11.0**, annotated tag at `3139e81333cf917838eee084ad612b6745eae959`, published on crates.io and landed on `main`.
- Approved source: `review/spec-habits-darrion` at `2d812ec`, findings 1–5 applied and approved by Darrion on 2026-11-03.
- Integration: `cb607c4` merges that approval with specification main `e9b0f84`, retaining v0.4.0 individual-close/root-tree-archival semantics. Artifact corrections: `5b705a5`.
- Core dependency, lockfile, specification declaration and platform gitlink adoption are tracked separately by `=core-habit-pins`; this publication does not move them.

The 2026-11-03 local `cargo publish` attempt was blocked by absent credentials. Darrion chose crates.io trusted publishing instead: facilitator commit `3139e81` adds only `.github/workflows/publish.yml` on top of reviewed grammar `b2b98f9`. The `crates-io` environment requires Darrion's approval and accepts only `v*` tags. Darrion approved [Publish run 41770414263](https://github.com/ClearHeadToDo-Devs/tree-sitter-actions/actions/runs/41770414263), which completed successfully.

On 2026-11-04 the steward independently verified **0.11.0** exists and is not yanked in `https://index.crates.io/tr/ee/tree-sitter-actions`, downloaded the public crate from `https://static.crates.io/crates/tree-sitter-actions/tree-sitter-actions-0.11.0.crate`, and verified SHA-256 **`c587f5318244840a87573a7ed6e9c5122349624a9684d0f52ffda8aac36aa236`** matches the index. Published `grammar.js`, `patterns.js`, `src/` and `queries/` match the tagged source file for file. The public packaged Rust tests and doctest pass. No local registry token was needed or stored.

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

## Release procedure and adoption

The release commit moves all eight schema IDs to v0.5.0 and records this verification. Annotated specification tag `v0.5.0` names that commit; `main` and `release` fast-forward to it. Grammar `main` fast-forwards to its existing published `v0.11.0` tag. Schema identity resolves at `https://clearhead.dev/schemas/v0.5.0/actions.schema.json`; the site and vocabulary publish together from `release` (specification README).

Platform `=release-habits` records the exact specification release hash and public site proof after push. `=spec-habits` completes at publication. `=core-habit-pins` then adopts these exact published versions as a separately reviewed cycle; `=grammar-habits` remains open until that adoption is complete.
