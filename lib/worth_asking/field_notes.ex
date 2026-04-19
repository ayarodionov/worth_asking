defmodule WorthAsking.FieldNotes do
  @moduledoc """
  Loads and queries Field Notes from a JSON file.

  ## Adding new Field Notes

  Edit `priv/field_notes.json` and add a new object with these fields:

      {
        "id": "6",
        "slug": "your-slug-here",
        "title": "Your Title",
        "situation": "Describe the scenario...",
        "insight": "Explain the perspective...",
        "quick_reference": ["Bullet one", "Bullet two"],
        "tags": ["tag1", "tag2"],
        "is_premium": false
      }

  Restart the server to pick up new entries.
  """

  @notes_path Application.app_dir(:worth_asking, "priv/field_notes.json")

  defstruct [:id, :slug, :title, :situation, :insight, :quick_reference, :tags, :is_premium]

  @doc "Load all field notes."
  def list_all do
    load()
  end

  @doc "List field notes, optionally filtered by tag."
  def list(tag \\ nil) do
    notes = load()

    if tag && tag != "" do
      Enum.filter(notes, fn note -> tag in note.tags end)
    else
      notes
    end
  end

  @doc "Get a single field note by slug."
  def get_by_slug(slug) do
    Enum.find(load(), fn note -> note.slug == slug end)
  end

  @doc "Get all unique tags across all field notes."
  def all_tags do
    load()
    |> Enum.flat_map(& &1.tags)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc "Find related notes by shared tags, excluding the given slug."
  def related(slug, limit \\ 3) do
    case get_by_slug(slug) do
      nil ->
        []

      note ->
        load()
        |> Enum.reject(&(&1.slug == slug))
        |> Enum.map(fn other ->
          shared = length(note.tags -- note.tags -- other.tags)
          {shared, other}
        end)
        |> Enum.filter(fn {shared, _} -> shared > 0 end)
        |> Enum.sort_by(fn {shared, _} -> -shared end)
        |> Enum.take(limit)
        |> Enum.map(fn {_, other} -> other end)
    end
  end

  defp load do
    path =
      if File.exists?(@notes_path) do
        @notes_path
      else
        Path.join(:code.priv_dir(:worth_asking), "field_notes.json")
      end

    path
    |> File.read!()
    |> Jason.decode!()
    |> Enum.map(&to_struct/1)
  end

  defp to_struct(map) do
    %__MODULE__{
      id: map["id"],
      slug: map["slug"],
      title: map["title"],
      situation: map["situation"],
      insight: map["insight"],
      quick_reference: map["quick_reference"] || [],
      tags: map["tags"] || [],
      is_premium: map["is_premium"] || false
    }
  end
end
