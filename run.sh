#!/bin/bash
# Helper script for LaTeX, aim to have same functionality as GUI.
# Author: Kevin Cyu, kevinbird61@gmail.com, P76064570@mail.ncku.edu.tw
#
# Usage:
# ./run.sh {i16 | i18 | compile | clean | diff [ref]}
#   - i16:          installation for ubuntu 16.04 LTS.
#   - i18:          installation for ubuntu 18.04 LTS.
#   - compile:      using pdflatex & bibtex to compile your tex file.
#   - clean:        clean all temp files.
#   - diff [ref]:   generate tracked-changes PDF vs a git commit (default: HEAD~1).

function install_16()
{
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    # 16.04
    echo "deb http://miktex.org/download/ubuntu xenial universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get update
    sudo apt-get install miktex
}

function install_18()
{
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys D6BC243565B2087BC3F897C9277A7293F59E4889
    # 18.04
    echo "deb http://miktex.org/download/ubuntu bionic universe" | sudo tee /etc/apt/sources.list.d/miktex.list
    sudo apt-get update
    sudo apt-get install miktex
}

function compile()
{
    # same function as "pdflatex + MakeIndex + Bibtex"
    # run first time (will generate main.aux for next step)
    pdflatex main.tex
    # run bibtex for database
    bibtex main.aux
    # run second time
    pdflatex main.tex
}

function clean()
{
    rm -rf *.aux *.bbl *.blg *.lof *.log *.lot *.out *.toc
    rm -f diff_main.tex diff_main.pdf
}

function diff_pdf()
{
    local ref=${2:-HEAD~1}
    local output="diff_main"

    if ! command -v latexdiff-vc &> /dev/null; then
        echo "Error: latexdiff-vc not found. Install with: sudo apt install latexdiff"
        exit 1
    fi

    echo "Generating diff against: $ref"
    latexdiff-vc --git --flatten --encoding=utf8 --type=CFONT -r "$ref" main.tex

    local generated
    generated=$(ls main-diff*.tex 2>/dev/null | head -1)
    if [ -z "$generated" ]; then
        echo "Error: latexdiff-vc failed to generate diff file."
        exit 1
    fi

    mv "$generated" "${output}.tex"
    echo "Compiling ${output}.tex ..."

    pdflatex "${output}.tex"
    bibtex "${output}.aux"
    pdflatex "${output}.tex"
    pdflatex "${output}.tex"

    echo "Done! Output: ${output}.pdf"
}

if [ $# -eq 0 ]; then
    echo "Usage: ./$(basename $0) {i16 | i18 | compile | clean | diff [ref]}"
    echo "  ./$(basename $0) i16:         installation for ubuntu 16.04 LTS."
    echo "  ./$(basename $0) i18:         installation for ubuntu 18.04 LTS."
    echo "  ./$(basename $0) compile:     using pdflatex & bibtex to compile your tex file."
    echo "  ./$(basename $0) clean:       clean all temp files."
    echo "  ./$(basename $0) diff [ref]:  generate tracked-changes PDF vs a git commit (default: HEAD~1)."
    exit
fi

if [ "$1" == "i16" ]; then
    install_16
    exit
elif [ "$1" == "i18" ]; then
    install_18
    exit
elif [ "$1" == "compile" ]; then
    compile
    exit
elif [ "$1" == "clean" ]; then
    clean
    exit
elif [ "$1" == "diff" ]; then
    diff_pdf "$@"
    exit
fi

echo "Unknown command: $1"
echo "Run ./$(basename $0) for usage."
exit 1