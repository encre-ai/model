// The works a knowledge base cites: its page `/bibliography` lists them with
// `works`, and a page that cites them ends with `sources`, Typst's own
// bibliography of the works it cites.

// The page of a knowledge base that lists its works.
#let bibliography-page = "/bibliography"

// How encre shows a citation and a list of works.
#let style = "chicago-author-date"

// The block that `works` takes in the page whose text is `text`: Hayagriva
// YAML or BibLaTeX, as written between its backticks. `none` when there is
// none. The page is read as text, not run, as `at` reads a page.
#let works-data(text) = {
  let found = text.match(regex("(?s)works\(\s*```[a-z]*[ \t]*\n(.*?)```"))
  if found == none { none } else { found.captures.at(0) }
}

/// The works the knowledge base cites, on its page `/bibliography`, shown as
/// a full bibliography. Write them in Hayagriva YAML, Typst's own format, or
/// in BibLaTeX, as one raw block whose lines start at the left margin.
/// encre reads a citation of a YAML work as its authors, title and date.
///
/// ```typ
/// = Bibliography
/// #works(```yaml
/// evans-2003:
///   type: book
///   title: Domain-Driven Design
///   author: Evans, Eric
///   date: 2003
/// ```)
/// ```
///
/// - data (raw): The works, as a raw block.
#let works(data) = {
  assert(
    type(data) == content and data.func() == raw,
    message: "works takes the works as one raw block, such as ```yaml evans-2003: ...```, in Hayagriva YAML or BibLaTeX",
  )
  bibliography(bytes(data.text), title: none, full: true, style: style)
}

/// The works this page cites, from `/bibliography`, shown as Typst's
/// bibliography: write it once, at the end of a page that cites a work with
/// `@key` or `cite(<key>)`, in its text or in an element's `source`.
///
/// ```typ
/// #invariant("Paid in full", [...], source: [@evans-2003, p. 42])
///
/// #sources()
/// ```
///
/// - title (content): The title over the list.
#let sources(title: [Sources]) = {
  let data = works-data(read(bibliography-page))
  assert(
    data != none,
    message: "the page " + bibliography-page + " lists no works: write them there in #works(```yaml ...```)",
  )
  bibliography(bytes(data), title: title, style: style)
}

// The works of `/bibliography` as a dictionary by key, when they are
// Hayagriva YAML; empty when they are BibLaTeX.
#let yaml-works() = {
  let data = works-data(read(bibliography-page))
  if data == none or data.trim().starts-with("@") { (:) } else { yaml(bytes(data)) }
}

// One work as a reader names it: its authors, title and date, such as
// "Evans, Eric: Domain-Driven Design (2003)"; its key when encre cannot
// read it.
#let work-name(works, key) = {
  let work = works.at(key, default: none)
  if type(work) != dictionary { return key }
  let authors = work.at("author", default: ())
  let authors = if type(authors) == array { authors.join("; ") } else { str(authors) }
  let title = work.at("title", default: key)
  let title = if type(title) == dictionary { title.at("value", default: key) } else { str(title) }
  let date = work.at("date", default: none)
  (if authors != "" { authors + ": " } else { "" }) + title + if date != none { " (" + str(date) + ")" } else { "" }
}

// The keys of the works `item` cites: `cite(<key>)`, or `@key` for a key
// that is no label of the page, at any depth.
#let cited-keys(item) = {
  if type(item) != content { return () }
  if item.func() == cite { return (str(item.key),) }
  if item.func() == ref { return (str(item.target),) }
  if item.has("children") { return item.children.map(cited-keys).flatten() }
  if item.has("body") { return cited-keys(item.body) }
  ()
}

// `item` as encre records it: each citation made the name of its work, so
// that encre reads what the source is rather than an empty citation.
#let recorded(item, works) = {
  if type(item) != content { return item }
  let key = if item.func() == cite { str(item.key) } else if item.func() == ref and str(item.target) in works { str(item.target) }
  if key != none {
    let supplement = item.at("supplement", default: none)
    return if type(supplement) == content { [#work-name(works, key), #supplement] } else { work-name(works, key) }
  }
  if item.has("children") { return item.children.map(child => recorded(child, works)).join() }
  item
}
