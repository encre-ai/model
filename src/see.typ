// Links between pages, which encre checks when a page is written and points
// at the pages' addresses when it shows one.

#import "element.typ": at, check-local, page-path, reference, reference-link, version

// The heading of the page whose text is `text` that `target` sits on, or
// its first heading when `target` is `none`; `none` when there is none.
#let heading-of(text, target) = {
  let pattern = if target == none {
    "(?m)^[ \t]*=[ \t]+(.*?)[ \t]*(<[^>]*>)?[ \t]*$"
  } else {
    "(?m)^[ \t]*=+[ \t]+(.*?)[ \t]*<" + target.replace(".", "\\.") + ">[ \t]*$"
  }
  let found = text.match(regex(pattern))
  if found == none { none } else { found.captures.at(0) }
}

/// A link to a page of the knowledge base, to an element or labelled place
/// in it, or to one in this page.
///
/// ```typ
/// #see("/terms/invoice")
/// #see("/terms/invoice", <due-date>)[the due date]
/// #see(at("/terms/invoice", <due-date>))
/// #see(<paid-in-full>)
/// ```
///
/// encre refuses the page when the page or the label does not exist. A link
/// shows, unless content is given to show: the heading the label sits on,
/// or the name of the element it labels, or the label; for a whole page,
/// its first heading, or its path.
#let see(..args) = {
  let usage = "see takes a page's path such as \"/terms/invoice\", optionally followed by a label such as <due-date>, or a label of this page, or at(...), then optional content to show"
  assert(args.named().len() == 0, message: usage)
  let args = args.pos()
  let body = if args.len() > 1 and type(args.last()) == content { args.pop() } else { none }
  assert(args.len() == 1 or (args.len() == 2 and type(args.at(0)) == str), message: usage)
  let target = if type(args.at(0)) == str {
    let path = page-path(args.at(0), "see")
    if args.len() == 2 {
      at("/" + path, args.at(1))
    } else {
      (encre-reference: version, page: path, label: none, name: none)
    }
  } else {
    reference(args.at(0), "see")
  }
  if target.page == none {
    return check-local((target,), "see") + reference-link(target, body: body)
  }
  // Reading the page checks that it exists, and gives the heading to show.
  let heading = heading-of(read("/" + target.page), target.label)
  let name = if heading != none { heading } else if target.name != none { target.name } else if target.label == none { target.page } else { none }
  reference-link((..target, name: name), body: body)
}
