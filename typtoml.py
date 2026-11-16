import argparse
import os
import pathlib
import subprocess
import sys
import tempfile
from typing import Any

import tomlkit

parser = argparse.ArgumentParser(
    description="TOML to Typst to PDF converter",
    epilog="Use at your own risk!",
)

parser.add_argument("filename", help="TOML-файл со спецификациями лекций")
parser.add_argument(
    "-l",
    "--lecture",
    type=str,
    action="append",
    default=[],
    help="""
    Номер лекции, если нет желания пересобирать все.
    Если указать эту опцию несколько раз, то будут обработаны все указанные лекции.
    """,
)
parser.add_argument(
    "-p",
    "--path",
    type=pathlib.Path,
    default="./blocks",
    help="Папка, содержащая все составные части",
)
parser.add_argument(
    "-o",
    "--outpath",
    type=pathlib.Path,
    default=".",
    help="Папка для сохранения pdf-файла",
)
parser.add_argument(
    "-n",
    "--outname",
    type=str,
    default=None,
    help="Опциональное имя выходного файла",
)
parser.add_argument(
    "--skip",
    action="store_true",
    help="Пропускать отсутствующие файлы",
)

header = [
    '#import "@local/neat-document:0.1.0": *',
    '#import "@preview/theorion:0.6.0": *',
    '#import "@preview/tschich:0.2.0": *',
    "#show: neat-document.with(margin: tschich-var(210mm, 297mm, 1 / 10), leading: 1em, size: 12pt)",
    "#show: show-theorion",
]


def get_toml_content(fname: str) -> dict[str, Any]:
    try:
        with open(fname, "r", encoding="utf8") as f:
            content = "\n".join([l.strip("\n") for l in f])
            return tomlkit.loads(content)
    except FileNotFoundError:
        print("Не указан обязательный TOML-файл")
        sys.exit(1)


def get_block_content(fname: str, *, args, shift: int = 0) -> list[str]:
    res = []
    try:
        with open(fname, "r", encoding="utf8") as f:
            body = False
            for l in f:
                l = l.strip("\n")
                match l:
                    case "// BEGIN":
                        body = True
                        continue
                    case "// END":
                        body = False
                    case _:
                        if not body:
                            continue
                        if l.startswith("=") and (shift > 0):
                            l = "=" * shift + l
                        res.append(l)
    except FileNotFoundError:
        if not args.skip:
            print(f"Файл '{fname}' недоступен")
            sys.exit(1)
    return res


def get_blocks_recursive(blocks, *, args, shift: int = 0):
    res = []
    for block in blocks:
        if isinstance(block, str):
            if not block.endswith(".typ"):
                if shift == 0:
                    print("""
                            Заголовки на нулевом уровне не поддерживаются.
                            Если Вы хотите добавить заголовок вручную,
                            создайте вложенный список блоков.
                            """)
                    sys.exit(1)
                res.append(f"{'=' * shift} {block}")
            else:
                res += get_block_content(args.path / block, args=args, shift=shift)
        elif isinstance(block, list):
            res += get_blocks_recursive(block, args=args, shift=shift + 1)
        else:
            raise TypeError("Получен блок несовместимого типа")
    return res


def get_file_name(
    lect: int | str | None,
    specs: dict[str, Any],
    args: argparse.Namespace,
) -> tuple[str, str]:
    key = f"Lecture-{lect}"
    newname = (
        specs.get(key, {}).get("name", "") if args.outname is None else args.outname
    )
    return key, f"Лекция {lecture}. {newname}".strip(". ")


def get_new_file(
    spec: dict,
    args: argparse.Namespace,
) -> list[str]:
    newfile = []

    if "name" in spec:
        newfile.append("#set document(title: [" + spec["name"] + "])")

    newfile += header

    newfile += get_blocks_recursive(spec.get("blocks", []), args=args)

    if "bibliography" in spec:
        newfile.append('#bibliography("' + spec["bibliography"] + '")')

    if "appendix" in spec:
        newfile.append("#show: appendix\n")
        newfile += get_blocks_recursive(spec.get("appendix", []), args=args)

    return newfile


if __name__ == "__main__":
    args = parser.parse_args()

    specs = get_toml_content(args.filename)

    if args.outpath != ".":
        os.makedirs(args.outpath, exist_ok=True)

    lectures = (
        args.lecture
        if args.lecture != []
        else [k.replace("Lecture-", "") for k in specs]
    )

    for lecture in lectures:
        key, newname = get_file_name(lecture, specs, args)
        if key not in specs:
            continue
        print(f" => {newname}: ", end="")
        newfile = get_new_file(specs.get(key, {}), args)

        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf8",
            suffix=".typ",
            dir=args.path,
        ) as tmp_file:
            tmp_file.writelines("\n".join(newfile))
            tmp_file.flush()

            tmp_path = tmp_file.name

            result = subprocess.run(
                [
                    "typst",
                    "c",
                    tmp_path,
                    str(args.outpath / f"{newname}.pdf"),
                ],
                check=False,
                capture_output=True,
            )

        if not result.returncode:
            print("OK")
        else:
            print("FAILED")
            with open(
                args.outpath / f"{newname}.log",
                mode="w",
                encoding="utf8",
            ) as log_file:
                log_file.write(result.stderr.decode("utf8"))

        try:
            os.unlink(tmp_path)
        except FileNotFoundError:
            pass
