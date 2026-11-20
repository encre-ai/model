// Trying a formula: the values a reader enters for its inputs, and what its
// `compute` gives for them. encre asks for one formula's result by
// compiling its page with `sys.inputs` holding, under `encre-try`, a JSON
// object such as `{"key": "days-sales-outstanding", "values": {"B": "1200",
// "S": "3000"}}`. The formula then writes its result in a metadata element,
// `(encre-tried: version, key: …, value: …)`, or what was wrong with the
// values, `(encre-tried: version, key: …, error: "…")`.

#import "element.typ": version

// Whether `value` is a number Typst computes with.
#let is-number(value) = type(value) in (int, float, decimal)

// The inputs of formula `name`, checked: each a symbol of its `where`, with
// a default value or `none`, and `compute`, which takes them in order.
// `none` when the formula takes neither.
#let inputs-of(name, inputs, compute, symbols) = {
  let field = "formula \"" + name + "\""
  assert(
    (inputs == none) == (compute == none),
    message: field + " takes inputs and compute together: inputs names what a reader enters, such as (B: none, d: 90), and compute calculates from it, such as (B, d) => B / d",
  )
  if inputs == none { return none }
  assert(
    type(inputs) == dictionary and inputs.len() > 0,
    message: "the inputs of " + field + " are a dictionary of its symbols and their default values, such as (B: none, d: 90)",
  )
  assert(
    type(compute) == function,
    message: "the compute of " + field + " is a function of its inputs, in their order, such as (B, d) => B / d",
  )
  for (symbol, default) in inputs {
    assert(
      symbol in symbols,
      message: "the input " + symbol + " of " + field + " is not a symbol of its where: say there what it stands for",
    )
    assert(
      default == none or is-number(default) or (type(default) == array and default.all(is-number)),
      message: "the input " + symbol + " of " + field + " takes a number, none when it has no default value, or an array of numbers when it is a list, such as ()",
    )
  }
  inputs
}

// The number a reader wrote, such as "1200", "1 200,5" or "-3e2": an
// integer when it has no fraction or exponent, a float otherwise. `none`
// when it is no number.
#let parse-number(text) = {
  if is-number(text) { return text }
  if type(text) != str { return none }
  let text = text.replace(regex("[\s_\u{a0}\u{202f}]"), "")
  if text.matches(",").len() == 1 and not text.contains(".") { text = text.replace(",", ".") }
  if text.match(regex("^[+-]?\d+$")) != none { int(text) }
  else if text.match(regex("^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$")) != none { float(text) }
  else { none }
}

// The value of one input: what the reader entered, else its default. A
// string when it is wrong, saying why.
#let input-value(symbol, default, entered) = {
  let list = type(default) == array
  if entered == none {
    return if default == none { "enter a value for " + symbol } else { default }
  }
  if list {
    if type(entered) != array { return symbol + " takes a list of numbers" }
    let numbers = entered.map(parse-number)
    let wrong = numbers.position(number => number == none)
    if wrong != none { return "the value " + str(wrong + 1) + " of " + symbol + " is not a number" }
    numbers
  } else {
    let number = parse-number(entered)
    if number == none { symbol + " is not a number" } else { number }
  }
}

// What `compute` gives for `values`, after checking it is a number.
#let checked-result(name, compute, values) = {
  let result = compute(..values)
  assert(
    is-number(result),
    message: "the compute of formula \"" + name + "\" gives " + repr(result) + ", but a formula computes a number",
  )
  result
}

// The values `sys.inputs` asks formula `key` to be tried with, or `none`
// when it asks for another formula, or for none.
#let asked(key) = {
  let asked = sys.inputs.at("encre-try", default: none)
  if asked == none { return none }
  let asked = json(bytes(asked))
  if asked.at("key", default: none) != key { return none }
  asked.at("values", default: (:))
}

// The result of formula `key` for the values `sys.inputs` asks it to be
// tried with, as metadata encre reads, or nothing when it asks for none.
// Without values, checks that `compute` gives a number for the defaults
// when every input has one.
#let tried(name, key, inputs, compute) = {
  if inputs == none { return }
  let entered = asked(key)
  if entered == none {
    if inputs.values().all(default => default != none) {
      let _ = checked-result(name, compute, inputs.values())
    }
    return
  }
  let values = inputs.pairs().map(((symbol, default)) => input-value(symbol, default, entered.at(symbol, default: none)))
  let wrong = values.filter(value => type(value) == str)
  if wrong.len() > 0 {
    metadata((encre-tried: version, key: key, error: wrong.join("; ")))
  } else {
    metadata((encre-tried: version, key: key, value: checked-result(name, compute, values)))
  }
}

// The inputs a reader can try the formula with, for encre to build its
// form from: in HTML, a hidden list of each input's symbol, in Typst math,
// and what it stands for, marked with the symbol and its default value.
// Nothing in other targets.
#let inputs-list(inputs, meanings) = context if target() == "html" and inputs != none {
  html.elem("dl", attrs: (data-part: "inputs", hidden: ""), {
    for (symbol, default) in inputs {
      let attrs = (data-input: symbol)
      if type(default) == array {
        attrs.insert("data-list", "")
        attrs.insert("data-default", json.encode(default.map(str), pretty: false))
      } else if default != none {
        attrs.insert("data-default", str(default))
      }
      html.elem("dt", attrs: attrs, math.equation(eval(symbol, mode: "math")))
      html.elem("dd", meanings.at(symbol))
    }
  })
}
