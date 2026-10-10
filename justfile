# ikigai-emacs local gates.
#
# `just gates` runs exactly what .github/workflows/ci.yml runs, in the same order:
# byte-compile the package, then the ERT suite in batch. just stops at the first
# failing line, so a byte-compile error never reaches the tests and the recipe's
# exit status is the failing command's own.
#
# The devtools gates (`just -f ~/git-personal/ikigai-devtools/justfile gates`) find
# this recipe because the repo has no Cargo.toml, and run it with a full log and a
# real exit status. Do not call those gates from here: they refuse to loop.
#
# ⚠ ci.yml does NOT call this recipe: `just` is not installed on GitHub's
# ubuntu-latest image, and adding a third-party action to install it would put a new
# dependency in CI to save two commands. So the commands live in BOTH places, and a
# change to one is a change to the other. The devtools gates do not compare them.

# Byte-compile ikigai.el, then run the ERT suite (mirrors ci.yml).
gates: byte-compile ert

# Byte-compile the package: catches undefined functions, bad forms, and a variable that shadows a macro.
byte-compile:
    emacs -Q --batch \
      --eval "(require 'org)" \
      --eval "(require 'org-element)" \
      -f batch-byte-compile ikigai.el

# Run the ERT suite in batch (no kernel: the tests stub `ikigai-eval`).
ert:
    emacs -Q --batch -L . \
      -l test/ikigai-test.el \
      -f ert-run-tests-batch-and-exit
