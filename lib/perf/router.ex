defmodule MyRouter do
  use Plug.Router
  @host   "host"
  @port "port"
  @method "method"
  @path "path"
  @steps "steps"
  @increment "incre"
  @duration  "duration"
  @const_load "load"
  plug :match
  plug :dispatch

  get "/execute" do
    conn = fetch_query_params(conn)
    %{ @host => host, @port => port,@method => method,@path => path,@steps => steps,@increment => incre,@duration => duration,@const_load => load} = conn.params
    {realport,_}= Integer.parse(port)
    {duration,_}= Integer.parse(duration)
    {increment,_}= Integer.parse(incre)
    {steps,_}= Integer.parse(steps)
    param1 = {:http, host,realport}
    param2 = %{method: method,path: path, headers: [], body: ""}
    param3 = %{steps: steps,increment: increment, duration: duration, constant_load: convert(load)}
    param4 = :none
    Perf.Application.init(param1,param2,param3,param4)
    Perf.Application.start_link()
    while(Perf.Application.get())
    result = inspect Perf.Application.get()
    Perf.Application.add_to(nil)
    send_resp(conn, 200,result)
  end

  match _ do
    send_resp(conn, 404, IEx.Info.info(5))
  end

  def convert("true"), do: true

  def convert("false"), do: false

  def while(i) when i != nil do
    i
  end

  def while(i) do
    while(Perf.Application.get())
  end

end
