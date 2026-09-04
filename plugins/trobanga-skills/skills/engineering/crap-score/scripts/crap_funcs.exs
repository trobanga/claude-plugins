# Reports one JSON line per Elixir function clause: the file, the name,
# the first and the last line, and the cyclomatic complexity.
#
# It reads the file paths from standard input, one per line, and needs
# only the Elixir standard library, no project dependency.
#
#     printf 'lib/a.ex\nlib/b.ex\n' | elixir crap_funcs.exs
#
# One record per `def`, `defp`, `defmacro` or `defmacrop` clause. A
# function with several clauses gets `Mod.name/arity#n`, with n the index
# of the clause; a function with one clause gets `Mod.name/arity`.
#
# Decisions that raise the complexity above one: `if` and `unless`, each
# `case`, `cond`, `receive`, `try` and `with ... else` arm except a final
# catch-all, each `<-` step of a `with`, each `rescue`, `catch` and `after`
# of a `try`, each filter of a `for`, `&&`, `||`, `and` and `or`, and a
# guard on the clause head plus every `and`, `or` and `when` inside it.
# An anonymous `fn` keeps no record of its own; each of its clauses after
# the first and each decision in its body raise the complexity of the
# function around it.

defmodule CrapFuncs do
  @defs [:def, :defp, :defmacro, :defmacrop]

  def main do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Enum.each(&file/1)
  end

  defp file(path) do
    source = File.read!(path)

    case Code.string_to_quoted(source, token_metadata: true, columns: true) do
      {:ok, ast} ->
        ast
        |> walk(nil, [])
        |> Enum.reverse()
        |> number_clauses()
        |> Enum.each(fn r -> IO.puts(encode(Map.put(r, :file, path))) end)

      {:error, {meta, message, token}} ->
        IO.puts(:stderr, "crap_funcs: #{path}:#{meta[:line]}: #{message}#{token}")
        System.halt(1)
    end
  end

  # -- walk: find the modules and the function clauses --------------------

  defp walk({:defmodule, _, [alias, [do: body]]}, module, acc) do
    walk(body, join(module, alias_name(alias)), acc)
  end

  defp walk({:quote, _, _}, _module, acc), do: acc

  defp walk({op, meta, [head | rest]} = node, module, acc) when op in @defs do
    {name, arity, guards} = signature(head)
    body = case rest do
      [body] -> body
      _ -> []
    end

    record = %{
      name: "#{module || "?"}.#{name}/#{arity}",
      start: meta[:line],
      end: last_line(meta, node),
      cc: 1 + decisions(body) + guard_decisions(guards)
    }

    [record | acc]
  end

  defp walk({_, _, args}, module, acc) when is_list(args) do
    Enum.reduce(args, acc, &walk(&1, module, &2))
  end

  defp walk({a, b}, module, acc), do: walk(b, module, walk(a, module, acc))
  defp walk(list, module, acc) when is_list(list) do
    Enum.reduce(list, acc, &walk(&1, module, &2))
  end
  defp walk(_, _, acc), do: acc

  defp join(nil, name), do: name
  defp join(module, name), do: module <> "." <> name

  defp alias_name({:__aliases__, _, parts}), do: Enum.map_join(parts, ".", &to_string/1)
  defp alias_name(other), do: Macro.to_string(other)

  defp signature({:when, _, [call | guards]}) do
    {name, arity, _} = signature(call)
    {name, arity, guards}
  end
  defp signature({name, _, args}) when is_list(args), do: {name, length(args), []}
  defp signature({name, _, _}), do: {name, 0, []}

  # `def f(x), do: y` has no `end` token, so the clause ends on the last
  # line any of its tokens sits on.
  defp last_line(meta, node) do
    explicit = get_in(meta, [:end, :line])
    {_, deepest} = Macro.prewalk(node, meta[:line], fn
      {_, m, _} = n, max when is_list(m) ->
        {n, Enum.max([max, m[:line] || 0, get_in(m, [:end, :line]) || 0,
                      get_in(m, [:closing, :line]) || 0])}
      n, max -> {n, max}
    end)
    max(explicit || 0, deepest)
  end

  defp number_clauses(records) do
    counts = Enum.frequencies_by(records, & &1.name)
    {numbered, _} =
      Enum.map_reduce(records, %{}, fn r, seen ->
        if counts[r.name] > 1 do
          n = Map.get(seen, r.name, 0) + 1
          {%{r | name: "#{r.name}##{n}"}, Map.put(seen, r.name, n)}
        else
          {r, seen}
        end
      end)
    numbered
  end

  # -- decisions ----------------------------------------------------------

  defp guard_decisions([]), do: 0
  defp guard_decisions(guards) do
    {_, n} = Macro.prewalk(guards, 0, fn
      {op, _, _} = node, n when op in [:and, :or, :when] -> {node, n + 1}
      node, n -> {node, n}
    end)
    1 + n
  end

  defp decisions(body) do
    {_, n} = Macro.prewalk(body, 0, fn node, n -> {node, n + decision(node)} end)
    n
  end

  defp decision({op, _, _}) when op in [:if, :unless, :&&, :||, :and, :or], do: 1

  defp decision({op, _, [_, blocks]}) when op in [:case, :receive] and is_list(blocks) do
    arms(blocks[:do]) + arms(blocks[:after])
  end

  defp decision({:cond, _, [blocks]}) when is_list(blocks), do: arms(blocks[:do])

  defp decision({:with, _, args}) do
    {blocks, steps} = List.pop_at(args, -1)
    arms_of_with = if Keyword.keyword?(blocks), do: arms(blocks[:else]), else: 0
    Enum.count(steps, &match?({:<-, _, _}, &1)) + arms_of_with
  end

  defp decision({:try, _, [blocks]}) when is_list(blocks) do
    arms(blocks[:rescue]) + arms(blocks[:catch]) + arms(blocks[:else]) +
      if(blocks[:after], do: 1, else: 0)
  end

  defp decision({:for, _, args}) do
    {blocks, steps} = List.pop_at(args, -1)
    steps = if Keyword.keyword?(blocks), do: steps, else: args
    Enum.count(steps, fn s -> not match?({:<-, _, _}, s) and not match?({:<<>>, _, _}, s) end)
  end

  # every clause of an anonymous function after the first is one decision
  defp decision({:fn, _, clauses}) when is_list(clauses), do: length(clauses) - 1

  defp decision(_), do: 0

  # arms of a case-like block: each arm is one decision, except a final
  # catch-all (`_` or `true`)
  defp arms(nil), do: 0
  defp arms(clauses) when is_list(clauses) do
    n = length(clauses)
    if n > 0 and catch_all?(List.last(clauses)), do: n - 1, else: n
  end
  defp arms(_), do: 0

  defp catch_all?({:->, _, [[{:_, _, _}], _]}), do: true
  defp catch_all?({:->, _, [[true], _]}), do: true
  defp catch_all?(_), do: false

  # -- JSON, without a dependency -----------------------------------------

  defp encode(r) do
    ~s({"file": #{string(r.file)}, "name": #{string(r.name)}, ) <>
      ~s("start": #{r.start}, "end": #{r.end}, "cc": #{r.cc}})
  end

  defp string(s) do
    escaped = s |> String.replace("\\", "\\\\") |> String.replace("\"", "\\\"")
    "\"#{escaped}\""
  end
end

CrapFuncs.main()
