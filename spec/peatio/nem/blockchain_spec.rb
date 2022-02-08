require "peatio/nem2/blockchain"
RSpec.describe Peatio::Nem2::Blockchain do
  context :features do
    it 'defaults' do
      blockchain1 = Peatio::Nem2::Blockchain.new
      expect(blockchain1.features).to eq Peatio::Nem2::Blockchain::DEFAULT_FEATURES
    end

    it 'override defaults' do
      blockchain2 = Peatio::Nem2::Blockchain.new(cash_addr_format: true)
      expect(blockchain2.features[:cash_addr_format]).to be_truthy
    end

    it 'custom feautures' do
      blockchain3 = Peatio::Nem2::Blockchain.new(custom_feature: :custom)
      expect(blockchain3.features.keys).to contain_exactly(*Peatio::Nem2::Blockchain::SUPPORTED_FEATURES)
    end
  end



  
end
