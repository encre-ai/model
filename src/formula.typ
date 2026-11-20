// Formulas: the calculations of the domain, with what each symbol means.

#import "element.typ": aliases-of, also, check-local, cited, element, fields-list, key-of, numbered, reference, reference-link, recorded-sources, sources-of
#import "try.typ": inputs-list, inputs-of, tried

/// A calculation of the domain, with what each of its symbols stands for.
///
/// ```typ
/// #formula("Invoice total", $T = sum_i q_i p_i$, where: (
///   T: [the invoice's total, in euros],
///   q: <quantity>,
///   p: at("/terms/price", <unit-price>),
/// ))
/// ```
///
/// A formula a reader can try takes `inputs` and `compute`: encre shows a
/// button that opens a form with a field per input, and shows what
/// `compute` gives for the values entered.
///
/// ```typ
/// #formula("Days sales outstanding", $D = B / S times d$,
///   where: (D: [...], B: <outstanding-balance>, S: [...], d: [...]),
///   inputs: (B: none, S: none, d: 90),
///   compute: (B, S, d) => B / S * d)
/// ```
///
/// - name (str): What the formula computes.
/// - equation (content): The formula, in Typst math.
/// - where (dictionary): Each symbol and what it stands for: a description,
///   with its unit, or a reference to the term it is, as a label of this
///   page or `at(...)` for another page. A symbol is written in Typst math
///   and shown as such, so one with an index or a power is a quoted key,
///   such as `"g_i": [...]` or `"x^2": [...]`.
/// - inputs (dictionary): What a reader enters to try the formula: symbols
///   of `where`, each with its default value, or `none` for none. A list,
///   such as the amounts of an account's invoices, takes an array of
///   numbers, `()` when empty.
/// - compute (function): What the formula gives for the inputs, taken in
///   the order `inputs` writes them: a number. A list arrives as an array,
///   such as `amounts => amounts.sum(default: 0)`. Numbers arrive as
///   integers or floats. When every input has a default value, encre checks
///   that compute gives a number for them.
/// - aliases (array): Other names for what it computes, such as "Amount
///   due".
/// - source (content, array): Where the knowledge comes from, such as
///   [Confirmed by the user] or link("https://…")[Ticket 42]; an array
///   for several.
/// - key (str): The formula's label, from its name by default.
#let formula(name, equation, where: (:), inputs: none, compute: none, aliases: (), source: none, key: auto) = {
  let key = key-of("formula", name, key)
  let aliases = aliases-of("formula", name, aliases)
  let sources = sources-of("formula", name, source)
  assert(type(equation) == content, message: "formula \"" + name + "\" takes its equation in Typst math, such as $T = sum_i q_i p_i$")
  assert(type(where) == dictionary, message: "the where of formula \"" + name + "\" is a dictionary of symbols, such as (T: [the total, in euros], q: <quantity>)")
  let symbols = where.pairs().map(((symbol, meaning)) => {
    let field = "the symbol " + symbol + " of formula \"" + name + "\""
    if type(meaning) in (content, str) { (symbol, meaning, (description: meaning)) } else {
      let target = reference(meaning, field)
      (symbol, reference-link(target), (reference: target))
    }
  })
  let inputs = inputs-of(name, inputs, compute, where.keys())
  let meanings = symbols.map(((symbol, shown, _)) => (symbol, shown)).to-dict()
  let body = {
    equation
    also(aliases)
    if symbols.len() > 0 { fields-list(symbols.map(((symbol, shown, _)) => (math.equation(eval(symbol, mode: "math")), shown))) }
    cited(sources)
    inputs-list(inputs, meanings)
  }
  let refs = symbols.filter(((_, _, meaning)) => "reference" in meaning).map(((_, _, meaning)) => meaning.reference)
  check-local(refs, "formula \"" + name + "\"")
  let recorded = symbols.map(((symbol, _, meaning)) => (symbol: symbol, ..meaning))
  element("formula", key, name, (equation: equation, aliases: aliases, where: recorded, source: recorded-sources(sources)), numbered("formula", [Formula], key, name, body))
  tried(name, key, inputs, compute)
}
