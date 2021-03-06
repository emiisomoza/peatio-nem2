require 'faraday'
require 'better-faraday'

module Peatio
  module Nem2
    class Client
      Error = Class.new(StandardError)
      ConnectionError = Class.new(Error)

      class ResponseError < Error
        def initialize(msg)
          super "#{msg}"
        end
      end

      def initialize(endpoint)
        @endpoint = URI.parse(endpoint)
      end

      def rest_api(verb, path, data = nil)
        args = [@endpoint.to_s + path]

        if data
          if %i[post put patch].include?(verb)
            args << data.compact.to_json
            args << { 'Content-Type' => 'application/json' }
          else
            args << data.compact
            args << {}
          end
        else
          args << nil
          args << {}
        end

        args.last['Accept']        = 'application/json'

        response = Faraday.send(verb, *args)
        response.assert_success!
        response = JSON.parse(response.body)
        response['error'].tap { |error| raise ResponseError.new(error) if error }
        response
      rescue Faraday::Error => e
        if e.is_a?(Faraday::ConnectionFailed) || e.is_a?(Faraday::TimeoutError)
          raise ConnectionError, e
        else
          raise ConnectionError, JSON.parse(e.response.body)['message']
        end
      end
    end
  end
end
