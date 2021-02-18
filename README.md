# Performance Analyzer

Performance Analyzer is an HTTP benchmarking tool capable of generating significant load from a single node or from a distributed cluster. It combines the capabilities of elixir to analyze the behavior of an application in different concurrency scenarios.

## Install

```elixir
mix deps.get
mix compile
```

## Basic Usage

Open and edit config/dev.exs file to configure.

```
use Mix.Config

config :perf_analizer,
       url: "http://127.0.0.1:8080/wait/1",
       request: %{method: "POST", headers: [{"Content-Type", "application/json"}], body: "{\"key\": \"example\"}"},
       execution: %{steps: 5, increment: 50, duration: 7000, constant_load: false},
       distributed: :none

config :logger,
       level: :warn
```

| Property      | Description                                                                                                   |
| ------------- | ------------------------------------------------------------------------------------------------------------- |
| url           | The url of the application you want to test. Make sure you have a network connection between two machines     |
| request       | Here you need to configure the HTTP verb, headers and the body of the request.                                |
| steps         | The number of executions for the test. Each step adds the concurrency configured in the increment             |
| increment     | Increment in concurrency after each step                                                                      |
| duration      | Duration in milliseconds of each step                                                                         |
| constant_load | Allows you to configure if the load will be constant or if the increment will be used to vary the concurrency in each step |
| distributed   | Indicates if it should be run from a single node or in a distributed way                                      |

In the example above will be executed a test of 5 steps with an increment of 50:

1. Step 1: 50 of concurrency
2. Step 2: 100 of concurrency
3. Step 3: 150 of concurrency
4. ...

Each step will last 7 seconds.

## Run

In the shell:

```
iex -S mix
or
iex  --sname node1@localhost -S mix
```

To run Execution:

```
Perf.Execution.launch_execution()
```

## Results

After each step is executed you will get a table of results like the following:

```
concurrency, throughput -- mean latency -- max latency, mean http latency, http_errors, protocol_error_count, error_conn_count
50, 22159 -- 2ms -- 12ms, 2ms, 0, 0, 0
100, 29329 -- 3ms -- 19ms, 3ms, 0, 0, 0
150, 31000 -- 5ms -- 211ms, 5ms, 0, 0, 0
200, 31031 -- 6ms -- 33ms, 6ms, 0, 0, 0
250, 31413 -- 8ms -- 42ms, 8ms, 0, 0, 0
......
```

Then, you can compare the attributes that are interesting for you. For example concurrency vs Throughtout or concurrency vs mean latency.

### Examples

![Example 1 - Throughput](https://github.com/bancolombia/distributed-performance-analyzer/blob/documentation-improves/assets/dresults_example1.png)

![Example 2 - Latency](https://github.com/bancolombia/distributed-performance-analyzer/blob/documentation-improves/assets/dresults_example2.png)
