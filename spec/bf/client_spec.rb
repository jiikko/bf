require 'spec_helper'

RSpec.describe BF::Client do
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

  describe 'get_health' do
    it do
      result = nil
      begin
        result = BF::Client.get_state.keys.sort
      rescue => e
        skip "オフラインの可能性があります(#{})"
      end
      expect(result).to eq(['state', 'health'].sort)
    end
  end
end
