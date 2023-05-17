- [Performance Analyzer](#performance-analyzer)
  - [Install](#install)
  - [Basic Usage](#basic-usage)
  - [Run](#run)
  - [Results](#results)
    - [Examples](#examples)

# Performance Analyzer

[![MIT License][license-shield]][license-url]
[![Docker Hub][docker-shield]][docker-url]
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![Score Cards][scorecards-shield]][scorecards-url]

Performance Analyzer is an HTTP benchmarking tool capable of generating significant load from a single node or from a distributed cluster. It combines the capabilities of elixir to analyze the behavior of an application in different concurrency scenarios.

## Install

```shell
./enable-hook.sh
mix deps.get
mix compile
```

## Basic Usage

Open and edit config/performance.exs file to configure.

```elixir
import Config

config :perf_analyzer,
  url: "http://httpbin.org/get",
  request: %{
    method: "GET",
    headers: [{"Content-Type", "application/json"}],
    # body: ~s|'{"data": "value"}'| --> If you don't use dataset values
    body: fn item ->
      # This is for dataset replacement
      ~s|'{"data": #{Enum.random(1..10)}, "key": "#{item.columnName}"}'|
    end
  },
  execution: %{
    steps: 5,
    increment: 1,
    duration: 2000,
    constant_load: false,
    dataset: "/Users/sample.csv",
    # dataset: :none, --> If you don't use dataset
    separator: ","
  },
  distributed: :none,
  jmeter_report: true

config :logger,
  level: :info

```

| Property      | Description                                                                                                                |
| ------------- | -------------------------------------------------------------------------------------------------------------------------- |
| url           | The url of the application you want to test. Make sure you have a network connection between two machines                  |
| request       | Here you need to configure the HTTP verb, headers and the body of the request.                                             |
| steps         | The number of executions for the test. Each step adds the concurrency configured in the increment                          |
| increment     | Increment in concurrency after each step                                                                                   |
| duration      | Duration in milliseconds of each step                                                                                      |
| constant_load | Allows you to configure if the load will be constant or if the increment will be used to vary the concurrency in each step |
| dataset       | The path to the csv dataset file                                                                                           |
| separator     | Dataset separator (, ; :)                                                                                                  |
| distributed   | Indicates if it should be run from a single node or in a distributed way                                                   |

In the example above will be executed a test of 5 steps with an increment of 50:

1. Step 1: 50 of concurrency
2. Step 2: 100 of concurrency
3. Step 3: 150 of concurrency
4. ...

Each step will last 2 seconds.

## Run

Docker:

https://hub.docker.com/r/bancolombia/distributed-performance-analyzer

```shell
docker run --rm -v <project_path>/config:/app/config -v <project_path>/dataset:/app/datasets bancolombia/distributed-performance-analyzer:latest
```

In the shell:

```shell
iex -S mix
or
iex  --sname node1@localhost -S mix
```

To run Execution:

```shell
Perf.Execution.launch_execution()
```

## Results

After each step is executed you will get a table of results like the following:

```shell
concurrency, throughput -- mean latency -- p90 latency, max latency, mean http latency, http_errors, protocol_error_count, error_conn_count
50, 22159 -- 2ms -- 3ms, 12ms, 2ms, 0, 0, 0
100, 29329 -- 3ms -- 4ms, 19ms, 3ms, 0, 0, 0
150, 31000 -- 5ms -- 6ms, 211ms, 5ms, 0, 0, 0
200, 31031 -- 6ms -- 7ms, 33ms, 6ms, 0, 0, 0
250, 31413 -- 8ms -- 9ms, 42ms, 8ms, 0, 0, 0
......
```

And in CSV format:
 
 ```shell
concurrency, throughput, mean latency, p90 latency, max latency
2, 14, 138, 284, 284
3, 21, 132, 230, 230
4, 26, 143, 128, 518
5, 34, 139, 230, 420
 ```

Then, you can compare the attributes that are interesting for you. For example concurrency vs Throughput or Concurrency vs Mean Latency.

### Examples

![Example 1 - Throughput](assets/dresults_example1.png)

![Example 2 - Latency](assets/dresults_example2.png)


[scorecards-shield]: https://github.com/bancolombia/distributed-performance-analyzer/actions/workflows/scorecards-analysis.yml/badge.svg
[scorecards-url]: https://github.com/bancolombia/distributed-performance-analyzer/actions/workflows/scorecards-analysis.yml
[docker-shield]: https://img.shields.io/docker/pulls/bancolombia/distributed-performance-analyzer
[docker-url]: https://hub.docker.com/repository/docker/bancolombia/distributed-performance-analyzer
[contributors-shield]: https://img.shields.io/github/contributors/bancolombia/distributed-performance-analyzer.svg
[contributors-url]: https://github.com/bancolombia/distributed-performance-analyzer/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/bancolombia/distributed-performance-analyzer.svg
[forks-url]: https://github.com/bancolombia/distributed-performance-analyzer/network/members
[stars-shield]: https://img.shields.io/github/stars/bancolombia/distributed-performance-analyzer.svg
[stars-url]: https://github.com/bancolombia/distributed-performance-analyzer/stargazers
[issues-shield]: https://img.shields.io/github/issues/bancolombia/distributed-performance-analyzer.svg
[issues-url]: https://github.com/bancolombia/distributed-performance-analyzer/issues
[license-shield]: https://img.shields.io/github/license/bancolombia/distributed-performance-analyzer.svg
[license-url]: https://github.com/bancolombia/distributed-performance-analyzer/blob/main/LICENSE
