y = () => from(bucket: "telegraf")
	|> range(start: dashboardTime)
	|> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_system" and r.cpu == "cpu-total")
    |> yield(name: "y")

x = () => from(bucket: "telegraf")
	|> range(start: dashboardTime)
	|> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_system" and r.cpu == "cpu-total")
	|> map(fn: (r) => ({_time: r._time, index: 1}))
	|> cumulativeSum(columns: ["index"])
    |> yield(name: "x")

y_bar = () => from(bucket: "telegraf")
	|> range(start: dashboardTime)
	|> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_system" and r.cpu == "cpu-total")
    |> mean(columns: ["_value"])
    |> keep(columns : ["_value"])
    |> yield(name: "y_bar")

x_bar = () => from(bucket: "telegraf")
	|> range(start: dashboardTime)
	|> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_system" and r.cpu == "cpu-total")
	|> map(fn: (r) => ({_time: r._time, index: 1}))
	|> cumulativeSum(columns: ["index"])
    |> mean(columns: ["index"])
    |> keep(columns : ["index"])
    |> yield(name: "x_bar")

diff_y = () => y()
		|> map(fn: (r) => ({_time: r._time, _value: r._value, y_bar: 2.56}))
        |> map(fn: (r) => ({"_time": r._time, "_value": (r._value - r.y_bar)}))

diff_x = () => x()
		|> map(fn: (r) => ({_time: r._time, index: r.index, x_bar: 15}))
        |> map(fn: (r) => ({"_time": r._time, "_value": (r.index - r.x_bar)}))

joined = () => join(tables: {diff_y: diff_y(), diff_x: diff_x()}, on: ["_time"]])
		|> keep(columns: ["_time", "_value_diff_y","_value_diff_x"])
        |> map(fn: (r) => ({"_time": r._time, "diff_y": r._value_diff_y,"diff_x": r._value_diff_x}))


m_num = () => joined() |> map(fn: (r) => (r.diff_y * r.diff_x))

m_num()
