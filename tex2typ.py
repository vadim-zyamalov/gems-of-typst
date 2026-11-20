import argparse
import pathlib
import re
import subprocess
import sys

parser = argparse.ArgumentParser(
    description="Обертка вокруг Tylax",
    epilog="Use at your own risk!",
)
parser.add_argument(
    "filename",
    help="Исходник в LaTeX",
    type=pathlib.Path,
)
parser.add_argument(
    "-r",
    "--regex",
    type=pathlib.Path,
    default=None,
    help="""
    Опциональный файл, содержащий пары паттерн-замена.
    Одна строка - одна пара, разделенная знаком табуляции.
    """,
)
parser.add_argument(
    "--replace",
    action="store_true",
    help="Заменить список паттернов вместо дополнения",
)
parser.add_argument(
    "-o",
    "--output",
    type=pathlib.Path,
    default=None,
    help="""
    Путь и имя итогового файла.
    Если не задано, то используется имя исходного файла.
    """,
)
parser.add_argument(
    "--tylax",
    type=pathlib.Path,
    default="t2l",
    help="Путь к бинарнику Tylax",
)


patterns = [
    # Убираем лишние скобки
    (r"(\^|_)\(([0-9A-Za-z])\)(?=( |\^|_|\)|\]|\}|,|\$))", r"\1\2"),
    (r"(\^|_)\(([0-9A-Za-z])\)(?=(\(|\(|\{)|[A-Za-z0-9]|\+|\-|=)", r"\1\2 "),
    # Исправляем положение апострофа
    (r" '", r"^prime "),
    (r"'_", r"^prime_"),
    (r"'", r"^prime "),
    # Функция векторизации
    (r"Vect([A-Za-z0-9]+)", r"vv(\1)"),
    # Коррекция какого-то par
    (r"par([A-Za-z])(_|\^)", r"\1\2"),
    (r"par([A-Za-z]{2,})", r'italic("\1")'),
    (r'italic\("tial(.*?)"\)', r"partial \1"),
    # Коррекция многобуквенных переменных
    (r"(([A-Z] )+[A-Z])", r'italic("\1")'),
    # Удаление лишнего пробела
    (r"^ \$", r"$"),
    # ref -> @
    # cite -> @
    (r"\(#ref\(<(.*?)>\)\)", r"@\1"),
    (r"\(#cite\(<(.*?)>\)\)", r"@\1"),
    (r"#ref\(<(.*?)>\)", r"@\1"),
    (r"#cite\(<(.*?)>\)", r"@\1"),
    # Кавычки
    (r"«[ ]*(.*?)[ ]*»", r'"\1"', re.MULTILINE),
    # Минус после закрывающей скобки
    (r"\)(-|\+|=)", r") \1"),
    (r"(\)|\]|\})(?!(\)|\]|\}|\$|_|\^|,|\.|;|'))[ ]*", r"\1 "),
    # Перенос строки по точке
    (r"([А-Яа-я])\. ", r"\1.\n"),
    (r"^(=+ .*)$", r"\n\1\n"),
]


if __name__ == "__main__":
    args = parser.parse_args()

    if args.regex is not None:
        with open(args.regex, "r", encoding="utf8") as f:
            new_patterns = [tuple(l.strip().split("\t")) for l in f if l.strip() != ""]
        if args.replace:
            patterns = new_patterns
        else:
            patterns += new_patterns

    f_in = args.filename

    f_out = args.output
    if f_out is None:
        f_out = f_in.with_suffix(".typ")

    result = subprocess.run(
        [
            "t2l",
            f_in.name,
            "-o",
            f_out.name,
        ],
        check=False,
        capture_output=True,
    )

    if result.returncode:
        with open(
            f_in.with_suffix(".log"),
            mode="w",
            encoding="utf8",
        ) as log_file:
            log_file.write(result.stderr.decode("utf8"))
        sys.exit(1)

    lines = []
    with open(f_out, "r", encoding="utf8") as f:
        for line in f:
            if line.strip() == "":
                continue
            for pat, repl, *flags in patterns:
                flg = 0
                for flag in flags:
                    flg |= flag
                line = re.sub(pat, repl, line, flags=flg)
            lines.append(line)

    with open(f_out, "w", encoding="utf8") as f:
        f.writelines(lines)
