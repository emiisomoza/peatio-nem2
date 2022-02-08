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

  context :build_transaction do

    let(:raw_transaction) do
      {"txid"=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
       "hash"=>"aa5d1157ad7d609eda564125cde235bd4f20c47723f024c9a45fd9054118ecc3",
       "version"=>2,
       "size"=>280,
       "vsize"=>198,
       "locktime"=>1354649,
       "vin"=>
         [{"txid"=>"fc5574fac1b2592853ce89be09fe883cb6b46e6e080213ec22408e2b8632b428",
           "vout"=>0,
           "scriptSig"=>
             {"asm"=>"0014ab96ef2628ff873662ebd77f522aecf16c224495",
              "hex"=>"160014ab96ef2628ff873662ebd77f522aecf16c224495"},
           "txinwitness"=>
             ["3045022100af57fa2d9e948fa2c7541dba8a02886aeaf4800a9726d0451dc0eeb1dc79488e022059bbfec78f3c0c07918008afde040ee5816cb7c84e3f09e3c5d30832acaca74001",
              "026f7eeba4cbf41edbfab5cba1d476d1942aada8dc3bbedbd4db87b0ecfdfc8cfb"],
           "sequence"=>4294967294}],
       "vout"=>
         [{"value"=>0.1,
           "n"=>0,
           "scriptPubKey"=>
             {"asm"=>"OP_HASH160 869bf1331ba9fe042ba7c06455d8c2bcb0b2a208 OP_EQUAL",
              "hex"=>"a914869bf1331ba9fe042ba7c06455d8c2bcb0b2a20887",
              "reqSigs"=>1,
              "type"=>"scripthash",
              "addresses"=>["2N5WyM3QT1Kb6fvkSZj3Xvcx2at7Ydm5VmL"]}},
          {"value"=>0.2,
           "n"=>1,
           "scriptPubKey"=>
             {"asm"=>"OP_HASH160 4c69a52518526c13b234f1e88e163feed08739c8 OP_EQUAL",
              "hex"=>"a9144c69a52518526c13b234f1e88e163feed08739c887",
              "reqSigs"=>1,
              "type"=>"scripthash",
              "addresses"=>["2MzDFuDK9ZEEiRsuCDFkPdeHQLGvwbC9ufG"]}},
          {"value"=>0.11749604,
           "n"=>2,
           "scriptPubKey"=>
             {"asm"=>"OP_HASH160 1d4f141e0ee4f0121bef6e2d14c852b679ceceaa OP_EQUAL",
              "hex"=>"a9141d4f141e0ee4f0121bef6e2d14c852b679ceceaa87",
              "reqSigs"=>1,
              "type"=>"scripthash",
              "addresses"=>["2MuvCKKi1MzGtvZqvcbqn5twjA2v5XLaTWe"]}}],
       "hex"=>
         "0200000000010128b432862b8e4022ec1302086e6eb4b63c88fe09be89ce532859b2c1fa7455fc0000000017160014ab96ef2628ff873662ebd77f522aecf16c224495feffffff03809698000000000017a914869bf1331ba9fe042ba7c06455d8c2bcb0b2a20887002d31010000000017a9144c69a52518526c13b234f1e88e163feed08739c887e448b3000000000017a9141d4f141e0ee4f0121bef6e2d14c852b679ceceaa8702483045022100af57fa2d9e948fa2c7541dba8a02886aeaf4800a9726d0451dc0eeb1dc79488e022059bbfec78f3c0c07918008afde040ee5816cb7c84e3f09e3c5d30832acaca7400121026f7eeba4cbf41edbfab5cba1d476d1942aada8dc3bbedbd4db87b0ecfdfc8cfb99ab1400"}
    end

    context 'three vout tx' do
      let(:expected_transactions) do
        [{:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>0,
          :to_address=>"2N5WyM3QT1Kb6fvkSZj3Xvcx2at7Ydm5VmL",
          :amount=>0.1e0,
          :status=>"success",
          :currency_id=>currency[:id]},
         {:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>1,
          :to_address=>"2MzDFuDK9ZEEiRsuCDFkPdeHQLGvwbC9ufG",
          :amount=>0.2e0,
          :status=>"success",
          :currency_id=>currency[:id]},
         {:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>2,
          :to_address=>"2MuvCKKi1MzGtvZqvcbqn5twjA2v5XLaTWe",
          :amount=>0.11749604e0,
          :status=>"success",
          :currency_id=>currency[:id]}]
      end

      let(:currency) do
        { id: :ltc,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:blockchain) do
        Peatio::Nem2::Blockchain.new.tap { |b| b.configure(currencies: [currency]) }
      end

      it 'builds formatted transactions for passed transaction' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end

    context 'multiple currencies' do
      let(:currency1) do
        { id: :ltc1,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:currency2) do
        { id: :ltc2,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:expected_transactions) do
        [{:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>0,
          :to_address=>"2N5WyM3QT1Kb6fvkSZj3Xvcx2at7Ydm5VmL",
          :amount=>0.1e0,
          :status=>"success",
          :currency_id=>currency1[:id]},
         {:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>0,
          :to_address=>"2N5WyM3QT1Kb6fvkSZj3Xvcx2at7Ydm5VmL",
          :amount=>0.1e0,
          :status=>"success",
          :currency_id=>currency2[:id]},
         {:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>1,
          :to_address=>"2MzDFuDK9ZEEiRsuCDFkPdeHQLGvwbC9ufG",
          :amount=>0.2e0,
          :status=>"success",
          :currency_id=>currency1[:id]},
         {:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>1,
          :to_address=>"2MzDFuDK9ZEEiRsuCDFkPdeHQLGvwbC9ufG",
          :amount=>0.2e0,
          :status=>"success",
          :currency_id=>currency2[:id]},
         {:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>2,
          :to_address=>"2MuvCKKi1MzGtvZqvcbqn5twjA2v5XLaTWe",
          :amount=>0.11749604e0,
          :status=>"success",
          :currency_id=>currency1[:id]},
         {:hash=>"1da5cd163a9aaf830093115ac3ac44355e0bcd15afb59af78f84ad4084973ad0",
          :txout=>2,
          :to_address=>"2MuvCKKi1MzGtvZqvcbqn5twjA2v5XLaTWe",
          :amount=>0.11749604e0,
          :status=>"success",
          :currency_id=>currency2[:id]}]
      end

      let(:blockchain) do
        Peatio::Nem2::Blockchain.new.tap do |b|
          b.configure(currencies: [currency1, currency2])
        end
      end

      it 'builds formatted transactions for passed transaction per each currency' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end

    context 'single vout transaction' do
      let(:currency) do
        { id: :ltc,
          base_factor: 100_000_000,
          options: {} }
      end

      let(:blockchain) do
        Peatio::Nem2::Blockchain.new.tap { |b| b.configure(currencies: [currency]) }
      end

      let(:raw_transaction) do
        {"txid"=>"6d9570b516efa9d46dd0ce18abbb4fc95a4359a047abbb6dc76fab247b45b4f3",
         "hash"=>"6d9570b516efa9d46dd0ce18abbb4fc95a4359a047abbb6dc76fab247b45b4f3",
         "version"=>1,
         "size"=>104,
         "vsize"=>104,
         "locktime"=>0,
         "vin"=>
           [{"coinbase"=>"03349e000658fa4676092a0100000095090000",
             "sequence"=>4294967295}],
         "vout"=>
           [{"value"=>50,
             "n"=>0,
             "scriptPubKey"=>
               {"asm"=>
                  "OP_DUP OP_HASH160 7eb3fdb623776fb500cdb70816cf2a5256eb358e OP_EQUALVERIFY OP_CHECKSIG",
                "hex"=>"76a9147eb3fdb623776fb500cdb70816cf2a5256eb358e88ac",
                "reqSigs"=>1,
                "type"=>"pubkeyhash",
                "addresses"=>["ms4u4DsgfqdP85ceodZkHm1TFn43tEHaiX"]}}],
         "hex"=>
           "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff1303349e000658fa4676092a0100000095090000ffffffff0100f2052a010000001976a9147eb3fdb623776fb500cdb70816cf2a5256eb358e88ac00000000"}
      end

      let(:expected_transactions) do
        [{:hash=>"6d9570b516efa9d46dd0ce18abbb4fc95a4359a047abbb6dc76fab247b45b4f3",
          :txout=>0,
          :to_address=>"ms4u4DsgfqdP85ceodZkHm1TFn43tEHaiX",
          :amount=>0.5e2,
          :status=>"success",
          :currency_id=>currency[:id]}]
      end

      it 'builds formatted transactions for each vout' do
        expect(blockchain.send(:build_transaction, raw_transaction)).to contain_exactly(*expected_transactions)
      end
    end
  end
end
