#import "@preview/callisto:0.3.0"
#import "@preview/codly:2.0.0" as codly

// Печать номера ячейки вынесена вовне.
#let plain-result(data, ctx: none, ..args) = {
  callisto.handle(
    data,
    mime: "rich-output-generic",
    ctx: ctx,
    ..args,
  )
}

#let plain-code-input(cell, ctx: none, block-args: none, ..args) = {
  callisto.handle(
    cell.source,
    mime: "source-code-generic",
    ctx: ctx,
    lang: ctx.lang,
  )
}

#let plain-code-output(cell, ctx: none, ..args) = {
  let outs = callisto.outputs(cell, ..ctx.cfg)
  if outs.len() == 0 { return }
  block(
    above: if ctx.input { 0pt } else { 2em },
    below: 2em,
    width: 100%,
    inset: 0.5em,
    codly.new(outs.join()),
  )
}

#let plain-theme = (
  callisto.themes.notebook
    + (
      result: plain-result,
      code-cell-input: plain-code-input,
      code-cell-output: plain-code-output,
    )
)
