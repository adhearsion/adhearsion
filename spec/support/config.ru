app = Proc.new {
  [
    200,
    { "Content-Type" => "text/html" },
    ["Hello, Rack"]
  ]
}
run app
