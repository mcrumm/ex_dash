defmodule ExDash.Injector.Function do
  @moduledoc """
  An Injector for identifying Elixir type specs and injecting Function anchors into ExDoc-generated files.

  """

  alias Floki
  alias ExDash.Injector

  @behaviour Injector

  @doc """
  find_ids/1 returns all Elixir functions found in the passed HTML.

  """
  @spec find_ids(Injector.html_content()) :: [Injector.id()]
  def find_ids(html_content) do
    list_selector = ".details-list#functions .detail"

    id_parser = &Floki.attribute(&1, "id")

    with {:ok, parsed_content} <- Floki.parse_document(html_content),
         functions when functions != [] <- Floki.find(parsed_content, list_selector) do
      functions
      |> Stream.reject(&has_macro_note/1)
      |> Enum.map(&id_parser.(&1))
      |> Enum.flat_map(& &1)
    else
      _ ->
        []
    end
  end

  @spec has_macro_note(Injector.html_content()) :: boolean
  defp has_macro_note(detail) do
    note_text =
      Floki.find(detail, ".detail-header span.note")
      |> Floki.text()

    String.contains?(note_text, "macro")
  end

  @doc """
  match_and_anchor/1 returns a matching string and injectable anchor string for the passed id.

  """
  @spec match_and_anchor(Injector.id()) :: {match :: String.t(), replacement :: String.t()}
  def match_and_anchor(id) do
    escaped_id = id |> URI.encode_www_form()

    match_string = "<a href=\"##{id}\" class=\"detail-link\""

    dash_anchor_label = "Function"

    replacement_string = """
      <a name="//apple_ref/#{dash_anchor_label}/#{escaped_id}" class="dashAnchor"></a>
      #{match_string}
    """

    {match_string, replacement_string}
  end
end
