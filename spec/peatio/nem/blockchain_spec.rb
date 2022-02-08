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

  context :configure do
    let(:blockchain) { Peatio::Nem2::Blockchain.new }
    it 'default settings' do
      expect(blockchain.settings).to eq({})
    end

    it 'currencies and server configuration' do
      currencies = [{ id: :ltc,
                      base_factor: 100_000_000,
                      options: {} }]
      settings = { server: 'http://user:password@127.0.0.1:7890',
                   currencies: currencies,
                   something: :custom }
      blockchain.configure(settings)
      expect(blockchain.settings).to eq(settings.slice(*Peatio::Blockchain::Abstract::SUPPORTED_SETTINGS))
    end
  end

  context :latest_block_number do
    before(:all) { WebMock.disable_net_connect! }
    after(:all)  { WebMock.allow_net_connect! }

    let(:server) { 'http://user:password@127.0.0.1:7890' }
    let(:server_without_authority) { 'http://127.0.0.1:7890' }

    let(:response) do
      response_file
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:response_file) do
      File.join('spec', 'resources', 'getblockcount', '40500.json')
    end

    let(:blockchain) do
      Peatio::Nem2::Blockchain.new.tap {|b| b.configure(server: server)}
    end

    before do
      stub_request(:post, server_without_authority)
        .with(body: { jsonrpc: '1.0',
                      method: :getblockcount,
                      params:  [] }.to_json)
        .to_return(body: response.to_json)
    end

    it 'returns latest block number' do
      expect(blockchain.latest_block_number).to eq(40500)
    end

    it 'raises error if there is error in response body' do
      stub_request(:post, 'http://127.0.0.1:7890')
        .with(body: { jsonrpc: '1.0',
                      method: :getblockcount,
                      params:  [] }.to_json)
        .to_return(body: { result: nil,
                           error:  { code: -32601, message: 'Method not found' },
                           id:     nil }.to_json)

      expect{ blockchain.latest_block_number }.to raise_error(Peatio::Blockchain::ClientError)
    end
  end

  
end
