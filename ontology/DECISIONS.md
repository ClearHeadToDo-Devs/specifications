# Ontology decisions

Decisions about the ontology's meaning (the former `ontology` repository's log, folded in with Decision 50). Decisions that span repositories live in the platform's `docs/DECISIONS.md`. Each entry states the choice, the alternatives rejected, and the trade-off accepted. The domain they shape, and its standard terms, is in [domain.md](domain.md).

---

## Decision 6: Values and Recurrence Need No Terms of Their Own

Decided 2026-10-01 by the orchestrator, from the human's standard-terms principle (Decision 1). A **value** is a disposition in the person (BCIO personal value, BCIO_006063), like a habit, and a values statement is an information entity that `is about` it. **Recurrence** is not an ontology entity: a recurring action prescribes many acts instead of one (CCO's Plan prescribes "some set of intended acts"), a rate-like recurrence prescribes a CCO Frequency, and the calendar rule saying which intervals is iCal RRULE (RFC 5545), owned by the specification.

**Alternatives rejected:** a ClearHead Values Statement class; a recurrence class (no BFO-family ontology has one, and iCal is already the standard for the rule).

**Trade-off accepted:** recurring work is only fully understood with the specification's iCal mapping beside the ontology.

## Decision 5: Objectives Have State, Confirmed by an Agent

Decided 2026-10-01 by the human. An objective has its own state, as plans and actions do, and none is derived from another. Whether an objective is achieved is confirmed by an agent and recorded as the objective's state: a Nominal Measurement ICE that `is a nominal measurement of` the objective, the same pattern as a cancelled action (Decision 4). Where an objective has a real measure ("on-time completion over 90% across three months"), the measurement is evidence the agent can confirm from; most objectives have none, and the agent's confirmation is all there is.

**Alternatives rejected:** requiring measurable (SMART) objectives; deriving achievement from the state of the objective's plans.

**Trade-off accepted:** the system never decides an objective is achieved on its own; someone has to say so.

## Decision 4: Cancelled Is a State; Deleted Is Absence

Decided 2026-09-30 by the human. A dropped action is **cancelled**: "we are no longer doing this", kept in the data with that state. A **deleted** action is out of the dataset entirely and leaves no record.

There are two kinds of state, measuring different things. **Commitment** states (cancelled) classify the action itself: a Nominal Measurement ICE that `is a nominal measurement of` the action, since no act exists to measure. **Progress** states (in progress, completed) are Event Status measurements of the act the action prescribes. Not started is the absence of either. The reason an action was cancelled is a Descriptive ICE that `is about` the cancellation; it cannot be a part of it, because CCO infers a descriptive whole with a descriptive part to be a Performance Specification.

**Alternatives rejected:** cancelled as an Event Status (there is no act for it to measure); a separate decision record as the only trace of cancelling (the human treats cancelled as a state).

**Trade-off accepted:** a state shown to the user is derived from two kinds of record rather than read from one field.

## Decision 3: An AI Agent Is the Machine Running It

Decided 2026-09-30. An AI agent is a cco:Agent: the running machine, bearing an Agent Capability. The model is part of it in two senses: the copy of the weights in memory is a material part of the machine, and the model's content is information the machine concretizes and acts on, as a person concretizes a plan.

**Alternatives rejected:** treating the model or the software as the agent (an Agent is a material entity in CCO; software is information); a ClearHead-specific agent class.

**Trade-off accepted:** "the agent" in records means a machine running a harness and model, so two runs of the same model on different machines are different agents.

## Decision 2: Objectives, Plans and Actions

Decided 2026-09-30, from the human's competency questions.

- An **objective** is a cco:Objective: a state someone wants, achieved once or maintained.
- A **plan** is a cco:Plan and names its objective as a part. Without an objective it is not a plan; without actions it is a plan still being drafted. An **area of focus** is a plan whose objective is maintained ("keep food in the house").
- An **action** is an IAO action specification (IAO_0000007): information prescribing one act, never the act itself. Every action is part of a plan, directly or through other actions, even where no file names that plan: the specification's workspace layout guarantees every workspace exactly one root charter, whose `next.actions` holds any action not filed elsewhere. An action with an objective of its own and actions of its own is also a plan, by the definition above; an action without one is only an action specification.
- **Waiting, context and energy** are CCO Performance Specifications: an action prescribed given a condition, with a descriptive part that `describes` the condition (CCO's own `describes condition` pattern). IAO's conditional specification was tried first; the reasoner classified every one as a Performance Specification, so CCO's term is used.
- **What happened** is never stored on a plan or action: acts are reached only through records about them (status, outcome, who acted).

**Alternatives rejected:** a ClearHead `Step` class (IAO already has action specification); every action a cco:Plan (most actions have no objective of their own); actions outside any plan (the root charter always contains them); areas of focus as roles holding objective-less actions ("errands" turned out to be a GTD context, not a container); a `waits on` relation of our own, and IAO's conditional specification (both replaced by Performance Specifications without changing any competency answer).

**Trade-off accepted:** each wait costs a Performance Specification and a condition description instead of one edge; the file formats keep their compact syntax and the spec maps it to this structure.

## Decision 1: Standard Terms Only, Tested With ROBOT

Decided 2026-09-30. This repository holds meaning, built from existing BFO-family terms: CCO v2.2 as is, plus IAO terms CCO lacks, pulled in as pinned MIREOT modules. A term of our own is minted only when a search of CCO, IAO and OBO finds nothing, and nothing is ever asserted about another ontology's terms; constraints we want on them are `robot verify` checks over data. ROBOT is the only test tool: reason over the ontology plus examples, verify must-never-happen queries, and answer the competency questions with `robot query`.

**Alternatives rejected:** a ClearHead vocabulary that re-describes CCO terms in place (v4 annotated cco:Plan as "a recurrence prescription", and its examples were inconsistent under a reasoner without any check noticing); importing all of IAO (two full information hierarchies for two terms); Python tests with pyshacl (they check shape, not meaning).

**Trade-off accepted:** IAO's terms sit beside CCO's under BFO rather than inside CCO's information hierarchy, so queries over "all CCO information entities" must also ask for them.
