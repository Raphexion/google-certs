defmodule GoogleCerts.CertificateCache do
  @moduledoc """
  GenServer that keeps track of the certificates
  """
  use GenServer

  require Logger

  alias GoogleCerts.Certificates

  @default_name __MODULE__
  @refresh_ms :timer.hours(1)
  @goolge_api_version 3

  @spec get(GenServer.server()) :: GoogleCerts.Certificates.t()
  def get(server \\ @default_name) do
    GenServer.call(server, :get)
  end

  def start_link(options, genserver_options) do
    GenServer.start_link(__MODULE__, options, genserver_options)
  end

  def child_spec(args \\ []) do
    options = Keyword.get(args, :options, [])
    genserver_options = Keyword.get(args, :genserver_options, name: @default_name)

    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [options, genserver_options]},
      type: :worker
    }
  end

  @impl true
  def init(_) do
    if fetch_on_start?() do
      Logger.info("fetching certifcates on start")
      Process.send_after(self(), :refresh, @refresh_ms, [])
      {:ok, :no_state, {:continue, :load}}
    else
      Logger.info("skip fetching certifcates on start")
      {:ok, :missing}
    end
  end

  @impl true
  def handle_continue(:load, _) do
    {:noreply, fresh_certs()}
  end

  @impl true
  def handle_call(:get, _from, :missing) do
    certs = fresh_certs()
    {:reply, certs, certs}
  end

  def handle_call(:get, _from, certs) do
    {:reply, certs, certs}
  end

  @impl true
  def handle_info(:refresh, _) do
    Process.send_after(self(), :refresh, @refresh_ms, [])
    {:noreply, fresh_certs()}
  end

  defp fresh_certs do
    %Certificates{}
    |> Certificates.set_version(@goolge_api_version)
    |> GoogleCerts.refresh()
  end

  defp fetch_on_start? do
    Application.get_env(:google_certs, :fetch_on_start?, true)
  end
end
