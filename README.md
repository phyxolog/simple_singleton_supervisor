# Simple Singleton Supervisor

[![Module Version](https://img.shields.io/hexpm/v/simple_singleton_supervisor.svg)](https://hex.pm/packages/simple_singleton_supervisor)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/simple_singleton_supervisor/)
[![Total Download](https://img.shields.io/hexpm/dt/simple_singleton_supervisor.svg)](https://hex.pm/packages/simple_singleton_supervisor)
[![License](https://img.shields.io/hexpm/l/simple_singleton_supervisor.svg)](https://github.com/phyxolog/simple_singleton_supervisor/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/phyxolog/simple_singleton_supervisor.svg)](https://github.com/phyxolog/simple_singleton_supervisor/commits/master)

It allows you to run a single globally unique process in a cluster. It uses only `:global` and doesn't create any additional processes. Name of the supervisor is determining of the global uniqueness.

You can find supporting documentation and usage examples [here](https://hexdocs.pm/simple_singleton_supervisor).

## Installation

Simple Singleton Supervisor is available on Hex, the package can be installed by adding `simple_singleton_supervisor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:simple_singleton_supervisor, "~> MAJ.MIN"}
  ]
end
```

You can determine the latest version by running `mix hex.info simple_singleton_supervisor` in your shell, or by going to the `simple_singleton_supervisor` [page on hex.pm](https://hex.pm/packages/simple_singleton_supervisor).

## Usage

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

## Copyright and License

Copyright (c) 2024 Yurii Zhyvaha

This library is MIT licensed. See the
[LICENSE.md](https://github.com/phyxolog/simple_singleton_supervisor/blob/master/LICENSE.md) for details.
