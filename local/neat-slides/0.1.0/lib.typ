#import "@preview/touying:0.7.4": *

#let margins = (top: 4.5em, bottom: 1.5em, x: 1em, y: 1em)

// Базовая настройка слайдов.
#let slide(title: auto, ..args) = touying-slide-wrapper(self => {
  if title != auto {
    self.store.title = title
  }
  // set HEADER
  let header(self) = {
    show: pad.with(1em)
    set align(top + left)

    set text(fill: self.colors.primary, size: .7em)
    strong(utils.display-current-heading(level: 1))
    linebreak()

    set text(size: 1.5em)
    if self.store.title != none {
      strong(utils.call-or-display(self, self.store.title))
    } else {
      strong(utils.display-current-heading(level: 2))
    }
  }

  let footer(self) = {
    show: pad.with(.4em)
    set align(bottom + right)
    set text(fill: self.colors.neutral-darkest, size: .8em)
    context utils.slide-counter.display() + " / " + utils.last-slide-number
  }

  self = utils.merge-dicts(
    self,
    config-page(
      header: header,
      footer: footer,
    ),
  )
  touying-slide(self: self, ..args)
})

// Титульный слайд.
// Модифицированная версия титульного слайда из темы university.
#let title-slide(
  config: (:),
  extra: none,
  ..args,
) = touying-slide-wrapper(self => {
  self = utils.merge-dicts(
    self,
    config-common(freeze-slide-counter: true),
    config,
  )

  let info = self.info + args.named()

  info.authors = {
    let authors = if "authors" in info {
      info.authors
    } else {
      info.author
    }
    if type(authors) == array {
      authors
    } else {
      (authors,)
    }
  }
  info.authors = info.authors.map(
    author => if type(author) == array {
      author
    } else {
      (author,)
    },
  )

  let header(self) = {
    if info.logo != none {
      show: pad.with(1em)
      align(top)[#text(info.logo)]
    }
  }

  let body = {
    std.align(center + horizon)[
      #{
        block(
          height: 40%,
          inset: 0em,
          breakable: false,
          fill-height-with-text(text(size: 1.5em, fill: self.colors.primary, strong(info.title))),
        )

        block(
          inset: 0em,
          breakable: false,
          {
            if info.subtitle != none {
              parbreak()
              text(size: 1em, fill: self.colors.primary, info.subtitle)
            }
          },
        )

        v(1fr)

        if "authors" in info {
          text(fill: self.colors.neutral-darkest, size: .8em)[
            #stack(
              dir: ttb,
              spacing: 1em,
              ..info
                .authors
                .chunks(3)
                .map(author-chunk => grid(
                  columns: (1fr,) * author-chunk.len(),
                  column-gutter: 1em,
                  ..author-chunk.map(author => author.join(linebreak()))
                )),
            )
          ]
        }

        v(1fr)

        if info.contact != none {
          parbreak()
          text(size: .9em, info.contact)
        }

        if info.date != none {
          parbreak()
          text(size: .8em, utils.display-info-date(self))
        }
      }
    ]
  }

  self = utils.merge-dicts(
    self,
    config-page(header: header),
  )

  touying-slide(self: self, body)
})

// Основная функция темы.
#let neat-slides(
  aspect-ratio: "16-9",
  margins: margins,
  ..args,
  body,
) = {
  set text(size: 20pt)

  show: touying-slides.with(
    config-page(
      paper: "presentation-" + aspect-ratio,
      margin: margins,
    ),
    config-common(
      slide-fn: slide,
    ),
    config-methods(
      alert: utils.alert-with-primary-color,
    ),
    config-colors(
      primary: rgb("#A00F33"),
      secondary: rgb("#C81240"),
      neutral-darkest: rgb("#002b5b"),
    ),
    config-store(title: none),
    ..args,
  )

  body
}
