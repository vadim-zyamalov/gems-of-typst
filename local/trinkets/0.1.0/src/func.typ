// Функция для автоматического выбора размера текста такого,
// что соответствующий элемент будет вписываться по ширине в страницу/слайд.
// See https://forum.typst.app/t/how-to-auto-size-text-and-images/1290/3
#let fill-height-with-text(min: 0.3em, max: 5em, eps: 0.1em, it) = layout(size => {
  let fits(text-size, it) = {
    (
      measure(width: size.width, {
        set text(text-size)
        it
      }).height
        <= size.height
    )
  }

  if not fits(min, it) { panic("Content doesn't fit even at minimum text size") }
  if fits(max, it) {
    set text(max)
    it
  }

  let (a, b) = (min, max)
  while b - a > eps {
    let new = 0.5 * (a + b)
    if fits(new, it) {
      a = new
    } else {
      b = new
    }
  }

  set text(a)
  it
})

#let fill-width-with-text(min: 0.3em, max: 5em, eps: 0.1em, it) = layout(size => {
  let fits(text-size, it) = {
    (
      measure(height: size.height, {
        set text(text-size)
        it
      }).width
        <= size.width
    )
  }

  if not fits(min, it) { panic("Content doesn't fit even at minimum text size") }
  if fits(max, it) {
    set text(max)
    it
  }

  let (a, b) = (min, max)
  while b - a > eps {
    let new = 0.5 * (a + b)
    if fits(new, it) {
      a = new
    } else {
      b = new
    }
  }

  set text(a)
  it
})

// Данный код позволяет игнорировать underbrace при определении высоты скобок
// https://forum.typst.app/t/how-to-recreate-latex-smash-and-vphantom-in-typst-math/8413/3
// Значение параметра `delim` должно быть преваряться #, дабы typst не интерпретировал его как часть формулы,
// ибо это за него будем делать мы.
#let autolr(eq, delim: ("(", ")")) = context {
  let ld = symbol(delim.at(0))
  let rd = symbol(delim.at(1))
  let wh = none
  {
    show math.underbrace: it => it.body
    show math.overbrace: it => it.body
    wh = measure(eq)
  }
  math.lr(size: wh.height, $ld eq rd$)
}

// Данная функция оборачивает печатную (блочную) функцию в нумеруемый блок.
// Это нужно чтобы:
// а) чтобы ссылки на формулы работали (в typst ссылки без номера не работают),
// б) чтобы можно было нумеровать конкретные формулы.
#let eqnum(eq, numbering: "(1)") = math.equation(
  block: true,
  numbering: numbering,
  eq,
)

#let to-string(it) = {
  if type(it) == str {
    it
  } else if type(it) != content {
    str(it)
  } else if it.has("text") {
    it.text
  } else if it.has("children") {
    it.children.map(to-string).join()
  } else if it.has("body") {
    to-string(it.body)
  } else if it == [ ] {
    " "
  }
}
