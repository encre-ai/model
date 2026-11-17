// What every element shares: its key, the metadata encre reads it from, and
// the references that tie it to other elements.

// The version of the library, written into every element's metadata so
// that encre reads each element by the rules it was written under.
#let version = "0.1.0"

// The key an element gets when it is given none: its name in lower case,
// with each run of other characters than letters and digits made a `-`,
// so "Due date" becomes `due-date`.
#let slug(name) = lower(name).replace(regex("[^\p{L}\p{N}]+"), "-").trim("-")

// The key of an element called `name`, checked: `key` when one is given.
#let key-of(kind, name, key) = {
  assert(
    type(name) == str and name.trim() != "",
    message: kind + " takes its name as a string, such as \"Invoice\"",
  )
  let key = if key == auto { slug(name) } else { key }
  assert(
    type(key) == str and key.match(regex("^\p{L}[\p{L}\p{N}_-]*$")) != none,
    message: "the key of " + kind + " \"" + name + "\" must start with a letter and hold only letters, digits, `-` and `_`, such as \"due-date\"",
  )
  key
}

// The aliases of an element called `name`, checked: other names that mean
// the same, such as "PO" for "Purchase order". encre finds the element by
// any of them, comparing names as `slug` writes them, so two names that
// differ only in case or punctuation are one name.
#let aliases-of(kind, name, aliases) = {
  assert(
    type(aliases) == array and aliases.all(alias => type(alias) == str and alias.trim() != ""),
    message: "the aliases of " + kind + " \"" + name + "\" are strings, such as (\"PO\",)",
  )
  let own = aliases.filter(alias => slug(alias) == slug(name))
  assert(
    own.len() == 0,
    message: kind + " \"" + name + "\" lists its own name among its aliases: drop " + own.join(", "),
  )
  let repeated = aliases.enumerate().filter(((i, alias)) => aliases.slice(0, i).any(other => slug(other) == slug(alias)))
  assert(
    repeated.len() == 0,
    message: kind + " \"" + name + "\" lists the alias " + repeated.map(((_, alias)) => alias).join(", ") + " twice, in case or punctuation: keep one",
  )
  aliases
}

// A part of an element that encre styles on its own, such as its aliases: in
// HTML, a paragraph marked `data-part="aliases"`; elsewhere, the body
// inline.
#let part(name, body) = context if target() == "html" {
  html.elem("p", attrs: (data-part: name), body)
} else [ #body]

// The line that shows an element's aliases, or nothing when it has none.
#let also(aliases) = if aliases.len() > 0 { part("aliases")[_Also:_ #aliases.join(", ")] }

#import "bibliography.typ": cited-keys, recorded, yaml-works

// The sources of an element called `name`, checked: where its knowledge
// comes from, such as the person who stated or confirmed it, a file, a
// ticket or a link. One source, or an array of several.
#let sources-of(kind, name, source) = {
  let sources = if source == none { () } else if type(source) == array { source } else { (source,) }
  assert(
    sources.len() > 0 or source == none,
    message: "the source of " + kind + " \"" + name + "\" is empty: drop it, or say where the knowledge comes from",
  )
  assert(
    sources.all(source => type(source) == content or (type(source) == str and source.trim() != "")),
    message: "the source of " + kind + " \"" + name + "\" is text, such as [Confirmed by the user] or link(\"https://…\")[Ticket 42], or an array of them",
  )
  sources
}

// The line that shows an element's sources, or nothing when it has none.
#let cited(sources) = if sources.len() > 0 { part("source")[_Source:_ #sources.join("; ")] }

// Whether the page whose text is `text` carries the label `name`: written
// as `<name>`, or made from a string, such as the element name "Due date"
// or the key "due-date" for `<due-date>`. The page is read as text, not
// run, so a label it computes some other way is not seen.
#let has-label(text, name) = {
  text.contains("<" + name + ">") or text
    .matches(regex("\"((?:[^\"\\\\]|\\\\.)*)\""))
    .any(found => found.captures.at(0) == name or slug(found.captures.at(0)) == name)
}

// The name of the element whose key is `key` in the page whose text is
// `text`: the first string of the page that makes that key and is not the
// key itself, such as "Due date" for `due-date`. `none` when there is none.
#let element-name(text, key) = {
  let found = text
    .matches(regex("\"((?:[^\"\\\\]|\\\\.)*)\""))
    .map(found => found.captures.at(0))
    .find(string => string != key and slug(string) == key)
  found
}

