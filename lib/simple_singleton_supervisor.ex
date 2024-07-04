defmodule SimpleSingletonSupervisor do
  @moduledoc ~S"""
  It allows you to run a single globally unique process in a cluster. It uses only `:global` and
  doesn't create any additional processes. Name of the supervisor is determining of the global uniqueness.

  Before starting it synchronizes all nodes via `:global.sync/0` and then runs a transaction to
  guarantee that the only one node is starting this process in the same time. If the process is started
  (or already running) it links that process to the local supervisor. If the process dies it will be
  restarted on another available node.

  If the process is started on one node and the network is partitioned you would face a situation when
  the process is running on `n` partitions. When the partition is healed, only one process will be running
  across the cluster. All other processes will be terminated.

  Be aware, in distributed systems you can't guarantee that the process will be started only and only once
  no matter what's happening. You still can face problems like network partitions. You can read more about
  it here: https://keathley.io/blog/sgp.html.

  To start a process you can add `SimpleSingletonSupervisor` to your application's children list:

  ```elixir
  defmodule MyApp.Application do
    use Application

    def start(_type, _args) do
      singleton_children = [
        {MyApp.SingletonProcess, []}
      ]

      children = [
        {SimpleSingletonSupervisor, [
          name: MyApp.SingletonSupervisor,
          strategy: :one_for_one,
          children: singleton_children
        ]}
      ]

      opts = [strategy: :one_for_one, name: MyApp.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  ```

  SingletonSupervisor can also be used as a module-based supervisor:

  ```elixir
  defmodule MySingletonSupervisor do
    @moduledoc false

    use Supervisor

    def start_link(init_arg) do
      SimpleSingletonSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
    end

    @impl Supervisor
    def init(_init_arg) do
      children = [
        {MyApp.SingletonProcess, []}
      ]

      Supervisor.init(children, strategy: :one_for_one)
    end
  end
  ```
  """

  use Supervisor

  @default_options [strategy: :one_for_one]

  def child_spec(init_arg) do
    {name, init_arg} = Keyword.pop(init_arg, :name)

    %{
      id: name,
      start: {__MODULE__, :start_link, [__MODULE__, init_arg, [name: name]]},
      type: :supervisor
    }
  end

  @doc "Starts a module-based singleton supervisor process with the given `module` and `init_arg`."
  @spec start_link(module(), term(), Keyword.t()) :: Supervisor.on_start()
  def start_link(module, init_arg, options \\ []) do
    name =
      Keyword.get(options, :name) ||
        raise ArgumentError, "The :name option is required when starting a singleton supervisor."

    transaction_fun = fn -> global_start_link(module, init_arg, name: {:global, name}) end

    with :ok <- :global.sync(),
         {:ok, pid} <- :global.trans({name, :start_link}, transaction_fun) do
      Process.link(pid)
      {:ok, pid}
    else
      {:error, {:singleton_sup_not_started, {:shutdown, reason}}} -> {:shutdown, reason}
      {:error, {:singleton_sup_not_started, reason}} -> {:error, reason}
      {:error, reason} -> {:error, {:global_sync_failed, reason}}
      :aborted -> {:error, :global_transaction_aborted}
    end
  end

  @impl Supervisor
  def init(init_arg) do
    {children, init_arg} = Keyword.pop(init_arg, :children, [])
    options = Keyword.merge(@default_options, init_arg)

    Supervisor.init(children, options)
  end

  defp global_start_link(module, init_arg, options) do
    {:global, name} = Keyword.fetch!(options, :name)

    with :undefined <- :global.whereis_name(name),
         {:ok, pid} <- Supervisor.start_link(module, init_arg, options) do
      {:ok, pid}
    else
      pid when is_pid(pid) -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, {:singleton_sup_not_started, reason}}
      {:shutdown, reason} -> {:error, {:singleton_sup_not_started, {:shutdown, reason}}}
      reason -> {:error, {:singleton_sup_not_started, reason}}
    end
  end
end
