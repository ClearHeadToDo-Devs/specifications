# ClearHead Process Explanation
While the [process specification](../process.md) is probably the most high-level document and covers the process in an abstract way, its important to explain how it connects to the other bits of guidance in the specifications.

In particular, the way to understand the process is as something that brings together most if not all of the concepts covered in the other documents to make an open, document-based process that tries to cover each topic orthogonally to give implementors specific guidance when they need

## Context
For starters, the process is assumed to be a check that happens AFTER intial parsing according to the [File Format](../action_file_format.md) specification. This means that any file being processed is already known to be valid according to the grammar.

As well as being after the [Formatting](../formatting.md) phase, which means that any files being processed are also in a canonical format that tools can rely on to make certain assumptions about structure and layout. (or not!) all optional.

Now, [linting](../linting.md) can happen either before or after processing depending on the use case. For example, a linter could be used to check for issues before processing to prevent bad data from entering the system, or it could be used after processing to ensure that certain process level checks outlined in [process](../process.md) are being followed.

### Embracing Minimal Structure
In order to avoid stuffing implementors with design details, we instead leverage the filesystem itself for much of how we handle this process. for example, [workspace conventions](../workspace.md) are used to determine which files are considered part of the process without needing to define complex structures within the files themselves.

All of this can be configured according to the [configuration specification](../configuration.md) to allow people to control the process no matter what tool they are using, and implementors need only respect this shared configuration in order to allow users to move seamlessly between different tools.

## Extra Features
While the core process is intentionally minimal, implementors are encouraged to add extra features on top of this that enable better user experiences and make the tools more powerful overall including:
- [Observability](../observability.md) features to allow users to track and monitor their actions over time while also allowing various tools to integrate with each other more easily as they can find the shared history of how a set of plans have changed over time.
- [Sync](../sync.md) features to allow users to keep their actions in sync across multiple devices and platforms, ensuring that they always have access to the most up-to-date information no matter where they are in a local-first way.
- the [Ontology](../ontology.md) specification allows all of this to be implemented in a universal way such that different tools can understand and interoperate with each other more easily without needing explicit integration points built out for each pair of tools.

While none of these features are required, they allow much more of the analytical and collaborative use cases outlined in the process document


