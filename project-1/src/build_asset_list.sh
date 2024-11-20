#!/bin/bash

bash -c "pandoc -o asset_list.pdf -f markdown+rebase_relative_paths <( echo -e '# PROJECT NAME {.title}\n\n# Externally sourced assets\n\n' )  $(find . -iname 'asset_source.md' -printf '<( echo -e "\n\n\n## %h \n\n\n" )  "%p" ')"
