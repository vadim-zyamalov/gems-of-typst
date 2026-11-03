#import "@preview/hydra:0.6.3": hydra
#import "@preview/parize:0.2.1": par-indent
#import "@preview/breather:0.1.0": breathe
#import "@preview/equate:0.3.3": equate

#let std-margin = (top: 2cm, bottom: 2cm, inside: 3cm, outside: 1cm)

// Переопределение заголовков в приложениях.
#let appendix(body, supplement: [Приложение], numbering: "A.1") = {
  set heading(numbering: numbering, supplement: supplement)
  body
}

// Функция для поворота страницы.
#let landscape(body) = context {
  let m-top = page.margin.top
  let m-bottom = page.margin.bottom

  set page(flipped: true, margin: (
    left: m-bottom,
    right: m-top,
    top: 2.5cm,
    bottom: 2.5cm,
  ))

  body
}

#let put-title() = context {
  let authors = if document.author != none {
    if type(document.author) == array {
      document.author
    } else {
      (document.author,)
    }
  }

  place(
    top + center,
    float: true,
    scope: "parent",
    clearance: 2em,
  )[
    #if document.title != none { title() }
    #if authors != none {
      text(size: 1em, weight: "bold")[
        #stack(
          dir: ttb,
          spacing: 1em,
          ..authors
            .chunks(3)
            .map(author-chunk => grid(
              columns: (1fr,) * author-chunk.len(),
              column-gutter: 1em,
              ..author-chunk
            )),
        )
      ]
    }
  ]
}

#let neat-document(
  indent: 2em,
  leading: 1em,
  font: "Noto Serif",
  sans-font: "Noto Sans",
  mono-font: "Noto Sans Mono",
  math-font: "Noto Sans Math",
  size: 14pt,
  raw-size: 0.9em,
  margin: (top: 2cm, bottom: 2cm, inside: 3cm, outside: 1cm),
  lang: "ru",
  refstyle: "chicago-author-date",
  doc,
) = {
  let leading = calc.max(0.65em, leading)
  let h-leading = calc.max(0.65em, leading / 2)

  // Настройки страницы.
  set page(
    paper: "a4",
    header: context {
      let page_num = counter(page).at(here()).first()
      if page_num != 1 {
        if calc.even(page_num) {
          align(left)[#emph(document.title)]
        } else {
          align(right)[#emph(hydra(1))]
        }
      }
    },
    footer: context align(center)[#counter(page).display("1", both: false)],
    columns: 1,
    margin: std-margin + margin,
  )

  // Настройки параграфов.
  set par(
    justify: true,
    leading: leading,
    first-line-indent: (amount: indent, all: true),
  )

  // Убираем переносы в заголовках документа.
  show title: set par(justify: false, leading: h-leading)
  show heading: set par(justify: false, leading: h-leading)

  // Отступы в списках
  set enum(indent: indent)
  set list(indent: indent)
  set terms(indent: indent, hanging-indent: -indent)

  // Делаем блочные матрицы более сжатыми по вертикали и разрешаем разрыв блока между страницами.
  show math.equation.where(block: true): set block(breakable: true)
  show math.equation.where(block: true): set par(leading: 0.75em)

  // Добавляем горизонтальное расстояние между колонками в матрицах.
  set math.mat(column-gap: 1em)

  // Делаем блоки сырого текста и таблицы более сжатыми по вертикали.
  show raw.where(block: true): set par(leading: 0.75em)
  show table: set par(leading: 0.75em)

  // Задаем шрифты.
  set text(lang: lang, size: size)
  show raw: set text(size: raw-size)

  set text(font: font) if font != none
  show raw: set text(font: mono-font) if mono-font != none
  show math.equation: set text(font: math-font) if math-font != none

  // Добавим вертикальный пробел после заголовков.
  show heading: it => { it + v(0.5em) }

  // Ссылки на уравнения в виде (1).
  // Данная функция предназначена для стандартных ссылок на формулы:
  // заменяет "Уравнение X" на "(X)".
  // https://typst.app/docs/reference/model/ref/
  show ref: it => {
    let el = it.element
    // Skip all other references.
    if el == none or el.func() != math.equation { return it }
    // Override equation references.
    link(el.location(), counter(math.equation).display(at: el.location()))
  }

  // То же самое, но для формул, нумерованных пакетом equate.
  // Это нужно делать специально, так как equate заново пересобирает все формулы,
  // в том числе и ссылки на них.
  // https://github.com/EpicEricEE/typst-equate/issues/11#issuecomment-2633709934
  set math.equation(supplement: none, numbering: (..nums) => numbering("(1)", ..nums))

  set cite(style: refstyle)

  // Применяем к документу функции из импортированных пакетов.
  show: par-indent
  show: equate.with(breakable: true, number-mode: "label")
  show: breathe

  // Размещаем заголовок документа.
  put-title()

  // Тело документа.
  doc
}
