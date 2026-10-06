#!/usr/bin/env bash
# Builds a Mix project without ExCoveralls: main is origin/main, the branch
# "feature" adds Calc.safe_div/2, whose error branch no test reaches.
set -euo pipefail

g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }

git init -q -b main .
printf '_build/\ndeps/\ncover/\n' > .gitignore

cat > mix.exs <<'EOF'
defmodule Calc.MixProject do
  use Mix.Project

  def project do
    [
      app: :calc,
      version: "0.1.0",
      elixir: "~> 1.15",
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps, do: []
end
EOF

mkdir -p lib test

cat > lib/calc.ex <<'EOF'
defmodule Calc do
  @moduledoc "Small arithmetic helpers."

  def add(a, b), do: a + b
end
EOF

cat > test/test_helper.exs <<'EOF'
ExUnit.start()
EOF

cat > test/calc_test.exs <<'EOF'
defmodule CalcTest do
  use ExUnit.Case

  test "add/2 adds" do
    assert Calc.add(2, 3) == 5
  end
end
EOF

g add -A
g commit -q -m "Calc"
git update-ref refs/remotes/origin/main HEAD
git checkout -q -b feature

cat > lib/calc.ex <<'EOF'
defmodule Calc do
  @moduledoc "Small arithmetic helpers."

  def add(a, b), do: a + b

  def safe_div(_a, 0), do: {:error, :division_by_zero}

  def safe_div(a, b) do
    if rem(a, b) == 0 do
      {:ok, div(a, b)}
    else
      {:ok, a / b}
    end
  end
end
EOF

cat > test/calc_test.exs <<'EOF'
defmodule CalcTest do
  use ExUnit.Case

  test "add/2 adds" do
    assert Calc.add(2, 3) == 5
  end

  test "safe_div/2 divides evenly" do
    assert Calc.safe_div(6, 3) == {:ok, 2}
  end
end
EOF

g add -A
g commit -q -m "Add safe_div/2"
