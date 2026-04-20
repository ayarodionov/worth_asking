defmodule WorthAsking.Categories do
  @moduledoc """
  Single source of truth for all categories in Worth Asking.
  Used by both user question submission and contributor onboarding/matching.
  """

  @categories [
    %{
      id: :dating_attraction,
      label: "Dating & Attraction",
      description: "Early-stage interest, first impressions, attraction, approaching women"
    },
    %{
      id: :relationships,
      label: "Relationships",
      description: "Ongoing romantic relationships, emotional dynamics, conflict"
    },
    %{
      id: :marriage_long_term,
      label: "Marriage & Long-Term",
      description: "Long-term commitment, marriage dynamics, deeper relationship patterns"
    },
    %{
      id: :sex_intimacy,
      label: "Sex & Intimacy",
      description: "Sexual behavior, desire, performance, physical connection"
    },
    %{
      id: :communication,
      label: "Communication",
      description: "Texting, tone, mixed signals, misunderstandings"
    },
    %{
      id: :social_situational,
      label: "Social & Situational",
      description: "Gift giving, date ideas, social behavior, what's appropriate in situations"
    },
    %{
      id: :work_professional,
      label: "Work & Professional",
      description: "Interactions with female colleagues, workplace dynamics, boundaries"
    },
    %{
      id: :appearance_lifestyle,
      label: "Appearance & Lifestyle",
      description: "Style, grooming, presentation, home/environment"
    },
    %{
      id: :general,
      label: "General",
      description: "For questions that don't clearly fit a category or span multiple areas"
    }
  ]

  @ids Enum.map(@categories, & &1.id)

  @doc "All category definitions as maps with :id, :label, :description."
  def all, do: @categories

  @doc "List of all category IDs (atoms)."
  def ids, do: @ids

  @doc "All category IDs plus legacy values for Ecto.Enum compatibility."
  def enum_values do
    @ids ++ [:dating, :relationships_legacy, :appearance, :work, :social_situations,
             :breakups, :first_impressions, :style, :dating_dynamics]
  end

  @doc "Get the display label for a category ID."
  def label(id) do
    case Enum.find(@categories, &(&1.id == id)) do
      %{label: label} -> label
      nil -> id |> to_string() |> String.replace("_", " ") |> String.split(" ") |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
    end
  end

  @doc "Get the description for a category ID."
  def description(id) do
    case Enum.find(@categories, &(&1.id == id)) do
      %{description: desc} -> desc
      nil -> ""
    end
  end

  @doc """
  Returns true if a contributor's categories match a question's category.
  For "general" questions, matches contributors who selected :general
  or who have 3+ categories selected (broad contributors).
  """
  def matches?(contributor_categories, :general) do
    :general in contributor_categories or length(contributor_categories) >= 3
  end

  def matches?(contributor_categories, question_category) do
    question_category in contributor_categories
  end
end
