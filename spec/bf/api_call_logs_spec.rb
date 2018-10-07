require 'spec_helper'

RSpec.describe BF::ApiCallLog do
  describe 'scopes' do
    describe 'old' do
      it '古いレコードを取得できること' do
        BF::ApiCallLog.create!(api_type: :private_api, created_at: Time.now)
        BF::ApiCallLog.create!(api_type: :public_api, created_at: 200.seconds.ago)
        expect(BF::ApiCallLog.old.last.api_type).to eq('public_api')
        expect(BF::ApiCallLog.old.count).to eq(1)
      end
    end

    describe 'recent' do
      it '新しいレコードを取得できること' do
        BF::ApiCallLog.create!(api_type: :private_api, created_at: Time.now)
        BF::ApiCallLog.create!(api_type: :public_api, created_at: 200.seconds.ago)
        expect(BF::ApiCallLog.recent.last.api_type).to eq('private_api')
        expect(BF::ApiCallLog.recent.count).to eq(1)
      end
    end
  end
end
