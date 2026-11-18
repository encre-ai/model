// Diagrams: a picture of how elements relate, drawn from Mermaid.

#import "element.typ": aliases-of, also, check-local, cited, element, key-of, numbered, references, recorded-sources, sources-of

/// A Mermaid diagram that shows how elements relate, such as an entity's
/// lifecycle, the steps of a process or the parts of a system. encre draws
/// it when it shows the page and finds it by its name, description and
/// code. A diagram illustrates: each rule it shows is also an element of
/// its own, such as an invariant or an event.
///
/// ````typ
/// #diagram("Order lifecycle", [How an order moves from placed to
///   delivered.], about: <order-entity>,
///   ```mermaid
///   stateDiagram-v2
///     Placed --> Paid
///     Paid --> Delivered
///   ```)
/// ````
///
/// - name (str): What the diagram shows, in a few words.
/// - description (content): What it shows and how to read it.
/// - code (raw): The diagram, as a raw block whose language is mermaid.
///   Any Mermaid diagram type works: flowchart, sequenceDiagram, stateDiagram-v2,
///   erDiagram, classDiagram and the others.
/// - about (label, array): The elements it shows: labels of this page, or
///   `at(...)` for another page.
/// - aliases (array): Other names people give the diagram.
/// - source (content, array): Where the knowledge comes from, such as
///   [Confirmed by the user] or link("https://…")[Ticket 42]; an array
///   for several.
/// - key (str): The diagram's label, `<order-lifecycle>` for "Order
///   lifecycle" by default.
#let diagram(name, description, code, about: (), aliases: (), source: none, key: auto) = {
  let key = key-of("diagram", name, key)
  let aliases = aliases-of("diagram", name, aliases)
  let sources = sources-of("diagram", name, source)
  assert(
    type(code) == content and code.func() == raw and code.at("lang", default: none) == "mermaid",
    message: "diagram \"" + name + "\" takes its drawing as a ```mermaid block after its description, such as ```mermaid flowchart LR; A --> B```",
  )
  assert(
    code.text.trim() != "",
    message: "the ```mermaid block of diagram \"" + name + "\" is empty: write the diagram in it",
  )
  let about = references(about, "the about of diagram \"" + name + "\"")
  check-local(about, "diagram \"" + name + "\"")
  let body = {
    description
    raw(code.text, lang: "mermaid", block: true)
    also(aliases)
    cited(sources)
  }
  element("diagram", key, name, (description: description, aliases: aliases, about: about, code: code.text, source: recorded-sources(sources)), numbered("diagram", [Diagram], key, name, body))
}
