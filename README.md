# Griffin::Interceptors

Griffin::Interceptors is a collection of gRPC's interceptors for [griffin](https://github.com/ganmacs/griffin).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'griffin-interceptors'
```

And then execute:

    $ bundle

## Usage

```rb
class GreeterServer < Helloworld::Greeter::Service
  def say_hello(hello_req, _unused_call)
    Helloworld::HelloReply.new(message: "Hello #{hello_req.name}")
  end
end

require 'griffin/interceptors/server/filtered_payload_interceptor'
require 'griffin/interceptors/server/logging_interceptor'
require 'griffin/interceptors/server/x_request_id_interceptor'

interceptors = [
  Griffin::Interceptors::Server::FilteredPayloadInterceptor.new,
  Griffin::Interceptors::Server::LoggingInterceptor.new,
  Griffin::Interceptors::Server::XRequestIdInterceptor.new,
]

Griffin::Server.configure do |c|
  c.bind '127.0.0.1'

  c.port 50051

  c.services GreeterServer.new

  c.interceptors interceptors

  c.workers 2
end

Griffin::Server.run
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cookpad/griffin-interceptors. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

