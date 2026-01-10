# ClearHead Specifications
This is intended to be a space where key specifications can live, separated by the implementation details of the underlying projects.

This enables those who wish to build upon the specifications, but avoid the tooling to do such without needing to carve out the relevant pieces from the implementation products.

## Index

Here is the index of specifications and their purpose within the whole:

1. [Action File Format](./action_specification.md) - The for format for the action files that serve as the atomic core of the rest of the system. If you read nothing else, start here to understand how action files are defined.
    1. For Example, while [tree-sitter-actions](https://github.com/ClearHeadToDo-Devs/tree-sitter-actions) implements this specification using tree-sitter, it could just as easily be implemented using PEGS or any other parsing technology.
2. [Naming Conventions](./naming_conventions.md) - The conventions for naming repositories, files, and other artifacts within the ClearHead ecosystem. This allows different tools to interoperate without confusion as they can leverage shared configuration, naming semantics, and structure to build more interesting systems
    1. Both [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) and [clearhead.nvim](https://github.com/ClearHeadToDo-Devs/clearhead.nvim) implement these conventions to manage collections of actions, wether they be plaintext files, json data, or full databases.
3. [Configuration](./configuration_specification.md) - Defines how ClearHead implementations handle configuration, including XDG directory structure, JSON configuration format, layered configuration (defaults → file → env → args), and extension mechanisms for implementation-specific settings. This ensures all tools share a common configuration approach while allowing for tool-specific extensions.
    1. Implementations like [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) and [clearhead.nvim](https://github.com/ClearHeadToDo-Devs/clearhead.nvim) can share configuration via `~/.config/clearhead/config.json` while maintaining their own sections for tool-specific settings.
4. [Json Schema](./json_schema_specification.md) - The canonical JSON serialization format for action files. This allows different tools to exchange action data in a structured way, and also enables validation and storage in systems that require structured formats.
    1. For Example, while [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) can inject action files, it can export json files that conform to this specification for use in other systems.
        1. Great for those who want to build with data but dont want a full database. with knowledge they can be synced back to plaintext action files later.
5. [Database Schema](./sql_schema_specification.md) - The schema for storing actions in a relational database. This allows for efficient querying, filtering, and manipulation of action data in a structured environment.
    1. [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) leverages this to query lists of actions in an efficient manner, allowing for complex filters and operations that would be cumbersome with plaintext files alone. while also being able to translate operations losslessly back to the action file format.
6. [Ontology & Linked Data](./ontology_specification.md) - Defines the semantic meaning of the data using the Actions Vocabulary (OWL) and explains the Context Map strategy.
    1. This specification ensures that while tools typically interact with simple JSON, the data remains semantically rigorous and interoperable with the broader Semantic Web (RDF/JSON-LD).
    2. It bridges the gap between the pragmatic `clearhead-cli` world and the formal logic of the ontology.
7. the [examples directory](../examples/) - A collection of example action files, covering a wide range of use cases and scenarios.
    1. [conformance_test.actions](../examples/conformance_test.actions) - A "Gold Standard" file testing all metadata fields, tree consistency, and date derivation.
    2. Implementors are expected to vendor these examples into their own projects as conformance tests and usage examples for their users. Thus, ensuring a consistent experience across different tools in the ClearHead ecosystem.
    2. Example queries for both jq and sql are provided to help with interoperability between different query approaches.
        1. while these are optional, it is recommended that implementors atleast be aware of canonical query patterns to help users transition between different tools more easily.
