require 'spec_helper'

RSpec.describe BfTools::Client do
  describe 'get_health' do
    it do
      expect(BfTools::Client.get_health.keys).to eq(['status'])
    end
  end
end
