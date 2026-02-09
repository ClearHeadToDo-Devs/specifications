# Charter Documentation 
Charters are the primary way that we organize plans within the platform. they are prose markdown documents that leverage combination of frontmatter and content to give users a way to organize plans and planned acts around a particular domain of concern.

## Frontmatter
for the purposes of organization and reading, frontmatter allows charters to contain some important metadata, while still remaining largely a prose document for human consumption

in this structure, we are primarily concerned with what is needed to give this structure meaning within the platform and link it with other parsed works meaning we have:
- id: a unique UUIDv7 for the charter that can be linked

this is the only required field for now if a charter DOES exist within the platform that will be used

### Optional Frontmatter
- title: a human readable title for the charter, this is optional because it can be derived
- alias: an aptional-short name for the charter that can be used for reference
  - aliases are scoped within the namespace of their parent charter
- parent: the reference of the parent charter, this allows for nesting charters within charters, and is optional because not all charters need to be nested
- objectives: a list of references to objectives within the platform that this works in servie of

## Content
For the purpose of the content, charters only need a single header and content below it 

```md
# Example Charter Title
with some description text
```

in this way, the first header serves as the title and the content serves as the description

even the description is optional, as the title is the only required content for a charter to be valid, but the description can be used to give more context about the charter and its purpose
