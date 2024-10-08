defmodule ExRabbitPool.Consumer do
  defmodule State do
    @moduledoc """
    RabbitMQ Consumer Worker State.

    State attributes:

      * `:pool_id` - the name of the connection pool to RabbitMQ
      * `:channel` - the RabbitMQ channel for consuming new messages
      * `:monitor` - a monitor for handling channel crashes
      * `:queue` - the name of the queue to consume
      * `:consumer_tag` - the consumer tag assigned by RabbitMQ
      * `:config` - the consumer configuration attributes
      * `:adapter` - the RabbitMQ client to use
    """
    @enforce_keys [:pool_id, :queue]

    @typedoc "Consumer State Type"
    @type t :: %__MODULE__{
            pool_id: atom(),
            channel: AMQP.Channel.t(),
            monitor: reference(),
            queue: AMQP.Basic.queue(),
            consumer_tag: AMQP.Basic.consumer_tag(),
            config: keyword(),
            adapter: module()
          }
    defstruct pool_id: nil,
              caller: nil,
              channel: nil,
              monitor: nil,
              queue: nil,
              consumer_tag: nil,
              config: [],
              adapter: nil
  end

  @type meta :: map()
  @type nowait :: boolean()
  @type reason :: any()

  @callback basic_consume_ok(State.t(), AMQP.Basic.consumer_tag()) :: :ok | {:stop, reason}
  @callback basic_deliver(State.t(), AMQP.Basic.payload(), meta()) :: :ok | {:stop, reason}
  @callback basic_cancel(State.t(), AMQP.Basic.consumer_tag(), nowait()) :: :ok | {:stop, reason}
  @callback basic_cancel_ok(State.t(), AMQP.Basic.consumer_tag()) :: :ok | {:stop, reason}

  defmacro __using__(_opts) do
    quote do
      use GenServer

      def start_link(config) do
        GenServer.start_link(__MODULE__, config)
      end

      ####################
      # Server Callbacks #
      ####################

      @impl true
      def init(config) do
        {opts, consumer_config} = Keyword.split(config, [:adapter, :pool_id, :queue])
        adapter = Keyword.get(opts, :adapter, ExRabbitPool.RabbitMQ)
        pool_id = Keyword.fetch!(opts, :pool_id)
        queue = Keyword.fetch!(opts, :queue)

        state = %State{
          pool_id: pool_id,
          queue: queue,
          adapter: adapter,
          config: consumer_config
        }

        {:ok, state, {:continue, :connect}}
      end

      @impl true
      def handle_continue(:connect, state), do: do_connect(state)

      @impl true
      def handle_info(:connect, state), do: do_connect(state)

      # Gets a connection worker out of the connection pool, if there is one available
      # takes a channel out of it channel pool, if there is one available subscribe
      # itself as a consumer process.
      def do_connect(state) do
        %{pool_id: pool_id} = state

        pool_id
        |> ExRabbitPool.get_connection_worker()
        |> ExRabbitPool.checkout_channel()
        |> handle_channel_checkout(state)
      end

      @impl true
      def handle_info(
            {:DOWN, monitor, :process, chan_pid, reason},
            %{monitor: monitor, channel: %{pid: chan_pid}, config: config} = state
          ) do
        schedule_connect(config)
        {:noreply, %State{state | monitor: nil, consumer_tag: nil, channel: nil}}
      end

      ################################
      # AMQP Basic.Consume Callbacks #
      ################################

      # Confirmation sent by the broker after registering this process as a consumer
      @impl true
      def handle_info(
            {:basic_consume_ok, %{consumer_tag: consumer_tag}},
            %{consumer_tag: consumer_tag} = state
          ) do
        case basic_consume_ok(state, consumer_tag) do
          :ok ->
            {:noreply, state}

          {:stop, reason} ->
            {:stop, reason, state}

          _ ->
            {:noreply, state}
        end
      end

      # This is sent for each message consumed, where `payload` contains the message
      # content and `meta` contains all the metadata set when sending with
      # Basic.publish or additional info set by the broker;
      @impl true
      def handle_info({:basic_deliver, payload, meta}, state) do
        case basic_deliver(state, payload, meta) do
          :ok ->
            {:noreply, state}

          {:stop, reason} ->
            {:stop, reason, state}

          _ ->
            {:noreply, state}
        end
      end

      # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
      @impl true
      def handle_info(
            {:basic_cancel, %{consumer_tag: consumer_tag, nowait: nowait}},
            %{consumer_tag: consumer_tag} = state
          ) do
        case basic_cancel(state, consumer_tag, nowait) do
          :ok ->
            {:stop, :shutdown, state}

          {:stop, reason} ->
            {:stop, reason, state}
        end
      end

      # Confirmation sent by the broker to the consumer process after a Basic.cancel
      @impl true
      def handle_info(
            {:basic_cancel_ok, %{consumer_tag: consumer_tag}},
            %{consumer_tag: consumer_tag} = state
          ) do
        case basic_cancel_ok(state, consumer_tag) do
          :ok ->
            {:stop, :normal, state}

          {:stop, reason} ->
            {:stop, reason, state}
        end
      end

      # When successfully checks out a channel, subscribe itself as a consumer
      # process and monitors it handle crashes and reconnections
      defp handle_channel_checkout(
             {:ok, %{pid: channel_pid} = channel},
             %{config: config, queue: queue, adapter: adapter} = state
           ) do
        with :ok <- setup_channel(state, channel),
             {:ok, consumer_tag} <- adapter.consume(channel, queue, self(), config) do
          ref = Process.monitor(channel_pid)
          {:noreply, %State{state | channel: channel, monitor: ref, consumer_tag: consumer_tag}}
        else
          {:error, reason} ->
            schedule_connect(config)
            {:noreply, %State{state | channel: nil, consumer_tag: nil}}
        end
      end

      # When there was an error checking out a channel, retry in a configured interval
      defp handle_channel_checkout({:error, reason}, %{config: config} = state) do
        schedule_connect(config)
        {:noreply, state}
      end

      defp schedule_connect(config) do
        reconnect_interval = Keyword.get(config, :reconnect_interval, 1_000)
        Process.send_after(self(), :connect, reconnect_interval)
      end

      def basic_deliver(%{adapter: adapter, channel: channel}, payload, %{delivery_tag: tag}) do
        :ok = adapter.ack(channel, tag)
      end

      def setup_channel(_state, _channel), do: :ok
      def basic_consume_ok(_state, _consumer_tag), do: :ok
      def basic_cancel(_state, _consumer_tag, _nowait), do: :ok
      def basic_cancel_ok(_state, _consumer_tag), do: :ok

      defoverridable setup_channel: 2
      defoverridable basic_deliver: 3
      defoverridable basic_consume_ok: 2
      defoverridable basic_cancel: 3
      defoverridable basic_cancel_ok: 2
    end
  end
end
