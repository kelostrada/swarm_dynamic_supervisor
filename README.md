# Swarm.DynamicSupervisor

[![Hex.pm Version](http://img.shields.io/hexpm/v/swarm_dynamic_supervisor.svg?style=flat)](https://hex.pm/packages/swarm_dynamic_supervisor)

Supervisor for `Swarm` registered processes to handle process crashes like regular `DynamicSupervisor`.

This supervisor acts like regular `DynamicSupervisor`, however it stores names registered by `Swarm` in `id` part of process definition.

For now joining processes to groups after restart don't work! I didn't need this functionality for now,
but I have plans to implement it in the future.

## Installation

The package can be installed by adding `swarm_dynamic_supervisor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swarm_dynamic_supervisor, "~> 0.1.0"}
  ]
end
```

## Example

The following example shows a simple case based on example from `Swarm` documentation,
but using `Swarm.DynamicSupervisor`. The processes will be distributed across the
cluster, will be discoverable by name from anywhere in cluster, will be restarted on
node failures and will be restarted and registered by the same name on unhandled
process crashes (like with regular `DynamicSupervisor`). After restart it's not
determined that the process will restarted on the same node.

```elixir
defmodule MyApp.Supervisor do
  @moduledoc """
  This is the supervisor for the worker processes you wish to distribute
  across the cluster, Swarm is primarily designed around the use case
  where you are dynamically creating many workers in response to events. It
  works with other use cases as well, but that's the ideal use case.
  """
  use Swarm.DynamicSupervisor

  def start_link() do
    Swarm.DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Swarm.DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Registers a new worker, and creates the worker process

  Notice that there is a required field `id` in child_spec. It's used for registering
  name of process in Swarm. You no longer have to call `Swarm.register_name/5`
  explicitly anymore.
  """
  def start_child(name) do
    spec = Supervisor.child_spec(MyApp.Worker, id: name, start: {MyApp.Worker, :start_link, [name]})
    Swarm.DynamicSupervisor.start_child(__MODULE__, spec)
  end
end

defmodule MyApp.Worker do
  @moduledoc """
  This is the worker process, in this case, it simply posts on a
  random recurring interval to stdout.
  """
  use GenServer, restart: :transient

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name])
  end

  def init([name]) do
    {:ok, {name, :rand.uniform(5_000)}, 0}
  end

  # called when a handoff has been initiated due to changes
  # in cluster topology, valid response values are:
  #
  #   - `:restart`, to simply restart the process on the new node
  #   - `{:resume, state}`, to hand off some state to the new process
  #   - `:ignore`, to leave the process running on its current node
  #
  def handle_call({:swarm, :begin_handoff}, _from, {name, delay}) do
    {:reply, {:resume, delay}, {name, delay}}
  end

  # crash process for testing
  def handle_call(:crash, _from, _state) do
    raise :crash
  end
  # called after the process has been restarted on its new node,
  # and the old process' state is being handed off. This is only
  # sent if the return to `begin_handoff` was `{:resume, state}`.
  # **NOTE**: This is called *after* the process is successfully started,
  # so make sure to design your processes around this caveat if you
  # wish to hand off state like this.
  def handle_cast({:swarm, :end_handoff, delay}, {name, _}) do
    {:noreply, {name, delay}}
  end
  # called when a network split is healed and the local process
  # should continue running, but a duplicate process on the other
  # side of the split is handing off its state to us. You can choose
  # to ignore the handoff state, or apply your own conflict resolution
  # strategy
  def handle_cast({:swarm, :resolve_conflict, _delay}, state) do
    {:noreply, state}
  end

  def handle_info(:timeout, {name, delay}) do
    IO.puts "#{inspect name} says hi!"
    Process.send_after(self(), :timeout, delay)
    {:noreply, {name, delay}}
  end
  # this message is sent when this process should die
  # because it is being moved, use this as an opportunity
  # to clean up
  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end
end

defmodule MyApp.ExampleUsage do
  ...snip...

  @doc """
  Starts worker and registers name in the cluster
  """
  def start_worker(name) do
    {:ok, pid} = MyApp.Supervisor.start_child(name)
  end

  def crash(name) do
    Swarm.call({:via, :swarm, name}, :crash)
  end

  ...snip...
end
```

## TODO

* Add processes to groups after restart
* Fix hexdocs
