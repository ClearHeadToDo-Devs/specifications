# The ClearHead Domain

What ClearHead's data is about, in plain words, and the standard terms that say it. The choices behind it, with the alternatives rejected, are in [DECISIONS.md](DECISIONS.md). The examples and checks that prove it are in [`v5/`](../v5/).

## Principle

The system holds only information: plans, objectives, and records of what happened. The acts, events and states they are about exist, or fail to, in the world. A plan exists whether or not anyone ever carries it out.

## Competency questions

The model must answer these, from the human's own words. Each is a `robot query` in [`v5/queries/`](../v5/queries/), run by `make -C v5 test` over the examples.

1. What do I need to do to complete my weekly review?
2. Which steps depend on other steps for my objective to come to fruition?
3. Which steps can I do within my current context, energy and priorities?
4. How do I define done for my objectives, and how do I keep track of my plans and their steps?
5. Which plans go toward a given objective?
6. Did we fulfil those plans? If not, why not?
7. What other details does the plan need to succeed?
8. What are the risks, dependencies and supporting materials for this objective?

## The domain

- **Objective**: a state someone wants to be true. Some are *achieved* once (get a degree, file taxes); some are *maintained* and never finish (inbox stays near empty).
- **Plan**: aims at an objective and contains actions. Without an objective it is not a plan; without actions it is a plan still being drafted.
- **Action**: prescribes one thing to do; the word means the prescription, never the doing. Actions contain actions, and every action is part of some plan. Splitting stops when whoever does it can do it without further planning, so the right depth depends on the doer.
- **Conditions**: an action may be prescribed given a condition: what it waits on (another action done, or something outside such as a reply), where or with what it can be done (its *context*), and the energy it calls for.
- **Record**: information that something happened: who acted, when, the outcome, and why it fell short. Status is a record too.
- **Area of focus**: a plan whose objective is maintained ("keep food in the house"). Not a separate kind of thing.
- **Values statement**: what objectives answer to ("live with integrity"). Never achieved, only reviewed.
- **Weekly review**: a recurring plan whose actions review the other plans: judging maintained objectives and values, and finding plans whose actions no longer lead to their objective.

## Distinctions to keep

- **Fulfilling a plan is not achieving its objective.** When every action is done and the objective is not met, either the objective has no clear done-condition or the actions were the wrong ones. Achievement is confirmed by an agent, never derived (Decision 5).
- **Planning done is not work done.** One is the status of the act of planning, the other the status of the planned acts.
- **The doer's situation is not the action's requirement.** Current energy and whereabouts belong to the question being asked; the action states only what it calls for.
- **A plan is sufficient when someone else could carry it out** from what it holds: objective and done-condition, actions, risks, dependencies, materials.
- **Context is a condition, not a container.** "Errands" says where an action can be done; "buy milk" is done in the errands context *for* the plan "keep food in the house". The information a plan carries is its *supporting material*, never its context.
- **A rate is a plan, not an objective.** "Run three times a week" prescribes acts; its objective is a state such as being fit.

## Standard terms

Everything is CCO v2.2 or BFO, plus one IAO term. ClearHead defines no terms of its own (Decision 1). CCO IRIs are opaque, so the label is given beside each; `cco:` is `https://www.commoncoreontologies.org/`, `obo:` is `http://purl.obolibrary.org/obo/`.

| Domain | Term | Pattern |
| --- | --- | --- |
| Objective | Objective `cco:ont00000476` | A maintained objective prescribes a stasis. |
| Plan | Plan `cco:ont00000974` | `has continuant part` (`obo:BFO_0000178`) its objective and its actions. |
| Action | action specification `obo:IAO_0000007` | `has continuant part` its sub-actions. Belonging to a plan is a `robot verify` check, not an axiom. |
| Waiting, context, energy | Performance Specification `cco:ont00000127` | Has as parts the action and a Descriptive ICE (`cco:ont00000853`) that `describes` (`cco:ont00001982`) the condition: an awaited action, a site (`obo:BFO_0000029`) or a quality (`obo:BFO_0000019`). |
| Progress (in progress, completed) | Event Status Nominal ICE `cco:ont00000203` | `is a nominal measurement of` (`cco:ont00001868`) the act; its value is the text on an Information Bearing Entity (`cco:ont00000253`) that `is carrier of` it. Not started is the absence of any status. |
| Cancelled | Nominal Measurement ICE `cco:ont00000293` | Measures the action itself, since no act exists (Decision 4). The reason is a Descriptive ICE that `is about` (`cco:ont00001808`) that measurement. |
| Objective achieved | Nominal Measurement ICE `cco:ont00000293` | Measures the objective, confirmed by an agent (Decision 5). |
| Priority | Priority Measurement ICE `cco:ont00000369` | `is an ordinal measurement of` (`cco:ont00001811`) the action; integer value on a bearer, 1 first. |
| What happened | Planned Act `cco:ont00000228`, Act of Planning `cco:ont00000511` | `prescribed by` (`cco:ont00001920`) the action or plan, `has agent` (`cco:ont00001833`) who acted. |
| Why it fell short | Descriptive ICE | `is about` the act. |
| Risk | Predictive ICE `cco:ont00000626` | `is about` the objective or plan. |
| Supporting material | Descriptive ICE | `is about` the plan or objective; a link is the URI value (`cco:ont00001768`) on its bearer. |
| Agent | Agent `cco:ont00001017`, Person `cco:ont00001262` | An AI agent is the running machine (Decision 3). |
| Values statement | BCIO personal value `BCIO_006063` | A disposition in the person; the statement `is about` it. Not imported yet: it arrives with the habit work. |
| Recurrence | none | A recurring action prescribes many acts; the rule is iCal RRULE, owned by the specification (Decision 6). |
| Time | Temporal Interval / Instant | The act `occupies temporal region`. |

Known stretch: a wait's condition `describes` the awaited action specification, standing in for its act, which may not exist yet.

## Upstream watch

Checked 2026-09-30 against the CCO milestones. Re-check when CCO 3.0 is tagged; CCO's board recommends waiting for 4.0 before updating.

- **Stable through 3.0 and 4.0:** Plan, Objective, Planned Act, Act of Planning, Act of Measuring, prescribes, is about, Event Status, Stasis, Predictive ICE, Performance Specification. Everything above leans on these.
- **In flux in 3.0:** information and its carriers (#875, #593, #682, #596) and QUDT replacing CCO units (#307). Records are therefore Descriptive ICEs `is about` the act, not CCO Report. Priority Scale may move from Descriptive to Directive (#147); cosmetic for us.
- **Wanted from 3.0:** the Information Structure Entity draft (#949) separates how information is structured from what it says. If adopted, the specification's formats (lines, documents, calendar entries) could be stated as Information Structures in CCO's own terms.
- **Read axioms, not prose:** some CCO definitions cite classes that no longer exist ("Directive Information Content Entity" in Planned Act, "Intentional Acts" in Plan).
