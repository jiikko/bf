RSpec.describe BF::Scalping::Makiami do
  describe '.scalp' do
    context 'vaild? is true' do
      it 'ScalpingTaskを作成すること' do
        scalping = BF::Scalping::Makiami.new
        allow(scalping).to receive(:valid?).and_return(true)
        allow_any_instance_of(BF::Client).to receive(:buy).and_return(1)
        trade = BF::Trade.create!(price: 3)
        scalping.scalp
        expect(BF::MyTradeShip.count).to eq(4)
        expect(BF::ScalpingTask.count).to eq(4)
        expect(BF::MyTradeShip.first.scalping_task).to be_a(BF::ScalpingTask)
        expect(BF::MyTradeShip.all.map(&:buy_trade).map(&:price)).to eq([3, -497, -997, -1497])
        expect(BF::MyTradeShip.all.map(&:buy_trade).map(&:params).uniq).to eq([{:timeout=>2.minutes}])
      end
    end
  end
end

