require 'spec_helper'

RSpec.describe BfTools::Monitor do
  describe 'ranges' do
    it do
      expect(BfTools::Monitor.new.ranges).to_not eq(nil)
    end
  end
end
