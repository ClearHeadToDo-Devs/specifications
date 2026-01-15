# ClearHead Specifications
This is intended to be a space where key specifications can live, separated by the implementation details of the underlying projects.

This enables those who wish to build upon the specifications, but avoid the tooling to do such without needing to carve out the relevant pieces from the implementation products.

# ClearHead Platform Overview
Many of these other specifications cover rather precise technical details, but i want to take a bit of time to cover the overarch process that is guiding much of these specifications as a way to bring meaning to the disperate parts.

## The Problem Being Solved
At its core, ClearHead is an attempt to _express intention_ in a clean, straightforward manner.

This starts as a simple text file on your machine, your replacement for `todo.txt`. However, as your needs grow, the tools will grow with you at the pace you need, rather than forcing you into a complex system from the start.

When you do start integrating these into your systems, it is important that these intentions become just as much data as they are text, and we will have access to the tools that power users are used to, rather than reinventing the wheel again.

We have demanding lives, and making these intentions useful takes more work than one might think when they start their todo.txt, and the goal is to allow people to use these intentions in whatever way makes sense within their system to:
- Keep track of what they need to do
  - both at home and while travelling
  - with or without internet access
  - on or off their home devices
- Pass intentions to other agents
  - coworkers
  - family members
  - hired professionals
  - LLM agents
- Analyze and reflect on their intentions
  - Capture data on how they spend their time
  - Reflect on what they have accomplished
  - find the dependencies between intentions
- Integrate this with other data
  - Calendar events to track intentions
  - Links to appropriate resources
  - Automations to help accomplish intentions
  - using the intentions themselves as a workflow engine for both humans and machines

## Values and Principles
With this platform, my goal is to create a system with a few core values:
- local-first: Users should be able to use the system fully offline, with optional cloud sync.
  - Adherence to Standards: In particular, i believe we achieve local-first software through the coordination of standards and data rather than bespoke implementations.
  - Interoperability: Different tools and implementations should be able to work together seamlessly.
    - This is why these specifications exist as a separate repo, so that other implementors can build their own tools that interoperate with the ecosystem.
- Incremental Adoption: Users should be able to start small and gradually integrate more features as they see fit, or not! A core usecase is the single person, writing a plaintext file in the woods are their phone without internet.
  - This is why the string file format is the core of the system, and everything else builds on top of that.
  - Power users will also need to extend the system beyond the core and this needs to be possible without breaking the core usecases.
- Opinionated Defaults: Everything from the file format to the tools is built with intention. We want to leverage best practices to make a nice experience out-of-the-box rather than making people build their workflow from scratch.
  - While we want to make customizability core, preferrably, for most this is a rare occasion and they can be productive with the system before they need to adopt the entire workflow

  These values are some of the big reasons i have not used one of the leading task frameworks as i didnt feel that any of them held to all of these values even if they stuck to one or two.

### Philisophical Inspirations

