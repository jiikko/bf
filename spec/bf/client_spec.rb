require 'spec_helper'

RSpec.describe BF::Client do
  before(:each) do
    Resque.redis.set(BF::Monitor::FETCH_DISPARITY_KEY, 0) # normalize
  end

  describe '#buy' do
    it 'success' do
      allow_any_instance_of(Net::HTTP).to receive(:request) do
        OpenStruct.new(body: { 'child_order_acceptance_id' => 'test' }.to_json)
      end
      expect(BF::Client.new.buy(1, 0.00001)).to eq('test')
    end
    context 'エラーレスポンスが返ってきた時' do
      it '例外をなげること' do
        allow_any_instance_of(Net::HTTP).to receive(:request) do
          OpenStruct.new(body: "{\"status\":-106,\"error_message\":\"The price is too low.\",\"data\":null}")
        end
        expect { BF::Client.new.buy(1, 0.00001) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#sell' do
    it 'success' do
      allow_any_instance_of(Net::HTTP).to receive(:request) do
        OpenStruct.new(body: { 'child_order_acceptance_id' => 'sell_test' }.to_json)
      end
      expect(BF::Client.new.sell(9999999999, 0.00001)).to eq('sell_test')
    end
    context 'エラーレスポンスが返ってきた時' do
      it '例外をなげること' do
        allow_any_instance_of(Net::HTTP).to receive(:request) do
          OpenStruct.new(body: "{\"status\":-106,\"error_message\":\"The price is too low.\",\"data\":null}")
        end
        expect { BF::Client.new.sell(9999999999, 0.00001) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#cancel_order' do
    it 'success' do
      allow_any_instance_of(Net::HTTP).to receive(:request) do
        OpenStruct.new(body: '', code: '200')
      end
      expect(BF::Client.new.cancel_order('bar')).to eq('200')
    end
  end

  describe '#get_health' do
    context 'タイムアウトになる時' do
      it 'retryすること' do
        allow_any_instance_of(Net::HTTP).to receive(:request) { raise(Timeout::Error) }
        allow_any_instance_of(BF::Client).to receive(:sleep_count_when_timeout) { 0 }
        state = BF::Client.new.get_state
        expect(state).to eq({})
      end
    end
    context '成功する時' do
      it do
        result = nil
        begin
          result = BF::Client.new.get_state.keys.sort
        rescue => e
          skip "オフラインの可能性があります(#{})"
        end
        expect(result).to eq(['state', 'health'].sort)
      end
    end
  end

  describe '#get_disparity' do
    it 'return disparity' do
      result = BF::Client.new.get_disparity
      expect(result).to be_a(Float)
    end
  end
end
