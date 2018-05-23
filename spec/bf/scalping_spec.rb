RSpec.describe BF::Scalping do
  before do
    ResqueSpec.reset!
    BF::MyTrade.destroy_all
    BF::ScalpingTask.delete_all
  end

  after do
    BF::Trade.delete_all
  end

  describe '.scalp' do
    it 'ScalpingTaskを作成すること' do
      scalping = BF::Scalping.new
      allow(scalping).to receive(:validate).and_return(true)
      allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
      trade = BF::Trade.create!(price: 3, kind: :minutely)
      scalping.scalp
      expect(BF::MyTradeShip.count).to eq(1)
      expect(BF::ScalpingTask.count).to eq(1)
      expect(BF::MyTradeShip.first.scalping_task).to be_a(BF::ScalpingTask)
    end
  end
end
