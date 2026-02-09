# Ontology Domain
Please feel free to review the full ontology and docs at [the full ontology repo](https://github.com/ClearHeadToDo-Devs/ontology).

For this we have a few primary entities that will align how much of the specifications are structured and understood:

- **Objectives**: Desired outcomes written down for the sake of planning towards them
- **Charters**: Declarations of scope for a particular domain of concern, these are the "containers" for plans and planned acts
- **Plans**: the formalized perscriptions that describe the intended execution of a plan, these are the "templates" for planned acts
- **Planned Acts**: the actual executions of plans, these are the "instances" of plans 

many of our structure map to these domain objects

## In specifications
many of the concepts and topics are ultimately converted into the domain objects or thought through the structure of the domain objects which is why this is an important core to understand when putting your head around the topic itself

## In Application Code
Another use of the ontology is in the form of structs or classes that can mirror the domain objects, either explicitly or through generation, so that we are able to have the structured understanding all the way through

### For querying
With this established, applications that use this format can start querying application data that is available through the lens of these domain objects using the SHACL shapes for validation of data in a graph database, and SPARQL queries for the primary querying technique for this work.

in this way, we can have a normal query language that can be shared between applications and composed with different ontologies so that this work can be put into the context of a larger ecosystem of ontologies and data
