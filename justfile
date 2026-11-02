jupyter:
    uv run jupyter lab

ipython:
    uv run ipython

build file src='Семинары' tgt='Семинары/pdf' aux='.ipynb':
  #!git-bash.exe
  cat > /tmp/ju2pdf.py <<FIN
  import sys
  import tempfile
  fname = sys.argv[1]
  outdir = sys.argv[2]
  with open(f"{tempfile.gettempdir()}/ju2pdf.typ", "r", encoding="utf8") as f:
      lines = f.readlines()
  with open(f"{outdir}/{fname}.typ", "w", encoding="utf8") as f:
      f.writelines(line.replace("<DUMMY>", fname) for line in lines)
  FIN

  cat > /tmp/ju2pdf.typ <<FIN
  #import "@preview/callisto:0.3.0"
  #import "@local/callisto-unmargin:0.1.0": unmargin-theme
  #import "@preview/tschich:0.2.0": *
  #import "@local/neat-document:0.1.0": neat-document
  #import "@local/trinkets:0.1.0": *
  #set document(title: [<DUMMY>])
  #show: neat-document.with(lang: "ru", margin: tschich-var(210mm, 297mm, 1 / 12))
  #show: trinkets
  #let (render, Cell, In, Out) = callisto.config(
    nb: path("<DUMMY>.ipynb"),
    handlers: (path: (x, ..args) => path(x)),
    theme: unmargin-theme,
  )
  #render()
  FIN

  echo "{{tgt}}"
  echo "{{src}}"
  echo "{{aux}}"
  if [[ ! -d "{{tgt}}" ]]; then mkdir "{{tgt}}"; fi
  if [[ ! -d "{{src}}" ]]; then mkdir "{{src}}"; fi
  if [[ ! -d "{{aux}}" ]]; then mkdir "{{aux}}"; fi
  if [[ ! "{{aux}}" == "{{src}}" ]]; then
  	if [[ ! -e {{aux}}/.pics ]]; then cp -r "{{src}}/.pics" "{{aux}}"; fi
  fi

  uv run jupyter nbconvert --execute --allow-errors --to notebook --output-dir="{{aux}}" "{{src}}/{{file}}.ipynb"

  cp /tmp/ju2pdf.typ "{{aux}}/{{file}}.typ"
  py /tmp/ju2pdf.py "{{file}}" "{{aux}}"

  typst c "{{aux}}/{{file}}.typ" "{{tgt}}/{{file}}.pdf"
