module Aws

  # Base class for all {Aws} service clients.
  class Client < Seahorse::Client::Base

    # Waits until a particular condition is satisfied.
    #
    #     client.wait_until(:condition_name)
    #
    # Each waiter has success and failure conditions. The waiter returns
    # `true` one the success condition has been satisfied. If the failure
    # condition is met, then an error is raised. If a maximum number of
    # attempts have been made without success or failure, then an
    # error is raised.
    #
    # Normally you will invoke this method with additional request params.
    # The params required depend on the client method being polled.
    #
    #     # see Aws::S3::Client#head_bucket for a list of supported options
    #     s3.wait_until(:bucket_exists, bucket:'aws-sdk')
    #
    # @example Custom interval and max attempts
    #
    #   client.wait_until(:waiter_name) do |waiter|
    #     waiter.interval = 30    # sleep 30 seconds between attempts
    #     waiter.max_attempts = 5 # try 5 times then give up
    #   end
    #
    # @example Progress Callbacks
    #
    #   client.wait_until(:waiter_name) do |waiter|
    #
    #     # yields just before polling for change
    #     waiter.before_attempt do |attempt|
    #       # throw :success to stop waiting
    #       # throw :failure, 'optional-msg' to stop waiting with an error
    #     end
    #
    #     # yields before sleeping
    #     waiter.before_wait do |attempt|
    #       # throw :success to stop waiting
    #       # throw :failure, 'optional-msg' to stop waiting with an error
    #     end
    #
    #   end
    #
    # @example Exponential back-off
    #
    #   # exponential back-off, sleep 1, 2, 4, and 8 seconds
    #   client.wait_until(:waiter_name) do |waiter|
    #     waiter.interval = 0 # disable default sleep
    #     waiter.max_attempts = 4
    #     waiter.before_wait do |attempt|
    #       sleep(attempt ** 2)
    #     end
    #   end
    #
    # @example Limit time, not attempts
    #
    #   client.wait_until(:waiter_name) do |waiter|
    #     one_hour = Time.now + 3600
    #     waiter.max_attempts = nil
    #     waiter.before_attempt do |attempt|
    #       throw(:failure, 'waited to long') if Time.now > one_hour
    #     end
    #   end
    #
    # @param [Symbol] waiter_name The name of the waiter. See {#waiter_names}
    #   for a full list of supported waiters.
    # @param [Hash] params Additional request parameters.
    # @return [Seahorse::Client::Response] Returns the client response from
    #   the successful polling request. If `:success` is thrown from a callback,
    #   then the 2nd argument to `#throw` is returned.
    # @raise [Waiters::Errors::NoSuchWaiter] Raised when the given `waiter_name`
    #   is not defined.
    # @raise [Waiters::Errors::WaiterFailed] Raised when a waiter callback
    #   throws `:failure`.
    def wait_until(waiter_name, params = {}, &block)
      waiter = self.class.waiters.waiter(waiter_name)
      yield(waiter) if block_given?
      waiter.wait(self, params)
    end

    # Returns the list of supported waiters.
    # @return [Array<Symbol>]
    def waiter_names
      self.class.waiters.waiter_names
    end

    class << self

      # @return [Symbol]
      # @api private
      attr_accessor :identifier

      # @return [Paging::Provider]
      # @api private
      attr_accessor :paginators

      # @return [Waiters::Provider]
      # @api private
      attr_accessor :waiters

      # @api private
      def define(svc_name, options)
        client_class = Class.new(self)
        client_class.identifier = svc_name.downcase.to_sym
        client_class.set_api(load_api(options[:api]))
        Api::ServiceCustomizations.apply(client_class)
        client_class
      end

      private

      def load_api(api)
        case api
        when Seahorse::Model::Api then api
        when Hash then Seahorse::Model::Api.new(api)
        when String then Seahorse::Model::Api.new(Aws.load_json(api))
        else
          raise ArgumentError, "expected :api to be an Api, Hash or String"
        end
      end

    end
  end
end