// The path of a page from the root of its knowledge base, without a
// leading `/` or `.typ`, after checking that the page exists. Reading the
// page, rather than running it, lets two pages refer to each other.
#let page-path(page, from) = {
  assert(
    type(page) == str and page.starts-with("/"),
    message: from + " takes a page's path from the root of the knowledge base, such as \"/terms/invoice\"",
  )
  page.trim("/", at: start, repeat: false).trim(".typ", at: end, repeat: false)
}

/// A reference to the element or place labelled `target` in another page,
/// checked when the page is written: encre refuses it when the page or the
/// label does not exist.
///
/// ```typ
/// #invariant("Paid in full", [...], about: (at("/terms/invoice", <invoice>),))
/// ```
#let at(page, target) = {
  let path = page-path(page, "at")
  assert(type(target) == label, message: "at takes a label as its second argument, such as <invoice>")
  let text = read("/" + path)
  assert(
    has-label(text, str(target)),
    message: "the page /" + path + " has no label <" + str(target) + ">",
  )
  (encre-reference: version, page: path, label: str(target), name: element-name(text, str(target)))
}

// A reference as metadata records it: a label of this page becomes a
// reference with no page.
#let reference(target, field) = {
  if type(target) == label {
    (encre-reference: version, page: none, label: str(target), name: none)
  } else if type(target) == dictionary and "encre-reference" in target {
    target
  } else {
    assert(false, message: field + " takes a label of this page, such as <invoice>, or at(\"/terms/invoice\", <invoice>) for another page")
  }
}

// The name of what the label `key` of this page marks, as a reader knows
// it: the name of the element whose key it is, or the text of the heading
// it sits on; the key itself when it marks neither.
#let local-name(key) = context {
  let element = query(metadata).find(found => (
    type(found.value) == dictionary and "encre" in found.value and found.value.at("key", default: none) == key
  ))
  let marked = query(label(key))
  if element != none {
    element.value.name
  } else if marked.len() > 0 and marked.first().func() == heading {
    marked.first().body
  } else {
    key
  }
}

// A link to what `ref` names, showing `body`, or else the element's name or
// the label. A link to another page names it by path, `encre:/terms/invoice`,
// and encre points it at that page's address when it shows the page.
#let reference-link(ref, body: none) = {
  let shown = if body != none { body } else if ref.name != none { ref.name } else if ref.page == none { local-name(ref.label) } else { ref.label }
  if ref.page == none {
    link(label(ref.label), shown)
  } else {
    link("encre:/" + ref.page + if ref.label == none { "" } else { "#" + ref.label }, shown)
  }
}

// The references of a field that takes several, accepting a single one.
#let references(targets, field) = {
  let targets = if type(targets) == array { targets } else { (targets,) }
  targets.map(target => reference(target, field))
}

// A check that each reference to this page names a label that exists in it.
#let check-local(refs, field) = context {
  for ref in refs.filter(ref => ref.page == none) {
    assert(
      query(label(ref.label)).len() > 0,
      message: field + " names <" + ref.label + ">, which no element of this page carries",
    )
  }
}

// An element: what it shows, then its metadata, which encre reads. `shown`
// carries the element's label, so that links and references land on it.
#let element(kind, key, name, fields, shown) = {
  shown
  metadata((encre: version, kind: kind, key: key, name: name, ..fields))
}

// An element shown as a numbered figure of its own kind, titled with its
// name and labelled with its key, so `@key` in its page reads, for
// instance, "Invariant 2". In HTML the title comes first, its kind and
// number apart from its name, so a reader sees what an element is before
// reading it.
#let numbered(kind, supplement, key, name, body) = {
  show figure.caption: it => if target() == "html" {
    html.elem("figcaption", attrs: (data-kind: kind), {
      html.elem("span", attrs: (data-part: "kind"))[#it.supplement #it.counter.display(it.numbering)]
      " "
      html.elem("span", attrs: (data-part: "name"), it.body)
    })
  } else { it }
  [#figure(
      kind: kind,
      supplement: supplement,
      caption: figure.caption(position: top, name),
      body,
    )#label(key)]
}

// A list of `label: value` lines, for an element's attributes or fields.
#let fields-list(pairs) = terms(..pairs.map(((name, value)) => terms.item(name, value)))

// The sources of an element as encre records them: a citation of a work
// becomes the work's name, read from `/bibliography`, which is read only
// when a source cites one.
#let recorded-sources(sources) = {
  if sources.map(cited-keys).flatten().len() == 0 { return sources }
  let works = yaml-works()
  sources.map(source => recorded(source, works))
}
