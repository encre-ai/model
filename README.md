# @encre/model

The Typst library encre pages are written with. A page is one Typst file in a knowledge base. It holds the elements of a domain model: terms, entities, events, invariants, formulas, decisions and open questions, and the links between pages. encre serves this library to every page, compiles each page when it is written, and reads the elements out of it.

```typ
#import "@encre/model:0.1.0": *
```

A page holds information only. encre refuses `set` and `show` rules, and imports of any other package.

## Elements

Each function takes the element's name first. Every element also takes `aliases`, other names it goes by, `source`, where its knowledge comes from, and `key`, its label. The label defaults to the name in lowercase with hyphens, so "Purchase order" is `<purchase-order>`. Each file in `src/` documents its function's arguments.

```typ
#term("Invoice", [A request for payment for an order.],
  aliases: ("bill",), avoid: ("receipt",))

#entity("Purchase order", [What a customer asks to buy, from placing to delivery.],
  key: "purchase-order-entity",
  attributes: (number: [Identifies the order; never changes.]))

#event("Order placed", [A customer confirmed their basket.],
  about: <order>, payload: (number: [The order's number.]))

#invariant("Total of lines", [An invoice's total is the sum of its lines.],
  about: (<invoice>,), because: [Lines are the only source of a price.])

#formula("Invoice total", $T = sum_i q_i p_i$, where: (
  T: [the invoice's total, in euros],
  q: <quantity>,
  p: at("/terms/price", <unit-price>),
))

#decision("Version pages one by one",
  status: "accepted",
  problem: [Two writers must not overwrite each other.],
  outcome: [Each page keeps its own history of revisions.],
  consequences: [A change across pages is several writes.],
  options: ([Version the whole knowledge base, like a git commit.],))

#question("Credit notes", [Does a credit note reduce an invoice or replace it?],
  about: <invoice>)
```

An entity is also a word of the language, so a page writes both. The `term` keeps the name's label, `<invoice>`, and the `entity` takes its own key, such as `"invoice-entity"`, because two elements of one page cannot share a label. A decision that replaces another names it in `supersedes`, and the old one's `status` becomes `"superseded"`.

## Links between pages

Pages live at paths such as `/billing/invoice`. An element of the same page is its label, `<invoice>`. An element of another page of the same knowledge base is `at("/billing/invoice", <invoice>)` inside a field such as `about` or `where`. In text, `see` links to a page or an element:

```typ
#see("/terms/invoice")
#see("/terms/invoice", <due-date>)[the due date]
#see(<paid-in-full>)
```

encre checks every `at` and `see` when the page is written, and refuses a link to a page or label that does not exist.

## Sources

Every element names where its knowledge comes from in `source`, one source or an array of several.

| Where it comes from | Write |
|---|---|
| A person said or confirmed it | `source: [Confirmed by the user, 2026-11-15]` |
| A file of the project | `source: "app/billing/src/invoice.rs"` |
| A ticket, a web page, a document online | `source: link("https://…")[Ticket 42]` |
| Another page of the knowledge base | `source: see("/meetings/2026-11-15")` |
| A work, such as a book, a paper or a standard | `source: [@evans-2003[p. 335]]` |
| Several of these | `source: ([Confirmed by the user], "app/billing/src/invoice.rs")` |

A source refers to an element of the knowledge base with `see`. The `@` form names works only.

## Works

Works live on the knowledge base's page `/bibliography`, in one block of Hayagriva YAML or BibLaTeX given to `works`. Add a work there under a key such as `evans-2003`, with its type, title, author, date and url. Write the YAML lines at the left margin.

````typ
#import "@encre/model:0.1.0": *
= Bibliography
The works this knowledge cites.
#works(```yaml
evans-2003:
  type: book
  title: Domain-Driven Design
  author: Evans, Eric
  date: 2003
```)
````

A page that cites a work, in its text or in a `source`, ends with `#sources()`, which lists the works it cites. encre reads a citation as the work's name only inside `source` or in text. Inside another field, such as a decision's `outcome`, it reads as nothing.

## License

MIT
