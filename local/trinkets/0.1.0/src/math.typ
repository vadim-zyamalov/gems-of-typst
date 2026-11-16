#import "@preview/zero:0.7.1": *

#let Ex = math.op([E])
#let Var = math.op([Var])
#let SE = math.op([SE])
#let Cov = math.op([Cov])
#let Corr = math.op([Corr])
#let Pr = math.op([P])
#let plim = math.op([plim], limits: true)
#let rank = math.op([rank])
#let Vect = el => math.bold(math.upright(el))
#let vv = Vect
#let vert = math.mid(sym.bar.v)

#let TSS = math.italic([TSS])
#let ESS = math.italic([ESS])
#let SSR = math.italic([SSR])
#let RSS = SSR

#let pm = sym.plus.minus
#let neq = sym.eq.not
#let ge = sym.gt.eq.slant
#let le = sym.lt.eq.slant
#let bigast = scale(150%)[$ast.op$]
#let nonumber = none
#let sim = sym.tilde.op

#let Re = math.op([Re])
#let Im = math.op([Im])

#let trinkets = doc => {
  set-num(decimal-separator: ",")
  show sym.lt.eq: sym.lt.eq.slant
  show sym.gt.eq: sym.gt.eq.slant
  show math.equation: it => {
    show regex("\d+(\.|,)\d+"): number => num[#number]
    it
  }

  doc
}
