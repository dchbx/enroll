module AmqpClientHelpers
  def with_response_exchange(conn)
    out_chan = conn.create_channel
    begin
      out_chan.confirm_select
      d_ex = out_chan.default_exchange
      yield d_ex
      out_chan.wait_for_confirms
    ensure
      out_chan.close
    end
  end
end