This has been a topic of research of mine for many years and it would be rude of me not to credit many of these authors for guiding and shaping my thinking on the topic:
- [Getting Things Done](https://gettingthingsdone.com/) by David Allen - The foundational text on modern task management and productivity.
  - Ive been practicing GTD personally for over a decade now and it shapes much of my thinking on these topics. In terms of clear, pragmatic systems for intentions I believe David does the best at creating a system that is empathetic to how humans actually work.
- [Deep Work](https://www.calnewport.com/books/deep-work/) by Cal Newport - A deep dive into the importance of focused work and how to achieve it in a distracted world.
  - While GTD is a brillient set of systems, it has relatively little to say on WHAT actions you should take and WHEN and how to go about them. Deep work answers this question by arguing that we should be trying to do as much deep work as possible, minimizing and automating shallow work. 
  - Cal has done a great job of outlining how professions like programming need to work and serves as a good guide to finding focus in a world of distractions.
- [The Agile Manifesto](https://agilemanifesto.org/) by Kent Beck et al. - A set of principles for software development that emphasizes collaboration, flexibility, and customer satisfaction.
  - While mostly focused on software, i believe the core insight of agile is a sense of humility and pragmatism when it comes to delivering work. Whereas the first two are about optimizations, agile is this funny instance of a more humanistic perspective peaking out from a very corporate mindset.
- [Marie Kondo's life-changing magic of tidying up](https://konmari.com/) by Marie Kondo - A guide to decluttering and organizing your physical space to create a more joyful life.
  - Marie does a good job of making a cleaning book not about cleaning, a productivity book not about productivity. Instead, or in addition to her wonderful cleaning tips, she subtly influences the reader with zen buddhist principles of mindfulness and intentionality, and serves as one of the more subtle pieces in this list but no doubt one of the most sophisticated in terms of the topics she covers
- [Atomic Habits](https://jamesclear.com/atomic-habits) by James Clear - A comprehensive guide to building good habits and breaking bad ones through small, incremental changes.
  - Another area that GTD doesnt cover as throughly is the idea of habits. or put another way, habits can be seen as a higher level system for managing actions that recur frequently. James does a great job of breaking down the science of habits and giving practical advice on how to build and maintain them.
  - I see it as using the systems of GTD to create the habits we want to see for ourselves, first with technical tools, until they become second nature.

#### Technical Inspirations

Over the years of research I have seen many implementations that have inspired this work:
- [todoist](https://todoist.com/) - A powerful task management system with a strong focus on user experience and cross-platform support.
  - My current personal task system while this system is built and while it adheres to most of the web 2.0 principles, it does a good job of being a solid, reliable task manager that just works and any system that replaces it will need to meet this high bar for both usability and reliability.
- [(Neo)vim](https://neovim.io/) - An extensible and highly customizable text editor that serves as the foundation for many ClearHead tools.
  - as my personal editor, neovim is a constant source of inspiration from both a technical perspective, as well as a user experience perspective. this tool will in many ways try to bring some of the same principles of extensibility and customizability to task management that neovim brings to text editing.
- [todo.txt](https://todotxt.org/) - A simple, plaintext-based task management system that emphasizes simplicity and portability.
  - has always been the standard bearer of simplicity in task management and while it lacks many of the advanced features of modern systems, its simplicity and portability are unmatched. ClearHead aims to aknowledge this core insight that one should always be able to go back to editing a file to list out intentions even if we grow from there.
- [taskwarrior](https://taskwarrior.org/) - A command-line task management tool that offers advanced features and flexibility for power users. 
  - taskwarrior shows in many ways the opposite virtue of todo.txt, in that it wants to leverage the power of data to do really cool things with relatively little effort. This is another very good virtue that clearhead will seek to embody.
- [org-mode](https://orgmode.org/) - An Emacs-based system for organizing tasks, notes, and projects with a focus on plain text and extensibility.
    - org-mode is another very powerful system that has a strong focus on plain text and shows that there is no reason a plain-text based system cant be as powerful as a database-backed system. While i personally dont use emacs, i do admire the power and flexibility of org-mode and its community.

While all of these systems have their strengths and weaknesses, none of them fully embody the values and principles that ClearHead aims to achieve, and thus i felt there was a need for a new system that could bring these ideas together in a cohesive manner.
## Index

Here is the index of specifications and their purpose within the whole:

1. [Proccess Overvoiew](./process.md) - A high level overview of how the process around actions are intended to work in the standard format to express how the more low-level specifications fit together to create a coherent system.
1. [Action File Format](./actionn.md) - The for format for the action files that serve as the atomic core of the rest of the system. If you read nothing else, start here to understand how action files are defined.
    1. For Example, while [tree-sitter-actions](https://github.com/ClearHeadToDo-Devs/tree-sitter-actions) implements this specification using tree-sitter, it could just as easily be implemented using PEGS or any other parsing technology.
2. [Naming Conventions](./naming_conventions.md) - The conventions for naming repositories, files, and other artifacts within the ClearHead ecosystem. This allows different tools to interoperate without confusion as they can leverage shared configuration, naming semantics, and structure to build more interesting systems
    1. Both [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) and [clearhead.nvim](https://github.com/ClearHeadToDo-Devs/clearhead.nvim) implement these conventions to manage collections of actions, wether they be plaintext files, json data, or full databases.
3. [Configuration](./configurationn.md) - Defines how ClearHead implementations handle configuration, including XDG directory structure, JSON configuration format, layered configuration (defaults → file → env → args), and extension mechanisms for implementation-specific settings. This ensures all tools share a common configuration approach while allowing for tool-specific extensions.
    1. Implementations like [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) and [clearhead.nvim](https://github.com/ClearHeadToDo-Devs/clearhead.nvim) can share configuration via `~/.config/clearhead/config.json` while maintaining their own sections for tool-specific settings.
4. [Json Schema](./json_schema.md) - The canonical JSON serialization format for action files. This allows different tools to exchange action data in a structured way, and also enables validation and storage in systems that require structured formats.
    1. For Example, while [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) can inject action files, it can export json files that conform to this specification for use in other systems.
        1. Great for those who want to build with data but dont want a full database. with knowledge they can be synced back to plaintext action files later.
5. [Database Schema](./sql_schema.md) - The schema for storing actions in a relational database. This allows for efficient querying, filtering, and manipulation of action data in a structured environment.
    1. [clearhead-cli](https://github.com/ClearHeadToDo-Devs/clearhead-cli) leverages this to query lists of actions in an efficient manner, allowing for complex filters and operations that would be cumbersome with plaintext files alone. while also being able to translate operations losslessly back to the action file format.
6. [Ontology & Linked Data](./ontology.md) - Defines the semantic meaning of the data using the Actions Vocabulary (OWL) and explains the Context Map strategy.
    1. This specification ensures that while tools typically interact with simple JSON, the data remains semantically rigorous and interoperable with the broader Semantic Web (RDF/JSON-LD).
    2. It bridges the gap between the pragmatic `clearhead-cli` world and the formal logic of the ontology.
7. the [examples directory](./examples/) - A collection of example action files, covering a wide range of use cases and scenarios.
    1. [conformance_test.actions](./examples/conformance_test.actions) - A "Gold Standard" file testing all metadata fields, tree consistency, and date derivation.
    2. Implementors are expected to vendor these examples into their own projects as conformance tests and usage examples for their users. Thus, ensuring a consistent experience across different tools in the ClearHead ecosystem.
    2. Example queries for both jq and sql are provided to help with interoperability between different query approaches.
        1. while these are optional, it is recommended that implementors atleast be aware of canonical query patterns to help users transition between different tools more easily.
