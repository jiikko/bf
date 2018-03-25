require 'spec_helper'

RSpec.describe BfTools::Client do
  describe 'get_health' do
    it do
      expect(BfTools::Client.get_state.keys.sort).to eq(['state', 'health'].sort)
    end
  end
end
