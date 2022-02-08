RSpec.describe Peatio::Nem2::Wallet do
  let(:wallet) { Peatio::Nem2::Wallet.new }

  def request_headers(wallet)
    { 'Accept': 'application/json' }
  end

  let(:uri) { 'http://127.0.0.1:7890/' }

  let(:settings) do
    {
      wallet: {
        address: '2N4qYjye5yENLEkz4UkLFxzPaxJatF3kRwf',
        uri: uri,
        secret: 'changeme',
        access_token: 'v2x0b53e612518e5ea625eb3c24175438b37f56bc1f82e9c9ba3b038c91b0c72e67',
        wallet_id: '5a7d9f52ba1923b107b80baabe0c3574',
        testnet: true
      },
      currency: {
        id: 'btc',
        base_factor: 100_000_000,
        code: 'btc',
        options: {}
      }
    }
  end

  context :configure do
    let(:settings) { { wallet: {}, currency: {} } }

    it 'requires wallet' do
      expect { wallet.configure(settings.except(:wallet)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { wallet.configure(settings) }.to_not raise_error
    end

    it 'requires currency' do
      expect { wallet.configure(settings.except(:currency)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { wallet.configure(settings) }.to_not raise_error
    end

    it 'sets settings attribute' do
      wallet.configure(settings)
      expect(wallet.settings).to eq(settings.slice(*Peatio::Nem2::Wallet::SUPPORTED_SETTINGS))
    end
  end

  
end
