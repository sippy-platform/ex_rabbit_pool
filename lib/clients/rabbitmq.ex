defmodule ExRabbitPool.RabbitMQ do
  require Logger

  @behaviour ExRabbitPool.Clients.Adapter

  use AMQP

  @impl true
  def publish(channel, exchange, routing_key, payload, options \\ []) do
    Basic.publish(channel, exchange, routing_key, payload, options)
  end

  @impl true
  def consume(%Channel{} = channel, queue, consumer_pid \\ nil, options \\ []) do
    Basic.consume(channel, queue, consumer_pid, options)
  end

  @impl true
  def cancel_consume(%Channel{} = channel, consumer_tag, options \\ []) do
    Basic.cancel(channel, consumer_tag, options)
  end

  @impl true
  def ack(%Channel{} = channel, delivery_tag, options \\ []) do
    Basic.ack(channel, delivery_tag, options)
  end

  @impl true
  def reject(%Channel{} = channel, delivery_tag, options \\ []) do
    Basic.reject(channel, delivery_tag, options)
  end

  @impl true
  def open_connection(config) do
    Connection.open(config)
  end

  @impl true
  def open_channel(conn) do
    Channel.open(conn)
  end

  @impl true
  def close_channel(pid) when is_pid(pid) do
    case :amqp_channel.close(pid) do
      :ok -> :ok
      error -> {:error, error}
    end
  end

  @impl true
  def close_channel(channel) do
    Channel.close(channel)
  end

  @impl true
  def close_connection(conn) do
    Connection.close(conn)
  end

  @impl true
  def declare_queue(channel, queue \\ "", options \\ []) do
    case Queue.declare(channel, queue, options) do
      {:ok, res} ->
        Logger.debug("queue: #{queue} successfully declared")
        {:ok, res}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def declare_exchange(channel, exchange, options \\ [])

  def declare_exchange(_channel, "", _options), do: :ok

  def declare_exchange(channel, exchange, options) do
    type = Keyword.get(options, :type, :direct)

    case Exchange.declare(channel, exchange, type, options) do
      :ok ->
        Logger.debug("exchange #{exchange} successfully declared")
        :ok

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def queue_bind(channel, queue, exchange, options \\ [])

  def queue_bind(_channel, _queue, "", _options), do: :ok

  def queue_bind(channel, queue, exchange, options) do
    case Queue.bind(channel, queue, exchange, options) do
      :ok ->
        Logger.debug("#{queue} successfully bound to #{exchange}")
        :ok

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def qos(channel, options \\ []) do
    Basic.qos(channel, options)
  end
end
