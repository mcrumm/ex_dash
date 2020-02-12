defmodule ExDash do
  @moduledoc """
  ExDash provides a `Formatter` and mix task for converting your elixir project into a Dash docset.

  """

  alias ExDash.{Injector, Docset, Store}

  @doc """
  A run function that is called by ExDoc.

  """
  @spec run(list, ExDoc.Config.t()) :: {list, ExDoc.Config.t()}
  def run(project_nodes, config) when is_map(config) do
    name = Store.get(:name)

    config =
      cond do
        not is_nil(name) ->
          %{config | project: name}

        config.project == "" ->
          %{config | project: default_umbrella_project_name()}

        true ->
          config
      end

    {config, docset_root_path} = Docset.build(project_nodes, config)

    ExDoc.Formatter.HTML.run(project_nodes, config)

    transform_ex_docs_to_dash_docs(config.output)

    docset_root_path
  end

  defp transform_ex_docs_to_dash_docs(output_docs_dir, ends_with \\ ".html") do
    File.ls!(output_docs_dir)
    |> Stream.filter(&String.ends_with?(&1, ends_with))
    |> Stream.map(&Path.join(output_docs_dir, &1))
    |> Enum.map(&Injector.inject_all/1)
  end

  defp default_umbrella_project_name() do
    File.cwd!() |> Path.basename()
  end
end
