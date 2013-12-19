# -*- coding: utf-8 -*-
require 'spec_helper'
require 'nkf'

describe EditorController do
  describe 'エディタ画面を表示する (GET index)' do
    it 'returns http success' do
      get :index
      response.should be_success
    end
  end

  describe 'プログラムが正しいかチェックする (XHR POST check)' do
    before do
      params = {
        source_code: {
          data: data,
        }
      }.with_indifferent_access

      xhr :post, :check, params
    end

    context 'プログラムが正しい場合' do
      let(:data) { 'puts "Hello, World!"' }

      it { expect(response).to be_success }

      it do
        expected = parse_json(SourceCode.new(data: data).check_syntax.to_json)
        expect(parse_json(response.body)).to eq(expected)
      end
    end

    context 'プログラムが正しくない場合' do
      let(:data) { 'puts Hello, World!"' }

      it { expect(response).to be_success }

      it do
        expected = parse_json(SourceCode.new(data: data).check_syntax.to_json)
        expect(parse_json(response.body)).to eq(expected)
      end
    end
  end

  describe 'プログラムを保存する (XHR POST save_file)' do
    let(:params) {
      {
        source_code: {
          filename: '01.rb',
          data: 'puts "Hello, World!"',
        }
      }
    }

    describe 'レスポンス' do
      subject {
        xhr :post, :save_file, params
        response
      }

      it { should be_success }
    end

    it 'アップロードされたプログラムを保存できる' do
      expect {
        xhr :post, :save_file, params
      }.to change { SourceCode.count }.by(1)
    end

    describe 'アップロードされたプログラム' do
      subject {
        ids = SourceCode.all.map(&:id)
        xhr :post, :save_file, params
        SourceCode.find((SourceCode.all.map(&:id) - ids).first)
      }

      its(:data) { should eq(params[:source_code][:data]) }
      its(:filename) { should eq(params[:source_code][:filename]) }
    end

    describe 'session' do
      before {
        ids = SourceCode.all.map(&:id)
        xhr :post, :save_file, params
        @created_source_code =
          SourceCode.find((SourceCode.all.map(&:id) - ids).first)
      }

      subject { session }

      it '[:source_code][:id]はアップロードしたプログラムのIDである' do
        expect(subject[:source_code][:id]).to eq(@created_source_code.id)
      end

      it '[:source_code][:digest]はアップロードしたプログラムのSHA256のハッシュ値である' do
        expect(subject[:source_code][:digest])
          .to eq(@created_source_code.digest)
      end
    end
  end

  describe 'プログラムをダウンロードしてサーバ上から削除する (DELETE destroy_file)' do
    let(:source_code) {
      SourceCode.create!(filename: '01.rb', data: 'puts "Hello, World!"')
    }

    context 'セッションが正しい場合' do
      let(:_session) {
        {
          source_code: {
            id: source_code.id,
            digest: source_code.digest,
          }
        }
      }

      before do
        allow(@controller).to receive(:send_data).and_call_original
        delete :destroy_file, {}, _session
      end

      specify 'プログラムをダウンロードする' do
        expect(@controller).to have_received(:send_data)
          .with(source_code.data,
                filename: source_code.filename,
                disposition: 'attachment',
                type: 'text/plain; charset=utf-8')
          .once
      end

      specify 'プログラムをサーバ上から削除する' do
        expect(SourceCode).to have(0).records
      end

      specify 'セッションから[:source_code]を削除する' do
        expect(session[:source_code]).to be_nil
      end
    end

    context 'セッションが不正な場合' do
      shared_examples 'raise exception' do
        it {
          expect {
            delete :destroy_file, {}, _session
          }.to raise_exception
        }
      end

      context 'セッションに[:source_code]がない場合' do
        let(:_session) { {} }

        include_examples 'raise exception'
      end

      context 'セッションに[:source_code][:id]がない場合' do
        let(:_session) {
          {
            source_code: {
              digest: source_code.digest,
            }
          }
        }

        include_examples 'raise exception'
      end

      context 'セッションに[:source_code][:digest]がない場合' do
        let(:_session) {
          {
            source_code: {
              id: source_code.id,
            }
          }
        }

        include_examples 'raise exception'
      end

      context 'セッションの[:source_code][:digest]が不正な場合' do
        let(:_session) {
          {
            source_code: {
              id: source_code.id,
              digest: 'invalid_digest',
            }
          }
        }

        include_examples 'raise exception'
      end
    end
  end

  describe 'プログラムを読み込む (POST load_file)' do
    before do
      post :load_file, load_file: load_file
    end

    describe '正常系' do
      let(:load_file) { fixture_file_upload('files/01.rb', 'text/plain') }

      it { expect(response).to be_success }

      it 'アップロードされたプログラムの情報をJSON形式でダウンロードできる' do
        load_file.rewind
        file = {
          name: load_file.original_filename,
          type: load_file.content_type,
          size: load_file.size,
          source: load_file.read.force_encoding('utf-8'),
        }
        expect(response.body).to be_json_eql(file.to_json)
      end
    end

    describe '異常系' do
      context '画像をアップロードした場合' do
        let(:load_file) {
          fixture_file_upload('files/favicon.ico', 'application/octet-stream')
        }

        it { expect(response).to be_success }

        it 'エラーを返す' do
          file = {
            name: load_file.original_filename,
            error: 'Rubyのプログラムではありません',
          }
          file.each do |path, value|
            expect(response.body)
              .to include_json(value.to_json).at_path(path.to_s)
          end
        end
      end
    end
  end
end
