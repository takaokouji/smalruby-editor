# -*- coding: utf-8 -*-

::NAME_INFO = {
  'トップページ' => {
    path: '/',
  },
  'デモページ' => {
    path: '/demo/',
  },
  'ブロック' => {
    path: '/',
  },
  'エディタ' => {
    path: '/',
  },

  'ブロックタブ' => {
    id: 'block-tab',
  },
  'Rubyタブ' => {
    id: 'ruby-tab',
  },
  'テキストエディタ' => {
    id: 'text-editor',
  },
  'プログラム名の入力欄' => {
    id: 'filename',
  },

  'ダウンロードボタン' => {
    id: 'download-button',
  },
  '実行ボタン' => {
    id: 'run-button',
  },
  'ロードボタン' => {
    id: 'load-button',
  },
  'セーブボタン' => {
    id: 'save-button',
  },
  'チェックボタン' => {
    id: 'check-button',
  },
  'リセットボタン' => {
    id: 'reset-button',
  },

  'メッセージ' => {
    id: 'messages',
  },
}

::NAME_INFO.values.each do |value|
  if value.key?(:id) && !value.key?(:selector)
    value[:selector] = "##{value[:id]}"
  end
end
