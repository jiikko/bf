require 'spec_helper'

RSpec.describe BF::Client do
  describe 'get_health' do
    it do
      expect(BF::Client.get_state.keys.sort).to eq(['state', 'health'].sort)
    end
  end
end
