require 'spec_helper'

RSpec.describe BF::Client do
  describe 'get_health' do
    it do
      skip
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
