defmodule WorthAsking.Notifications.Worker do
  @moduledoc """
  GenServer that handles scheduled notification waves.
  Uses Process.send_after for timed escalation.
  """

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Schedule a wave to be sent after `delay_ms` milliseconds.
  """
  def schedule_wave(question_id, wave_number, contributor_ids, delay_ms) do
    GenServer.cast(__MODULE__, {:schedule, question_id, wave_number, contributor_ids, delay_ms})
  end

  # Server callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:schedule, question_id, wave_number, contributor_ids, delay_ms}, state) do
    ref = make_ref()
    Process.send_after(self(), {:send_wave, ref, question_id, wave_number, contributor_ids}, delay_ms)
    {:noreply, Map.put(state, ref, {question_id, wave_number})}
  end

  @impl true
  def handle_info({:send_wave, ref, question_id, wave_number, contributor_ids}, state) do
    Task.start(fn ->
      WorthAsking.Notifications.execute_wave(question_id, wave_number, contributor_ids)
    end)

    {:noreply, Map.delete(state, ref)}
  end
end
