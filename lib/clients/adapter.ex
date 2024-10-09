defmodule ExRabbitPool.Clients.Adapter do
  @callback open_connection(keyword() | String.t()) :: {:ok, AMQP.Connection.t()} | {:error, any}
  @callback open_channel(AMQP.Connection.t()) :: {:ok, AMQP.Channel.t()} | {:error, any()} | any()
  @callback close_channel(AMQP.Channel.t() | pid()) :: :ok | {:error, AMQP.Basic.error()}
  @callback close_connection(AMQP.Connection.t()) :: :ok | {:error, any}
  @callback publish(AMQP.Channel.t(), String.t(), String.t(), String.t(), keyword) ::
              :ok | AMQP.Basic.error()
  @callback consume(AMQP.Channel.t(), String.t(), pid() | nil, keyword) ::
              {:ok, String.t()} | AMQP.Basic.error()
  @callback cancel_consume(AMQP.Channel.t(), String.t(), keyword) ::
              {:ok, String.t()} | {:error, AMQP.Basic.error()}
  @callback ack(AMQP.Channel.t(), AMQP.Basic.delivery_tag(), keyword()) ::
              :ok | AMQP.Basic.error()
  @callback reject(AMQP.Channel.t(), AMQP.Basic.delivery_tag(), keyword()) ::
              :ok | AMQP.Basic.error()
  @callback declare_queue(AMQP.Channel.t(), AMQP.Basic.queue(), keyword()) ::
              {:ok, map()} | AMQP.Basic.error()
  @callback queue_bind(AMQP.Channel.t(), AMQP.Basic.queue(), AMQP.Basic.exchange(), keyword()) ::
              :ok | AMQP.Basic.error()
  @callback declare_exchange(AMQP.Channel.t(), AMQP.Basic.exchange(), keyword()) ::
              :ok | AMQP.Basic.error()
  @callback qos(AMQP.Channel.t(), keyword()) :: :ok | AMQP.Basic.error()
end
