require 'spec_helper'

RSpec.describe BF::SummarizedMyTradeWorker do
  it 'be success' do
    BF::SummarizedMyTradeWorker.perform
  end
end
