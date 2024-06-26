defmodule GoogleCerts.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      GoogleCerts.CertificateCache
    ]

    opts = [strategy: :one_for_one, name: GoogleCerts.Application]
    Supervisor.start_link(children, opts)
  end
end
